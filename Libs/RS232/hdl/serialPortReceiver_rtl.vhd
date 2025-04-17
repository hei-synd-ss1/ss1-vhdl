--====================================================================--
-- Design units : RS232.serialPortReceiver.RTL
--
-- File name : serialPortReceiver_RTL.vhd
--
-- Purpose : Decode incoming serial data, handling error detection and multi-sampling for better accuracy.
--
-- Inputs :
--   i_clk : Clock
--   i_rst : Reset
--   i_rxd : Incoming serial data
--   i_rxd_en : Enable incoming data reception
--
-- Outputs :
--   o_byte : Recomposed data
--   o_byte_received : Indicates that a byte has been received
--   o_parity_error : Indicates that a parity error has occurred
--   o_frame_error : Indicates that a frame error has occurred
--   o_illegalstate_error : Indicates that an illegal state has occurred in the FSM
--   o_is_receiving : Indicates that the receiver is currently receiving data
--
-- Parameters :
--   g_BAUD_RATE_DIVIDER : Baud rate divider (must be at least 4)
--   g_DATA_BIT_NB : Number of data bits (between 5 and 9)
--   g_LSB_FIRST : Bit order ('0' = MSB first, '1' = LSB first)
--   g_USE_PARITY : Use parity ('0' = no parity, '1' = use parity)
--   g_PARITY_IS_EVEN : Parity type ('0' = odd parity, '1' = even parity)
--   g_STOP_BITS : Number of stop bits (1.0, 1.5, or 2.0)
--   g_IDLE_STATE : Idle state ('0' = idle low, '1' = idle high)
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
-- Version Author   Date           Changes
-- 2.0     AMA/BOY  16.04.2025     Added parity, stop bits, multi-sampling, bit order, idle state. Added frame / parity / illegal state error signals. Added Rx enable (RS485 / RS422).
-- 1.0              04.04.2022     First version
-- 
------------------------------------------------

library Common;
  use Common.CommonLib.all;

ARCHITECTURE RTL OF serialPortReceiver IS

  -- FSM
  type state_t is (ST_IDLE, ST_START_BIT, ST_SAMPLE_1, ST_SAMPLE_2, ST_SAMPLE_3, ST_NEXT_BIT, ST_INDICATE_REC_COMPLETE, ST_WAIT_STOP, ST_WAIT_STOP_MORE);
  signal lvec_state: state_t;
  -- Clock divider
  signal lvec_divider_counter: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDER)-1 downto 0);
  signal lvec_divider_sampling_counter: unsigned(requiredBitNb(positive(g_BAUD_RATE_DIVIDER / 3))-1 downto 0);
  constant c_DIVIDER_SAMPLING_TARGET: unsigned(lvec_divider_sampling_counter'range) := to_unsigned( positive(g_BAUD_RATE_DIVIDER / 4) - 1, lvec_divider_sampling_counter'length );
  -- Since exact stop bit divider may lead to erroneous data without flow control, wait a bit less than expected values
  constant c_DIVIDER_NEAR_HALF_TARGET: unsigned(lvec_divider_counter'range) := to_unsigned( positive(g_BAUD_RATE_DIVIDER / 3) * 2, lvec_divider_counter'length );
  constant c_DIVIDER_NEAR_BAUDRATE_TARGET: unsigned(lvec_divider_counter'range) := to_unsigned( positive(g_BAUD_RATE_DIVIDER * 1 / 4), lvec_divider_counter'length );
    -- When overflows
  signal lsig_divider_of, lsig_divider_sampling_of: std_ulogic;

  -- Data to receive
  function fctDataCntTarget(use_parity : std_ulogic) return integer
  is begin
      if use_parity = '0' then
          return g_DATA_BIT_NB;
      else
          return g_DATA_BIT_NB + 1;
      end if;
  end function;
  
  constant c_DATA_CNT_TARGET: unsigned(requiredBitNb(g_DATA_BIT_NB + 1)-1 downto 0) := to_unsigned( fctDataCntTarget(g_USE_PARITY), requiredBitNb(g_DATA_BIT_NB + 1) ); -- +1 for parity
  
  signal lvec_rx_counter: unsigned(requiredBitNb(g_DATA_BIT_NB + 1)-1 downto 0); -- +1 for parity
  signal lvec_rx_shift_reg: std_ulogic_vector(g_DATA_BIT_NB-1 + 1 downto 0); -- +1 for parity
  signal lvec_sampling_values: std_ulogic_vector(1 downto 0);
  signal lsig_sampled_value: std_ulogic;

  -- Sys
  signal lsig_o_byte_received: std_ulogic;
  signal lsig_o_parity_error: std_ulogic;
  signal lsig_o_frame_error : std_ulogic;
  signal lvec_o_byte : std_ulogic_vector(g_DATA_BIT_NB-1 downto 0);

  -- Other
  signal lsig_illegalstate: std_ulogic;

