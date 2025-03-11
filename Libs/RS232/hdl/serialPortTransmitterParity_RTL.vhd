--====================================================================--
-- Design units : RS232.serialPortTransmitterParity.RTL
--
-- File name : serialPortTransmitterParity.vhd
--
-- Purpose :
--
-- Note : This model can be synthesized by Xilinx Vivado.
--
-- Limitations : 
--
-- Errors : 
--
-- Library : RS232
--
-- Dependencies : None
--
-- Author : remy.borgeat
-- HES-SO Valais/Wallis
-- Route de l'Industrie 23
-- 1950 Sion
-- Switzerland
--
-- Design tool : HDL Designer 2019.2 (Build 5)
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author Date           Changes
-- 1.0            02.12.2024
-- 
-- 
------------------------------------------------

library Common;
use Common.CommonLib.all;

ARCHITECTURE rtl OF serialPortTransmitterParity IS

  -- FSM
  type state_t is (ST_IDLE, ST_SENDING_BYTE, ST_STOP_HOLD);
  signal lvec_state: state_t;
  signal lsig_is_idle: std_uLogic;
  -- What is to be sent
  constant c_PARITY_BIT_NB: integer := 1;
  constant c_DATA_SIZE: integer := g_DATA_BIT_NB + g_STOP_BIT_NB + c_PARITY_BIT_NB;
  signal lvec_tx_shift_reg: unsigned(c_DATA_SIZE downto 0);
  constant c_DATA_CNT_TARGET: unsigned(requiredBitNb(c_DATA_SIZE)-1 downto 0) := to_unsigned(c_DATA_SIZE, requiredBitNb(c_DATA_SIZE));
  signal lvec_data_cnt: unsigned(requiredBitNb(c_DATA_SIZE)-1 downto 0);
  -- Clock divider
  signal lvec_divider_counter: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDE)-1 downto 0);
    -- When overflows
  signal lsig_divider_of: std_uLogic;

BEGIN

  -- FSM
  fsm_proc : process(reset, clock)
  begin
    if reset = '1' then
      lvec_state <= ST_IDLE;
      lvec_tx_shift_reg <= (others => '1');
      lvec_data_cnt <= (others => '0');
    elsif rising_edge(clock) then
      case lvec_state is
        
        when ST_IDLE =>
          lvec_data_cnt <= (others => '0');
          if i_send = '1' then
            lvec_state <= ST_SENDING_BYTE;
            -- Preload data
            lvec_tx_shift_reg(0) <= '0';                                           -- start bit
            if g_LSB_FIRST = '1' then
              lvec_tx_shift_reg(g_DATA_BIT_NB downto 1) <= unsigned(i_data);       -- data
            else
              for i in 0 to g_DATA_BIT_NB-1 loop
                lvec_tx_shift_reg(g_DATA_BIT_NB - i) <= i_data(i);
              end loop;
            end if;
            lvec_tx_shift_reg(lvec_tx_shift_reg'high-1) <= xor unsigned(i_data);  -- parity bit
            lvec_tx_shift_reg(lvec_tx_shift_reg'high) <= '1';                     -- stop bit
          end if;

        when ST_SENDING_BYTE =>
          -- Bit clock overflows
          if lsig_divider_of = '1' then
            lvec_tx_shift_reg <= '1' & lvec_tx_shift_reg(lvec_tx_shift_reg'high downto 1);
            lvec_data_cnt <= lvec_data_cnt + 1;
            if lvec_data_cnt = c_DATA_CNT_TARGET then
              lvec_state <= ST_STOP_HOLD;
            end if;
          end if;
        
        when ST_STOP_HOLD =>
          if lsig_divider_of = '1' then
            lvec_state <= ST_IDLE;
          end if;
          
        when others =>
          lvec_state <= ST_IDLE;

      end case;
    end if;
  end process fsm_proc;

  lsig_is_idle <= '1' when lvec_state = ST_IDLE else '0';

  -- Clock divider
  clk_divider_proc: process(reset, clock)
  begin
    if reset = '1' then
      lvec_divider_counter <= (others => '0');
      lsig_divider_of <= '0';
    elsif rising_edge(clock) then
      lsig_divider_of <= '0';
      if lsig_is_idle = '1' or lvec_divider_counter = g_BAUD_RATE_DIVIDE - 1 then
        lvec_divider_counter <= (others => '0');
        lsig_divider_of <= not lsig_is_idle;
      else
        lvec_divider_counter <= lvec_divider_counter + 1;
      end if;
    end if;
  end process clk_divider_proc;

  -- Output signals
  o_txd <= lvec_tx_shift_reg(0) when lsig_is_idle = '0' else '1';
  o_busy <= not lsig_is_idle;
  o_txd_en <= not lsig_is_idle;

END ARCHITECTURE rtl;

