--====================================================================--
-- Design units : RS232.serialPortTransmitter.RTL
--
-- File name : serialPortTransmitter_RTL.vhd
--
-- Purpose : Encode given data into serial data.
--
-- Inputs :
--   i_clk : Clock signal
--   i_rst : Reset signal (active high)
--   i_data : Data to be sent (LSB first)
--   i_send : Send signal (active high)
--
-- Outputs :
--   o_txd : Serial data output
--   o_txd_en : Transmitter enable (active high)
--   o_is_sending : Sending status (active high)
--   o_illegalstate_error : Illegal state error (active high)
--
-- Parameters :
--   g_BAUD_RATE_DIVIDER : Baud rate divider (clock frequency / baud rate)
--   g_DATA_BIT_NB : Number of data bits (5 to 9)
--   g_LSB_FIRST : LSB first ('0' = MSB first, '1' = LSB first)
--   g_USE_PARITY : Use parity bit ('0' = no parity, '1' = parity)
--   g_PARITY_IS_EVEN : Parity type ('0' = odd, '1' = even)
--   g_STOP_BITS : Number of stop bits (1, 1.5 or 2)
--   g_IDLE_STATE : Idle state ('0' = low, '1' = high)
--
-- Library : RS232
--
-- Dependencies : Common
--
-- Author :
-- HES-SO Valais/Wallis
-- Route de l'Industrie 23
-- 1950 Sion
-- Switzerland
--
-- Design tool : HDL Designer 2019.2 (Build 5)
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author     Date           Changes
-- 2.0     AMA / BOY  16.04.2022     Added parity, stop bits, bit order, idle state. Added illegal state error signals. Added Tx enable (RS485 / RS422).
-- 1.0                04.04.2022     First version
-- 
-- 
------------------------------------------------

library Common;
use Common.CommonLib.all;

library IEEE;
  use IEEE.std_logic_misc.all;

ARCHITECTURE RTL OF serialPortTransmitter IS

  -- FSM
  type state_t is (ST_IDLE, ST_SEND_START, ST_SEND_BYTE, ST_SEND_PARITY, ST_SEND_STOP, ST_STOP_HOLD);
  signal lvec_state: state_t;
  signal lsig_is_idle: std_ulogic;
  
  -- What is to be sent
  signal lvec_tx_shift_reg: unsigned(i_data'range);
  signal lvec_data_cnt: unsigned(requiredBitNb(g_DATA_BIT_NB) - 1 downto 0);
  signal lsig_data_xor, lsig_o_txd: std_ulogic;

  -- Clock divider
  signal lvec_divider_counter: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDER) - 1 downto 0);
  constant c_HALF_BIT_TARGET: unsigned(lvec_divider_counter'range) := to_unsigned( g_BAUD_RATE_DIVIDER / 2, lvec_divider_counter'length );
    -- When overflows
  signal lsig_divider_of: std_ulogic;

  -- Other
  signal lsig_illegal_state: std_ulogic;