BEGIN

  -- Check generics
  assert g_BAUD_RATE_DIVIDER >= 4 report "g_BAUD_RATE_DIVIDER must be at least 4" severity failure;
  assert g_DATA_BIT_NB >= 5 and g_DATA_BIT_NB <= 9 report "g_DATA_BIT_NB must be between 5 and 9" severity failure;
  assert g_STOP_BITS = 1.0 or g_STOP_BITS = 1.5 or g_STOP_BITS = 2.0 report "g_STOP_BITS must be 1, 1.5 or 2" severity failure;

  -- Clock divider
  proc_clk_divider : process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_divider_counter <= (others => '0');
      lsig_divider_of <= '0';
      lvec_divider_sampling_counter <= (others => '0');
      lsig_divider_sampling_of <= '0';
    elsif rising_edge(i_clk) then
      lsig_divider_of <= '0';
      lsig_divider_sampling_of <= '0';
      -- Check for divider done
      if i_rxd_en = '0' or (lvec_state = ST_IDLE and i_rxd = g_IDLE_STATE) or lvec_divider_counter = 0 then
        lvec_divider_counter <= to_unsigned( g_BAUD_RATE_DIVIDER - 1, lvec_divider_counter'length );
        lsig_divider_of <= '1' when (i_rxd_en = '1' and lvec_state /= ST_IDLE) else '0';
        lvec_divider_sampling_counter <= c_DIVIDER_SAMPLING_TARGET;
      else
        lvec_divider_counter <= lvec_divider_counter - 1;
        if lvec_divider_sampling_counter = 0 then
          lvec_divider_sampling_counter <= c_DIVIDER_SAMPLING_TARGET;
          lsig_divider_sampling_of <= '1';
        else
          lvec_divider_sampling_counter <= lvec_divider_sampling_counter - 1;
        end if;
      end if;
    end if;
  end process proc_clk_divider;

  -- Receive FSM
  proc_fsm : process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_state <= ST_IDLE;
      lvec_rx_shift_reg <= (others => '0');
      lvec_rx_counter <= (others => '0');
      lsig_o_byte_received <= '0';
      lsig_o_parity_error <= '0';
      lsig_o_frame_error <= '0';
      lvec_o_byte <= (others => '0');
      lsig_illegalstate <= '0';
      lvec_sampling_values <= (others => '0');
      lsig_sampled_value <= '0';
    elsif rising_edge(i_clk) then
      lsig_o_byte_received <= '0';
      lsig_o_frame_error <= '0';
      lsig_o_parity_error <= '0';

      case lvec_state is

        when ST_IDLE =>
          lvec_rx_counter <= (others => '0');

          -- Start detected
          if i_rxd_en = '1' and i_rxd = not g_IDLE_STATE then
            lvec_state <= ST_START_BIT;
          end if;

        when ST_START_BIT =>
          -- Start bit detected
          if lsig_divider_of = '1' then
            lvec_state <= ST_SAMPLE_1;
          end if;

        when ST_SAMPLE_1 =>
          if lsig_divider_sampling_of = '1' then
            lvec_sampling_values(0) <= i_rxd;
            lvec_state <= ST_SAMPLE_2;
          end if;

        when ST_SAMPLE_2 =>
          if lsig_divider_sampling_of = '1' then
            lvec_sampling_values(1) <= i_rxd;
            lvec_state <= ST_SAMPLE_3;
          end if;

        when ST_SAMPLE_3 =>
          if lsig_divider_sampling_of = '1' then
            lsig_sampled_value <= (lvec_sampling_values(1) and i_rxd) or (lvec_sampling_values(0) and i_rxd) or (lvec_sampling_values(1) and lvec_sampling_values(0));
            lvec_state <= ST_NEXT_BIT;
          end if;

        when ST_NEXT_BIT =>

          -- Bit ready
          if lsig_divider_of = '1' then
            lvec_rx_shift_reg <= lsig_sampled_value & lvec_rx_shift_reg(lvec_rx_shift_reg'high downto 1);
            if lvec_rx_counter < c_DATA_CNT_TARGET - 1 then
              lvec_rx_counter <= lvec_rx_counter + 1;
              lvec_state <= ST_SAMPLE_1;
            else -- is last data bit / parity bit
              lvec_state <= ST_INDICATE_REC_COMPLETE;
              if g_USE_PARITY = '0' then
                lvec_rx_shift_reg <= '0' & lvec_rx_shift_reg(lvec_rx_shift_reg'high downto 1); -- no parity
              end if;
            end if;
          end if;

        when ST_INDICATE_REC_COMPLETE =>
          -- Need this state because lvec_rx_shift_reg not assigned yet. May be avoided by using variables.
          lvec_state <= ST_WAIT_STOP;

          -- Indicate reception
          lsig_o_byte_received <= '1';
          lsig_o_frame_error <= g_IDLE_STATE xor i_rxd; -- only checks if data MAY still be transmitting

          -- Data
          if g_LSB_FIRST = '1' then
            lvec_o_byte <= lvec_rx_shift_reg(lvec_rx_shift_reg'high - 1 downto 0);
          else
            for i in 0 to g_DATA_BIT_NB-1 loop
              lvec_o_byte(i) <= lvec_rx_shift_reg(g_DATA_BIT_NB - i - 1);
            end loop;
          end if;

          -- Check parity
          if g_USE_PARITY = '1' then
            if g_PARITY_IS_EVEN = '1' then
              if lvec_rx_shift_reg(lvec_rx_shift_reg'high) /= xor lvec_rx_shift_reg(lvec_rx_shift_reg'high - 1 downto 0) then
                lsig_o_parity_error <= '1';
              end if;
            else
              if lvec_rx_shift_reg(lvec_rx_shift_reg'high) /= xnor lvec_rx_shift_reg(lvec_rx_shift_reg'high - 1 downto 0) then
                lsig_o_parity_error <= '1';
              end if;
            end if;
          end if;

        -- Stop are happening a bit before the end of the bit period to avoid stopbits errors on high baudrates without flow control
        when ST_WAIT_STOP =>
          if g_STOP_BITS = 1.0 then
            if lvec_divider_counter < c_DIVIDER_NEAR_BAUDRATE_TARGET then
              lvec_state <= ST_IDLE;
            end if;
          elsif lsig_divider_of = '1' then
            lvec_state <= ST_WAIT_STOP_MORE;
          end if;

        when ST_WAIT_STOP_MORE =>
          -- Stop detected
          if g_STOP_BITS = 1.5 then
            if lvec_divider_counter < c_DIVIDER_NEAR_HALF_TARGET then
              lvec_state <= ST_IDLE;
            end if;
          else
            if lvec_divider_counter < c_DIVIDER_NEAR_BAUDRATE_TARGET then
              lvec_state <= ST_IDLE;
            end if;
          end if;

        when others =>
          lsig_illegalstate <= '1';
          lvec_state <= ST_IDLE;
        
      end case;
    end if;
  end process proc_fsm;

  -- Outputs
  o_byte <= lvec_o_byte;
  o_byte_received <= lsig_o_byte_received;
  o_parity_error <= lsig_o_parity_error;
  o_frame_error <= lsig_o_frame_error;
  o_is_receiving <= '0' when lvec_state = ST_IDLE else '1';
  o_illegalstate_error <= lsig_illegalstate;


END ARCHITECTURE RTL;
