ARCHITECTURE RTL OF rs232ToI2c IS

  constant dataStart   : std_uLogic_vector(i2cDataBitNb-2-1 downto 0) := (others => '0');
  constant dataStop    : std_uLogic_vector(i2cDataBitNb-2-1 downto 0) := (0=> '1', others => '0');

  signal rsData: unsigned(rxData'range);
  signal ack: std_ulogic;
  signal isHex: std_ulogic;
  signal rxNibble: unsigned(3 downto 0);
  signal selectNibble: std_ulogic;
  signal i2cData: unsigned(i2cDataBitNb-2-1 downto 0);
  signal sendDataEn: std_ulogic;
  signal sendData: std_ulogic;

  signal newAnswer: std_ulogic;
  signal newControl: std_ulogic;
  signal newDataH: std_ulogic;
  signal newDataL: std_ulogic;
  signal rxDataD: std_uLogic_vector(rxData'range);
  signal txNibble: unsigned(3 downto 0);
  signal txAscii: unsigned(txData'range);

BEGIN

  ------------------------------------------------------------------------------
  -- Send commands to I2C from RS232
  --

  upperCase: process(rxData)
  begin
    if (unsigned(rxData) >= character'pos('a')) and
       (unsigned(rxData) <= character'pos('z')) then
      rsData <= unsigned(rxData) - character'pos('a') + character'pos('A');
    else
      rsData <= unsigned(rxData);
    end if;
  end process upperCase;

  storeAck: process(reset, clock)
  begin
    if reset = '1' then
      ack <= '0';
    elsif rising_edge(clock) then
      if en = '1' then
        if rxDataValid = '1' then
          if rsData = character'pos('K') then
            ack <= '0';
          elsif rsData = character'pos('N') then
            ack <= '1';
          end if;
        end if;
      end if;
    end if;
  end process storeAck;

  checkHex: process(rsData)
  begin
    if (rsData >= character'pos('0')) and (rsData <= character'pos('9')) then
      isHex <= '1';
    elsif (rsData >= character'pos('A')) and (rsData <= character'pos('F')) then
      isHex <= '1';
    else
      isHex <= '0';
    end if;
  end process checkHex;

  extractNibble: process(rsData)
  begin
    if (rsData >= character'pos('0')) and (rsData <= character'pos('9')) then
      rxNibble <= rsData(rxNibble'range);
    elsif (rsData >= character'pos('A')) and (rsData <= character'pos('F')) then
      rxNibble <= rsData(rxNibble'range) - 1 + 10;
    else
      rxNibble <= (others => '-');
    end if;
  end process extractNibble;

  toggleNibble: process(reset, clock)
  begin
    if reset = '1' then
      selectNibble <= '0';
    elsif rising_edge(clock) then
      if en = '1' then
        if rxDataValid = '1' then
          if rsData = character'pos('(') then
            selectNibble <= '1';
          elsif isHex = '1' then
            selectNibble <= not selectNibble;
          end if;
        end if;
      end if;
    end if;
  end process toggleNibble;

  storeData: process(reset, clock)
  begin
    if reset = '1' then
      i2cData <= (others => '0');
    elsif rising_edge(clock) then
      if en = '1' then
        if rxDataValid = '1' then
          if selectNibble = '0' then
            i2cData(rxNibble'range) <= rxNibble;
          else
            i2cData(i2cData'high downto i2cData'high-rxNibble'length+1) <= rxNibble;
          end if;
        end if;
      end if;
    end if;
  end process storeData;

  checkForNewWord: process(reset, clock)
  begin
    if reset = '1' then
      sendDataEn <= '0';
      sendData <= '0';
    elsif rising_edge(clock) then
      if en = '1' then
        sendData <= '0';
        if rxDataValid = '1' then
          if rsData = character'pos('(') then
            sendDataEn <= '1';
          elsif rsData = character'pos(')') then
            sendDataEn <= '0';
          end if;
          if selectNibble = '0' then
            sendData <= sendDataEn;
          end if;
        end if;
      end if;
    end if;
  end process checkForNewWord;

  sendCommand: process(reset, clock)
  begin
    if reset = '1' then
      i2cTxData <= (others => '0');
      i2cTxWr <= '0';
    elsif rising_edge(clock) then
      i2cTxWr <= '0';
      if en = '1' then
        if rxDataValid = '1' then
          if rsData = character'pos('(') then
            i2cTxData <= '1' & dataStart & ack;
            i2cTxWr <= '1';
          elsif rsData = character'pos(')') then
            i2cTxData <= '1' & dataStop & ack;
            i2cTxWr <= '1';
          end if;
        elsif sendData = '1' then
          i2cTxData <= '0' & std_ulogic_vector(i2cData) & ack;
          i2cTxWr <= '1';
        end if;
      end if;
    end if;
  end process sendCommand;

  ------------------------------------------------------------------------------
  -- Send replies from I2C to RS232
  --

  newAnswer <= not i2cRxEmpty;
  i2cRxRd <= newAnswer;

  newControl <= newAnswer when i2cRxData(i2cRxData'high) = '1' else '0';

  newDataH <= newAnswer when i2cRxData(i2cRxData'high) = '0' else '0';

  delayNewData: process(reset, clock)
  begin
    if reset = '1' then
      newDataL <= '0';
      rxDataD <= (others => '0');
    elsif rising_edge(clock) then
      newDataL <= newDataH;
      if newDataH = '1' then
        rxDataD <= i2cRxData(i2cRxData'high-1 downto i2cRxData'high-rxDataD'length);
      end if;
    end if;
  end process delayNewData;

  txWr <= newControl or newDataH or newDataL;

  txNibble <= unsigned(i2cRxData(i2cRxData'high-1 downto i2cRxData'high-txNibble'length))
                when newDataH = '1' else
              unsigned(rxDataD(txNibble'range));

  txAscii <= "0011" & txNibble when txNibble < 10 else "0100" & txNibble-9;

  selectOutput: process(newControl, newDataH, newDataL, txAscii)
  begin
    if newControl = '1' then
      if i2cRxData(0) = '0' then
        txData <= std_ulogic_vector(to_unsigned(character'pos('('), txData'length));
      else
        txData <= std_ulogic_vector(to_unsigned(character'pos(')'), txData'length));
      end if;
    else
      txData <= std_ulogic_vector(txAscii);
    end if;
  end process selectOutput;

END ARCHITECTURE RTL;
