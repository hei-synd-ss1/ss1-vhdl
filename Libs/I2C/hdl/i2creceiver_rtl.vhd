library Common;
  use Common.CommonLib.all;

architecture RTL of i2cReceiver is

  signal clDelayed: std_logic;
  signal daDelayed: std_logic;
  signal clRising: std_uLogic;
  signal daRising: std_uLogic;
  signal daFalling: std_uLogic;
  signal startCondition: std_uLogic;
  signal stopCondition: std_uLogic;
  signal dataShiftReg: std_ulogic_vector(dataBitNb downto 0);       -- dataBitNb+1 bits
  signal bitCounter: unsigned(requiredBitNb(dataBitNb+1) downto 0); -- dataBitNb bits
  signal clRisingDelayed: std_uLogic;
  signal endOfWord: std_uLogic;
  signal endOfWordNoAck: std_uLogic;

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
  endOfWord <= '1' when (clRisingDelayed = '1') and (bitCounter = dataBitNb+1) else '0';
  endOfWordNoAck <= '1' when (clRisingDelayed = '1') and (bitCounter = dataBitNb) else '0';

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
        if bitCounter < (dataBitNb + 1) then -- dataBitNb + ack bit
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
      ackBit <= '0';
      startReceived <= '0';
      stopReceived <= '0';
    elsif rising_edge(clock) then
      dataValid <= '0';
      ackBit <= '0';
      startReceived <= '0';
      stopReceived <= '0';
      if startCondition = '1' then
        dataValid <= '1';
        startReceived <= '1';
      elsif stopCondition = '1' then
        dataValid <= '1';
        stopReceived <= '1';
      elsif endOfWord = '1' and isTransmitting = '1' then
        dataValid <= '1';
        dataOut <= dataShiftReg(dataShiftReg'high downto 1);
        ackBit <= not dataShiftReg(0); 
      elsif endOfWordNoAck = '1' and isTransmitting = '0' then
        dataValid <= '1';
        dataOut <= dataShiftReg(dataShiftReg'high-1 downto 0);
      end if;
    end if;
  end process sendWord;

end RTL;