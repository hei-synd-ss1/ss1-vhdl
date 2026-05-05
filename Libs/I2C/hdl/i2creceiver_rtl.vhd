--====================================================================--
-- Design units : I2C.i2cReceiver.RTL
--
-- File name : i2cReceiver_RTL.vhd
--
-- Purpose : Handles receiving I2C data as a slave.
--           Detects start and stop conditions, read data and requests ACK bit if used by a master when reading from slave.
--
-- Library : I2C
--
-- Dependencies : Common.CommonLib.requiredBitNb
--
-- Author : Axam
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
-- 1.2     AMA    26.05.2025   Comments, interface names, add bus assertion status
-- 1.1     BOY    ?            Change interface and split ACK and data
-- 1.0     COF    ?
-- 
-- 
------------------------------------------------

library Common;
  use Common.CommonLib.all;

architecture RTL of i2cReceiver is

  signal lsig_clDelayed: std_logic;
  signal lsig_daDelayed: std_logic;
  signal lsig_clRising: std_uLogic;
  signal lsig_daRising: std_uLogic;
  signal lsig_daFalling: std_uLogic;
  signal lsig_startCondition: std_uLogic;
  signal lsig_stopCondition: std_uLogic;
  signal lvec_dataShiftReg: std_ulogic_vector(8 downto 0);
  signal lvec_bitCounter: unsigned(requiredBitNb(8+1) - 1 downto 0);
  constant c_BITCOUNTER_MAX : unsigned(requiredBitNb(8+1) - 1 downto 0) := to_unsigned(8 + 1, requiredBitNb(8 + 1));
  signal lsig_clRisingDelayed: std_uLogic;
  signal lsig_endOfWord: std_uLogic;
  signal lsig_endOfWordNoAck: std_uLogic;
  signal lsig_bus_asserted: std_ulogic;
  signal lsig_data_indicated: std_ulogic;

begin

  ------------------------------------------------------------------------------
  -- start, stop and other conditions
  delayInputs: process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lsig_clDelayed <= '1';
      lsig_daDelayed <= '1';
      lsig_clRisingDelayed <= '0';
    elsif rising_edge(i_clk) then
      lsig_clDelayed <= i_scl;
      lsig_daDelayed <= i_sda;
      lsig_clRisingDelayed <= lsig_clRising;
    end if;
  end process delayInputs;

  lsig_clRising <= '1' when (i_scl = '1') and (lsig_clDelayed = '0') else '0';
  lsig_daRising <= '1' when (i_sda = '1') and (lsig_daDelayed = '0') else '0';
  lsig_daFalling <= '1' when (i_sda = '0') and (lsig_daDelayed = '1') else '0';
  lsig_startCondition <= '1' when (lsig_daFalling = '1') and (i_scl = '1') else '0';
  lsig_stopCondition <= '1' when (lsig_daRising = '1') and (i_scl = '1') else '0';
  lsig_endOfWord <= '1' when (lsig_clRisingDelayed = '1') and (lvec_bitCounter = 0) else '0';
  lsig_endOfWordNoAck <= '1' when (lsig_clRisingDelayed = '1') and (lvec_bitCounter = 1) else '0';

  ------------------------------------------------------------------------------
  -- data shift register
  shiftReg: process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_dataShiftReg <= (others => '0');
    elsif rising_edge(i_clk) then
      if lsig_clRising = '1' then
        lvec_dataShiftReg <= lvec_dataShiftReg(lvec_dataShiftReg'high-1 downto 0) & i_sda;
      end if;
    end if;
  end process shiftReg;

  ------------------------------------------------------------------------------
  -- bit counter
  countBitNb: process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_bitCounter <= (others => '0');
      o_busy_receiving <= '0';
    elsif rising_edge(i_clk) then
      if lsig_startCondition = '1' then
        lvec_bitCounter <= c_BITCOUNTER_MAX;
      elsif lsig_stopCondition = '1' then
        lvec_bitCounter <= c_BITCOUNTER_MAX;
      elsif lsig_endOfWord = '1' then
        lvec_bitCounter <= c_BITCOUNTER_MAX;
        o_busy_receiving <= '0';
      elsif lsig_clRising = '1' then
        lvec_bitCounter <= lvec_bitCounter - 1;
        o_busy_receiving <= '1';
      end if;
    end if;
  end process countBitNb;

  ------------------------------------------------------------------------------
  -- output data and control
  -- start and stop: MSB is '1', LSB specifies start/stop
  -- data words: MSB is '0', next is ack, 8 LSBs are data word
  -- could be made combinatorial, but sequential is easier to debug
  sendWord: process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      o_data_received <= '0';
      o_data <= (others => '0');
      o_ack_bit <= '0';
      o_start_restart_received <= '0';
      o_stop_received <= '0';
      lsig_bus_asserted <= '0';
      lsig_data_indicated <= '0';
    elsif rising_edge(i_clk) then
      o_data_received <= '0';
      o_start_restart_received <= '0';
      o_stop_received <= '0';
      -- Check start condition
      if lsig_startCondition = '1' then
        o_start_restart_received <= '1';
        lsig_bus_asserted <= '1';
      end if;
      -- Check stop condition
      if lsig_stopCondition = '1' then
        o_stop_received <= '1';
        lsig_bus_asserted <= '0';
        lsig_data_indicated <= '0';
      end if;
      -- Check data
      if lsig_bus_asserted = '1' then
        -- Waits for full 9 bits (8 data bits + ack bit) when writing to slave
        if lsig_endOfWord = '1' and i_slave_write = '1' then
          if lsig_data_indicated = '1' then
            lsig_data_indicated <= '0';
          else
            o_ack_bit <= lvec_dataShiftReg(0);
            o_data_received <= '1';
            o_data <= lvec_dataShiftReg(lvec_dataShiftReg'high downto 1);
          end if;
        -- Waits only for 8 bits when reading from slave to let master ACK or NACK the 9th bit
        elsif lsig_endOfWordNoAck = '1' and i_slave_write = '0' then
          lsig_data_indicated <= '1';
          o_data_received <= '1';
          o_data <= lvec_dataShiftReg(lvec_dataShiftReg'high-1 downto 0);
        end if;
      end if;
    end if;
  end process sendWord;

  o_bus_asserted <= lsig_bus_asserted;

end RTL;