library Common;
  use Common.CommonLib.all;

architecture RTL of i2cTransceiver is
                                                                     -- receiver
  signal clDelayed      : std_uLogic;
  signal daDelayed      : std_uLogic;
  signal clRising       : std_uLogic;
  signal clFalling      : std_uLogic;
  signal daRising       : std_uLogic;
  signal daFalling      : std_uLogic;
  signal startCondition : std_uLogic;
  signal stopCondition  : std_uLogic;
  signal bitCounter     : unsigned(requiredBitNb(dataBitNb)-1 downto 0);
  signal inputShiftReg  : std_ulogic_vector(dataBitNb-2 downto 0);
  signal clRisingDelayed: std_uLogic;
  signal endOfWord      : std_uLogic;
  signal i2cByteValid   : std_uLogic;
  signal i2cByte        : std_ulogic_vector(dataIn'range);
                                                                          -- ack
  signal ackMoment      : std_uLogic;
  signal sendAck        : std_uLogic;
                                                                      -- decoder
  type   rxStateType    is (idle, readChipAddress, readRegAddress,
                            incAddress1, incAddress);
  signal rxState        : rxStateType;
  signal chipAddress    : unsigned(chipAddr'range);
  signal registerAddress: unsigned(registerAddr'range);
  signal writeMode      : std_uLogic;

  signal loadOutShiftReg: std_uLogic;
  signal enSdaOut       : std_uLogic;
  signal outputShiftReg : std_ulogic_vector(dataBitNb-2-1 downto 0);

begin
  --============================================================================
                                             -- start, stop and other conditions
  delayInputs: process(reset, clock)
  begin
    if reset = '1' then
      clDelayed <= '1';
      daDelayed <= '1';
      clRisingDelayed <= '0';
    elsif rising_edge(clock) then
      clDelayed <= sCl;
      daDelayed <= sDaIn;
      clRisingDelayed <= clRising;
    end if;
  end process delayInputs;

  clRising <= '1' when (sCl = '1') and (clDelayed = '0') else '0';
  clFalling <= '1' when (sCl = '0') and (clDelayed = '1') else '0';
  daRising <= '1' when (sDaIn = '1') and (daDelayed = '0') else '0';
  daFalling <= '1' when (sDaIn = '0') and (daDelayed = '1') else '0';
  startCondition <= '1' when (daFalling = '1') and (sCl = '1') else '0';
  stopCondition <= '1' when (daRising = '1') and (sCl = '1') else '0';

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
      elsif clFalling = '1' then
        if bitCounter < dataBitNb-1 then
          bitCounter <= bitCounter + 1;
        else
          bitCounter <= to_unsigned(1, bitCounter'length);
        end if;
      end if;
    end if;
  end process countBitNb;

  endOfWord <= '1' when (clRisingDelayed = '1') and (bitCounter = dataBitNb-1)
    else '0';

  --============================================================================
                                                         -- input shift register
  shiftInputBits: process(reset, clock)
  begin
    if reset = '1' then
      inputShiftReg <= (others => '0');
    elsif rising_edge(clock) then
      if clRising = '1' then
        inputShiftReg(inputShiftReg'high downto 1) <= inputShiftReg(inputShiftReg'high-1 downto 0);
        inputShiftReg(0) <= sDaIn;
      end if;
    end if;
  end process shiftInputBits;

  ------------------------------------------------------------------------------
                                                -- read byte from shift register
  i2cByteValid <= '1' when (bitCounter = i2cByte'length) and (clFalling = '1')
    else '0';
  i2cByte <= inputShiftReg(i2cByte'range);

  storeByte: process(reset, clock)
  begin
    if reset = '1' then
      dataIn <= (others => '0');
    elsif rising_edge(clock) then
      if i2cByteValid = '1' then
        dataIn <= i2cByte;
      end if;
    end if;
  end process storeByte;

  --============================================================================
                                                           -- address extraction
  rxFsm: process(reset, clock)
  begin
    if reset = '1' then
      rxState <= idle;
    elsif rising_edge(clock) then
      if stopCondition = '1' then
        rxState <= idle;
      elsif startCondition = '1' then
        rxState <= readChipAddress;
      elsif endOfWord = '1' then
        case rxState is
          when readChipAddress =>
            if writeMode = '1' then
              rxState <= readRegAddress;
            else
              rxState <= incAddress1;
            end if;
          when readRegAddress =>
            rxState <= incAddress1;
          when incAddress1 =>
            rxState <= incAddress;
          when incAddress =>
            if (writeMode = '0') and (sDaIn = '1') then
              rxState <= idle;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process rxFsm;

  dataValid <= endOfWord when (rxState = incAddress1) or (rxState = incAddress)
    else '0';

  ------------------------------------------------------------------------------
                                                  -- provide running i2c address
  updateAddress: process(reset, clock)
  begin
    if reset = '1' then
      chipAddress <= (others => '0');
      registerAddress <= (others => '0');
      writeMode <= '0';
    elsif rising_edge(clock) then
      if i2cByteValid = '1' then
        case rxState is
          when readChipAddress =>
            chipAddress <= resize(
              shift_right(unsigned(i2cByte), 1),
              chipAddress'length
            );
            if i2cByte(0) = '0' then -- i2cByte(0)=0 -> master write to slave
              writeMode <= '1';
            else
              writeMode <= '0';
              registerAddress <= registerAddress + 1;
            end if;
          when readRegAddress =>
            registerAddress <= resize(unsigned(i2cByte)-1, registerAddress'length);
          when incAddress1 | incAddress =>
            registerAddress <= registerAddress + 1;
          when others => null;
        end case;
      end if;
    end if;
  end process updateAddress;

  chipAddr <= chipAddress;
  registerAddr <= registerAddress;
  writeData <= writeMode;

  ------------------------------------------------------------------------------
                                                                  -- acknowledge
  findAckMoment: process(reset, clock)
  begin
    if reset = '1' then
      ackMoment <= '0';
      sendAck <= '0';
    elsif rising_edge(clock) then
      if (bitCounter = dataBitNb-2) and (clFalling = '1') then
        ackMoment <= '1';
      elsif clFalling = '1' then
        ackMoment <= '0';
      end if;
      if ackMoment = '0' then
        sendAck <= '0';
      elsif isSelected = '1' then
        if writeMode = '1' then
          sendAck <= '1';
        elsif rxState = readChipAddress then
          sendAck <= '1';
        end if;
      end if;
    end if;
  end process findAckMoment;

  --============================================================================
                                                              -- output controls
  controlAnswering: process(reset, clock)
  begin
    if reset = '1' then
      loadOutShiftReg <= '0';
      enSdaOut <= '0';
    elsif rising_edge(clock) then
      if endOfWord = '1' then
        loadOutShiftReg <= '1';
      elsif clRising = '1' then
        loadOutShiftReg <= '0';
      end if;
      if
        (bitCounter = 1) and
        ( (rxState = incAddress1) or (rxState = incAddress) ) and
        (writeMode = '0')
      then
        if sDaIn /= '0' then  -- let master finish ack pulse
          enSdaOut <= '1';
        end if;
      elsif ( (bitCounter = dataBitNb-2) and (clFalling = '1') ) or (rxState = idle) then
        enSdaOut <= '0';
      end if;
    end if;
  end process controlAnswering;

  ------------------------------------------------------------------------------
                                                        -- output shift register
  shiftOutputBits: process(reset, clock)
  begin
    if reset = '1' then
      outputShiftReg <= (others => '0');
    elsif rising_edge(clock) then
      if loadOutShiftReg = '1' then
        outputShiftReg <= (others => '1');
        outputShiftReg(dataOut'range) <= dataOut;
      elsif clFalling = '1' then
        outputShiftReg(outputShiftReg'high downto 1) <= outputShiftReg(outputShiftReg'high-1 downto 0);
        outputShiftReg(0) <= '0';
      end if;
    end if;
  end process shiftOutputBits;

  ------------------------------------------------------------------------------
                                                        -- reply to read request
  sDaOut <= '0' when sendAck = '1'
    else outputShiftReg(outputShiftReg'high) when enSdaOut = '1'
    else '1';

end RTL;