BEGIN

  -- Check generics
  assert g_BAUD_RATE_DIVIDER >= 2 report "g_BAUD_RATE_DIVIDER must be at least 2" severity failure;
  assert g_DATA_BIT_NB >= 5 and g_DATA_BIT_NB <= 9 report "g_DATA_BIT_NB must be between 5 and 9" severity failure;
  assert g_STOP_BITS = 1.0 or g_STOP_BITS = 1.5 or g_STOP_BITS = 2.0 report "g_STOP_BITS must be 1, 1.5 or 2" severity failure;

  -- Clock divider
  proc_clk_divider: process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_divider_counter <= (others => '0');
      lsig_divider_of <= '0';
    elsif rising_edge(i_clk) then
      lsig_divider_of <= '0';
      if lsig_is_idle = '1' or lvec_divider_counter = 0 then
        lvec_divider_counter <= to_unsigned( g_BAUD_RATE_DIVIDER - 1, lvec_divider_counter'length );
        lsig_divider_of <= not lsig_is_idle;
      else
        lvec_divider_counter <= lvec_divider_counter - 1;
      end if;
    end if;
  end process proc_clk_divider;

  -- FSM
  proc_fsm : process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_state <= ST_IDLE;
      lvec_tx_shift_reg <= (others => '0');
      lvec_data_cnt <= (others => '0');
      lsig_illegal_state <= '0';
      lsig_data_xor <= '0';
      lsig_o_txd <= g_IDLE_STATE;
    elsif rising_edge(i_clk) then
      case lvec_state is
        
        when ST_IDLE =>
          lvec_data_cnt <= (others => '0');
          lsig_o_txd <= g_IDLE_STATE;  -- idle state

          if i_send = '1' then
            lvec_state <= ST_SEND_START;
            lsig_o_txd <= not g_IDLE_STATE;
            -- Preload data
            if g_LSB_FIRST = '1' then
              lvec_tx_shift_reg <= unsigned(i_data);       -- data
            else
              for i in 0 to g_DATA_BIT_NB-1 loop
                lvec_tx_shift_reg(g_DATA_BIT_NB - i - 1) <= i_data(i);
              end loop;
            end if;
            -- parity bit
            if g_USE_PARITY = '1' then
              if g_PARITY_IS_EVEN = '1' then
                lsig_data_xor <= xor_reduce(i_data);
              else
                lsig_data_xor <= xnor_reduce(i_data);
              end if;
            end if;
          end if;

        when ST_SEND_START =>
          -- Bit clock overflows
          if lsig_divider_of = '1' then
            lvec_state <= ST_SEND_BYTE;
            lsig_o_txd <= lvec_tx_shift_reg(0); -- send first bit
            lvec_tx_shift_reg <= shift_right( lvec_tx_shift_reg, 1 ); -- shift data
            lvec_data_cnt <= lvec_data_cnt + 1;
          end if;
          
        when ST_SEND_BYTE =>
          -- Bit clock overflows
          if lsig_divider_of = '1' then
            lsig_o_txd <= lvec_tx_shift_reg(0); -- send bit
            lvec_tx_shift_reg <= shift_right( lvec_tx_shift_reg, 1 );
            lvec_data_cnt <= lvec_data_cnt + 1;
            if lvec_data_cnt = g_DATA_BIT_NB then
              if g_USE_PARITY = '1' then
                lvec_state <= ST_SEND_PARITY;
                lsig_o_txd <= lsig_data_xor; -- send parity bit
              else
                lvec_state <= ST_STOP_HOLD;
                lsig_o_txd <= g_IDLE_STATE; -- stop bit
              end if;
            end if;
          end if;

        when ST_SEND_PARITY =>
          if lsig_divider_of = '1' then
            lvec_state <= ST_SEND_STOP;
            lsig_o_txd <= g_IDLE_STATE; -- stop bit
          end if;
        
        when ST_SEND_STOP =>
          if lsig_divider_of = '1' then
            if g_STOP_BITS = 1.0 then
              lvec_state <= ST_IDLE;
            else
              lvec_state <= ST_STOP_HOLD;
            end if;
          end if;
        
        when ST_STOP_HOLD =>
          if g_STOP_BITS = 1.5 then
            if lvec_divider_counter < c_HALF_BIT_TARGET then
              lvec_state <= ST_IDLE;
            end if;
          elsif lsig_divider_of = '1' then
            lvec_state <= ST_IDLE;
          end if;
          
        when others =>
          lvec_state <= ST_IDLE;
          lsig_illegal_state <= '1';

      end case;
    end if;
  end process proc_fsm;

  lsig_is_idle <= '1' when lvec_state = ST_IDLE else '0';

  -- Output signals
  o_txd <= lsig_o_txd;
  o_is_sending <= not lsig_is_idle;
  o_txd_en <= not lsig_is_idle;
  o_illegalstate_error <= lsig_illegal_state;

END ARCHITECTURE RTL;
