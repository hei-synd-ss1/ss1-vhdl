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

ARCHITECTURE RTL OF serialPortTransmitterParity IS

constant c_PARITY_BIT_NB: integer := 1;
signal lvec_divider_counter: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDE)-1 downto 0);
signal lsig_divider_counter_reset: std_uLogic;
signal lvec_tx_data: unsigned(g_DATA_BIT_NB-1 downto 0);
signal lsig_send1: std_uLogic;
signal lsig_tx_shift_enable: std_uLogic;
signal lvec_tx_shift_reg: unsigned(g_DATA_BIT_NB + g_STOP_BIT_NB + c_PARITY_BIT_NB downto 0);
signal lsig_tx_sending_byte: std_uLogic;
signal lsig_tx_sending_byte_and_stop: std_uLogic;

BEGIN

  divide: process(reset, clock)
  begin
    if reset = '1' then
      lvec_divider_counter <= (others => '0');
    elsif rising_edge(clock) then
      if lsig_divider_counter_reset = '1' then
        lvec_divider_counter <= to_unsigned(1, lvec_divider_counter'length);
      else
        lvec_divider_counter <= lvec_divider_counter + 1;
      end if;
    end if;
  end process divide;

  endOfCount: process(lvec_divider_counter, lsig_send1)
  begin
    if lvec_divider_counter = g_BAUD_RATE_DIVIDE then
      lsig_divider_counter_reset <= '1';
    elsif lsig_send1 = '1' then
      lsig_divider_counter_reset <= '1';
    else
      lsig_divider_counter_reset <= '0';
    end if;
  end process endOfCount;

  lsig_tx_shift_enable <= lsig_divider_counter_reset;

  storeData: process(reset, clock)
  begin
    if reset = '1' then
      lvec_tx_data <= (others => '1');
    elsif rising_edge(clock) then
      if i_send = '1' then
        lvec_tx_data <= unsigned(i_data);
      end if;
    end if;
  end process storeData;

  delaySend: process(reset, clock)
  begin
    if reset = '1' then
      lsig_send1 <= '0';
    elsif rising_edge(clock) then
      lsig_send1 <= i_send;
    end if;
  end process delaySend;

  shiftReg: process(reset, clock)
  begin
    if reset = '1' then
      lvec_tx_shift_reg <= (others => '1');
    elsif rising_edge(clock) then
      if lsig_tx_shift_enable = '1' then
        if lsig_send1 = '1' then
          lvec_tx_shift_reg <= (others => '1');                             -- stop bits
          lvec_tx_shift_reg(0) <= '0';                                      -- start bit
          lvec_tx_shift_reg(lvec_tx_data'high+1 downto 1) <= lvec_tx_data;  -- data
          lvec_tx_shift_reg(lvec_tx_shift_reg'high-1) <= xor lvec_tx_data;  -- parity bit
          lvec_tx_shift_reg(lvec_tx_shift_reg'high) <= '0';                 -- end flag
        else
          lvec_tx_shift_reg <= shift_right(lvec_tx_shift_reg, 1);
          lvec_tx_shift_reg(lvec_tx_shift_reg'high) <= '1';
        end if;
      end if;
    end if;
  end process shiftReg;

  lsig_tx_sending_byte <= '1' when
    (lvec_tx_shift_reg(lvec_tx_shift_reg'high downto 1) /= (lvec_tx_shift_reg'high downto 1 => '1'))
    else '0';

  lsig_tx_sending_byte_and_stop <= '1' when
    lvec_tx_shift_reg /= (lvec_tx_shift_reg'high downto 0 => '1')
    else '0';

  o_txd <= lvec_tx_shift_reg(0) when lsig_tx_sending_byte = '1' else '1';
  o_busy <= lsig_tx_sending_byte_and_stop or lsig_send1 or i_send;

END ARCHITECTURE RTL;

