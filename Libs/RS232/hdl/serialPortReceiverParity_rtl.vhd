--====================================================================--
-- Design units : RS232.serialPortReceiverParity.RTL
--
-- File name : serialPortReceiverParity.vhd
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
-- Design tool : HDL Designer 2023.4 Built on 6 Oct 2023 at 01:57:26
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author Date           Changes
-- 1.0            26.11.2024
-- 
-- 
------------------------------------------------
library Common;
  use Common.CommonLib.all;

ARCHITECTURE rtl OF serialPortReceiverParity IS

signal lvec_divider_counter: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDE-1)-1 downto 0);
signal lsig_divider_counter_reset: std_uLogic;
signal lsig_rx_delayed: std_uLogic;
signal lsig_divider_counter_synchronize: std_uLogic;
signal lsig_rx_sample: std_uLogic;
signal lsig_rx_shift_reg: std_ulogic_vector(g_DATA_BIT_NB-1 downto 0);
signal lsig_rx_receiving: std_uLogic;
signal lsig_rx_data_valid: std_uLogic;
signal lsig_rx_counter: unsigned(requiredBitNb(g_DATA_BIT_NB)-1 downto 0);

BEGIN

  divide: process(reset, clock)
  begin
    if reset = '1' then
      lvec_divider_counter <= (others => '0');
    elsif rising_edge(clock) then
      if lsig_divider_counter_synchronize = '1' then
        lvec_divider_counter <= to_unsigned(g_BAUD_RATE_DIVIDE/2, lvec_divider_counter'length);
      elsif lsig_divider_counter_reset = '1' then
        lvec_divider_counter <= (others => '0');
      else
        lvec_divider_counter <= lvec_divider_counter + 1;
      end if;
    end if;
  end process divide;

  endOfCount: process(lvec_divider_counter)
  begin
    if lvec_divider_counter = g_BAUD_RATE_DIVIDE-1 then
      lsig_divider_counter_reset <= '1';
    else
      lsig_divider_counter_reset <= '0';
    end if;
  end process endOfCount;

  delayRx: process(reset, clock)
  begin
    if reset = '1' then
      lsig_rx_delayed <= '0';
    elsif rising_edge(clock) then
      lsig_rx_delayed <= i_rxd;
    end if;
  end process delayRx;

  rxSynchronize: process(i_rxd, lsig_rx_delayed)
  begin
    if i_rxd /= lsig_rx_delayed then
      lsig_divider_counter_synchronize <= '1';
    else
      lsig_divider_counter_synchronize <= '0';
    end if;
  end process rxSynchronize;

  lsig_rx_sample <= lsig_divider_counter_reset and not lsig_divider_counter_synchronize;

  shiftReg: process(reset, clock)
  begin
    if reset = '1' then
      lsig_rx_shift_reg <= (others => '0');
    elsif rising_edge(clock) then
      if lsig_rx_sample = '1' then
        if lsig_rx_counter < g_DATA_BIT_NB then
          lsig_rx_shift_reg(lsig_rx_shift_reg'high-1 downto 0) <= lsig_rx_shift_reg(lsig_rx_shift_reg'high downto 1);
          lsig_rx_shift_reg(lsig_rx_shift_reg'high) <= i_rxd;
        end if;
      end if;
    end if;
  end process shiftReg;

  detectReceive: process(reset, clock)
  begin
    if reset = '1' then
      lsig_rx_receiving <= '0';
      lsig_rx_data_valid <= '0';
      o_byte_error <= '0';
    elsif rising_edge(clock) then
      if lsig_rx_sample = '1' then
        if lsig_rx_counter = g_DATA_BIT_NB then
          if i_rxd = xor lsig_rx_shift_reg then
            o_byte_error <= '0';
            lsig_rx_data_valid <= '1';
          else
            o_byte_error <= '1';
            lsig_rx_data_valid <= '0';
          end if;
        elsif i_rxd = '0' then
          lsig_rx_receiving <= '1';
        end if;
      elsif lsig_rx_data_valid = '1' then
        lsig_rx_receiving <= '0';
        lsig_rx_data_valid <= '0';
      elsif o_byte_error = '1' then
        lsig_rx_receiving <= '0';
        o_byte_error <= '0';
      end if;

    end if;
  end process detectReceive;

  countRxBitNb: process(reset, clock)
  begin
    if reset = '1' then
      lsig_rx_counter <= (others => '0');
    elsif rising_edge(clock) then
      if lsig_rx_sample = '1' then
        if lsig_rx_receiving = '1' then
          lsig_rx_counter <= lsig_rx_counter + 1;
        else
          lsig_rx_counter <= (others => '0');
        end if;
      end if;
    end if;
  end process countRxBitNb;

  o_byte <= lsig_rx_shift_reg(o_byte'range);
  o_byte_received <= lsig_rx_data_valid;

end rtl;