library Common;
  use Common.CommonLib.all;

architecture RTL of i2cReceiver is

  signal clDelayed: std_uLogic;
  signal daDelayed: std_uLogic;
  signal clRising: std_uLogic;
  signal daRising: std_uLogic;
  signal daFalling: std_uLogic;
  signal startCondition: std_uLogic;
  signal stopCondition: std_uLogic;
  signal dataShiftReg: std_ulogic_vector(dataBitNb-2 downto 0);
  signal bitCounter: unsigned(requiredBitNb(dataBitNb)-1 downto 0);
  signal clRisingDelayed: std_uLogic;
  signal endOfWord: std_uLogic;

begin
  ------------------------------------------------------------------------------
                                             -- start, stop and other conditions
  delayInputs: process(reset, clock)
  begin
    if reset = '1' then
      clDelayed <= '1';
      daDelayed <= '1';
      clRisingDelayed <= '0';
    elsif rising_edge(clock) then
      clDelayed <= sCl;
      daDelayed <= sDa;
      clRisingDelayed <= clRising;
    end if;
  end process delayInputs;

  clRising <= '1' when (sCl = '1') and (clDelayed = '0') else '0';
  daRising <= '1' when (sDa = '1') and (daDelayed = '0') else '0';
  daFalling <= '1' when (sDa = '0') and (daDelayed = '1') else '0';
  startCondition <= '1' when (daFalling = '1') and (sCl = '1') else '0';
  stopCondition <= '1' when (daRising = '1') and (sCl = '1') else '0';
  endOfWord <= '1' when (clRisingDelayed = '1') and (bitCounter = dataBitNb-1) else '0';

  ------------------------------------------------------------------------------
                                                          -- data shift register
  shiftReg: process(reset, clock)
  begin
    if reset = '1' then
      dataShiftReg <= (others => '0');
    elsif rising_edge(clock) then
      if clRising = '1' then
        dataShiftReg(dataShiftReg'high downto 1) <= dataShiftReg(dataShiftReg'high-1 downto 0);
        dataShiftReg(0) <= sDA;
      end if;
    end if;
  end process shiftReg;

  ------------------------------------------------------------------------------
                                                                  -- bit counter
  countBitNb: process(reset, clock)
  begin
    if reset = '1' then
      bitCounter <= (others => '0');
    elsif rising_edge(clock) then
      if startCondition = '1' then
        bitCounter <= (others => '0');
      elsif stopCondition = '1' then
        bitCounter <= (others => '0');
      elsif clRising = '1' then
        if bitCounter <= dataBitNb then
          bitCounter <= bitCounter + 1;
        else
          bitCounter <= (others => '0');
        end if;
      elsif endOfWord = '1' then
        bitCounter <= (others => '0');
      end if;
    end if;
  end process countBitNb;

  ------------------------------------------------------------------------------
               -- output data and control
               -- start and stop: MSB is '1', LSB specifies start/stop
               -- data words: MSB is '0', next is ack, 8 LSBs are data word
               -- could be made combinatorial, but sequential is easier to debug
  sendWord: process(reset, clock)
  begin
    if reset = '1' then
      dataValid <= '0';
      dataOut <= (others => '0');
    elsif rising_edge(clock) then
      dataValid <= '0';
      if startCondition = '1' then
        dataValid <= '1';
        dataOut <= (others => '0');
        dataOut(dataOut'high) <= '1';
      elsif stopCondition = '1' then
        dataValid <= '1';
        dataOut <= (others => '1');
        dataOut(dataOut'high) <= '1';
      elsif endOfWord = '1' then
        dataValid <= '1';
        dataOut <= '0' & dataShiftReg(0) & dataShiftReg(dataShiftReg'high downto 1);
      end if;
    end if;
  end process sendWord;

end RTL;
