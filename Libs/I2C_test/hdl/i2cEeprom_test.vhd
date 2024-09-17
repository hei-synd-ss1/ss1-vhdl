library BoardTester;
  use BoardTester.BoardTesterLib.all;

ARCHITECTURE test OF i2cEeprom IS

  constant dataBitNb : positive := 8;
  constant memoryWordLength : positive := dataBitNb;
  constant memoryArrayLength : positive := 2**addressBitNb;

  signal reset: std_uLogic;

  signal sDaIn: std_uLogic;
  signal startCondition: std_uLogic;
  signal stopCondition: std_uLogic;
  signal dataShiftReg: std_ulogic_vector(dataBitNb downto 0);
  signal i2cData: std_ulogic_vector(dataBitNb-1 downto 0);
  signal i2cDataDisplay: std_ulogic_vector(i2cData'range);
  signal bitCounter: unsigned(requiredBitNb(dataBitNb+1)-1 downto 0);
  signal endOfWord: std_uLogic;
  signal isSelected: std_uLogic;
  signal sDaUpdateTime: std_uLogic := '0';
  signal ackTime: std_uLogic;
  signal readWrite: std_uLogic;

  subtype memoryWord is std_ulogic_vector(memoryWordLength-1 downto 0);
  type memoryArray is array(0 to memoryArrayLength-1) of memoryWord;
  signal memoryContent: memoryArray;
  signal memoryAddress: unsigned(addressBitNb-1 downto 0);
  signal currentWord: memoryWord;

  type stateType is (IDLE, CHK_CTL, ADDR_H, ADDR_L, DATA_RD, DATA_WR);
  signal currentState: stateType;

BEGIN

  reset <= '1', '0' after 1 ns;

  sDaIn <= To_X01(sDa);

  startCondition <= '1', '0' after 1 ns when falling_edge(sDaIn) and (sCl /= '0') else '0';
  stopCondition <= '1', '0' after 1 ns when rising_edge(sDaIn) and (sCl /= '0') else '0';
  endOfWord <= '1' after 1 ns when bitCounter = dataBitNb+1 else '0' after 1 ns;

  shiftReg: process(reset, sCl)
  begin
    if reset = '1' then
      dataShiftReg <= (others => '0');
    elsif rising_edge(sCl) then
      dataShiftReg(dataShiftReg'high downto 1) <= dataShiftReg(dataShiftReg'high-1 downto 0);
      dataShiftReg(0) <= sDaIn;
    end if;
  end process shiftReg;

  i2cData <= dataShiftReg(dataShiftReg'high downto dataShiftReg'high-dataBitNb+1);
  i2cDataDisplay <= i2cData when falling_edge(ackTime);

  countBitNb: process(reset, startCondition, sCl, endOfWord)
  begin
    if reset = '1' then
      bitCounter <= (others => '0');
    elsif startCondition = '1' then
      bitCounter <= (others => '0');
    elsif rising_edge(sCl) then
      bitCounter <= bitCounter + 1;
    elsif endOfWord = '1' then
      bitCounter <= (others => '0');
    end if;
  end process countBitNb;

  checkSelected: process(reset, sCl, startCondition, stopCondition)
  begin
    if reset = '1' then
      isSelected <= '0';
    elsif (currentState = CHK_CTL) and falling_edge(sCl) then
      if (bitCounter = dataBitNb-1)
      and (dataShiftReg(dataBitNb-2 downto 0) = "1010" & addr) then
        isSelected <= '1';
      end if;
    elsif startCondition = '1' then
      isSelected <= '0';
    elsif stopCondition = '1' then
      isSelected <= '0';
    end if;
  end process checkSelected;

  sDaUpdateTime <= '1' after 1 us, '0' after 2 us when falling_edge(sCl);

  frameAck: process(reset, sDaUpdateTime)
  begin
    if reset = '1' then
      ackTime <= '0';
    elsif rising_edge(sDaUpdateTime) then
      if bitCounter = dataBitNb then
        ackTime <= '1';
      else
        ackTime <= '0';
      end if;
    end if;
  end process frameAck;

  readWrite <= dataShiftReg(1);

  FSM: process(reset, startCondition, endOfWord, stopCondition)
  begin
    if reset = '1' then
      currentState <= IDLE;
    elsif startCondition = '1' then
      currentState <= CHK_CTL;
    elsif stopCondition = '1' then
      currentState <= IDLE;
    else
      case currentState is
        when IDLE =>
          if startCondition = '1' then
            currentState <= CHK_CTL;
          end if;
        when CHK_CTL =>
          if endOfWord = '1' then
            if isSelected = '1' then
              if readWrite = '1' then
                currentState <= DATA_RD;
              else
                currentState <= ADDR_H;
              end if;
            else
              currentState <= IDLE;
            end if;
          end if;
        when ADDR_H =>
          if endOfWord = '1' then
            currentState <= ADDR_L;
          end if;
        when ADDR_L =>
          if endOfWord = '1' then
            currentState <= DATA_WR;
          end if;
        when DATA_RD =>
          if (endOfWord = '1') and (sDaIn = '1') then
            currentState <= IDLE;
          end if;
        when others => null;
      end case;
    end if;
  end process FSM;

  ack: process(ackTime)
  begin
    sDa <= 'H';
    if rising_edge(ackTime) and (isSelected = '1') then
      if currentState = CHK_CTL then
        sDa <= '0';
      elsif currentState = ADDR_H then
        sDa <= '0';
      elsif currentState = ADDR_L then
        sDa <= '0';
      elsif currentState = DATA_WR then
        sDa <= '0';
      end if;
    end if;
  end process ack;

  updateAddress: process(reset, endOfWord)
  begin
    if reset = '1' then
      memoryAddress <= (others => '0');
    elsif endOfWord = '1' then
      if currentState = ADDR_H then
        memoryAddress <=
          shift_left(
            resize(
              unsigned(i2cData),
              memoryAddress'length
            ),
            dataBitNb
          );
      elsif currentState = ADDR_L then
        memoryAddress(dataBitNb-1 downto 0) <= unsigned(i2cData);
      elsif (currentState = DATA_WR) or (currentState = DATA_RD) then
        memoryAddress <= memoryAddress + 1;
      end if;
    end if;
  end process updateAddress;

  updateMemory: process(endOfWord)
  begin
    if endOfWord = '1' then
      if currentState = DATA_WR then
        memoryContent(to_integer(memoryAddress)) <= i2cData;
      end if;
    end if;
  end process updateMemory;

  currentWord <= memoryContent(to_integer(memoryAddress));

  writeData: process(reset, sDaUpdateTime)
  begin
    if reset = '1' then
      sDa <= 'H';
    elsif rising_edge(sDaUpdateTime) then
      sDa <= 'H';
      if currentState = DATA_RD then
        if bitCounter < dataBitNb then
          if currentWord(dataBitNb - to_integer(bitCounter) - 1) = '0' then
            sDa <= '0';
          end if;
        end if;
      end if;
    end if;
  end process writeData;

END ARCHITECTURE test;
