LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE RTL OF uvmRs232Driver IS
                                                                   -- parameters
  signal baudRate_int: real;
  signal baudPeriod, characterPeriod: time;
  constant uartDataBitNb: positive := 9;
  constant maxStringLength: positive := driverTransaction'length;
                                                                   -- Tx signals
  signal outString : string(1 to maxStringLength);
  signal sendString: std_uLogic := '0';
  signal outChar: character;
  signal sendChar: std_ulogic := '0';
  signal sendParity, parityInit: std_ulogic := '0';
                                                                        -- debug
  signal outChar_debug: unsigned(uartDataBitNb-1 downto 0);


BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  interpretTransaction: process
    variable myLine : line;
    variable commandPart : line;
    variable baudRate_nat : natural;
    file dataFile : text;
    variable dataLine : line;
  begin
    wait on driverTransaction;
    write(myLine, driverTransaction);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "uart_baud" then
      read(myLine, baudRate_nat);
      baudRate_int <= real(baudRate_nat);
    elsif commandPart.all = "uart_parity" then
      sendParity <= '0';
      parityInit <= '0';
      if myLine.all = "even" then
        sendParity <= '1';
      elsif myLine.all = "odd" then
        sendParity <= '1';
        parityInit <= '1';
      end if;
    elsif commandPart.all = "uart_send" then
      outString <= pad(myLine.all, outString'length);
      sendString <= '1', '0' after 1 ns;
    elsif commandPart.all = "uart_send_file" then
      file_open(dataFile, "$SIMULATION_DIR/" & myLine.all, read_mode);
      while not endFile(dataFile) loop
        readLine(dataFile, dataLine);
--print(dataLine.all);
        outString <= pad(dataLine.all, outString'length);
        sendString <= '1', '0' after 1 ns;
        wait for (dataLine'length+8) * characterPeriod;
      end loop;
      file_close(dataFile);
    end if;
    deallocate(myLine);
  end process interpretTransaction;

  baudRate <= baudRate_int;
  baudPeriod <= 1.0/baudRate_int * 1 sec;
  characterPeriod <= 15*baudPeriod;

  --============================================================================
                                                      -- send string on RxD line
  uartSendString: process
    variable outStringRight: natural;
  begin
                                                             -- wait for command
    sendChar <= '0';
    wait until rising_edge(sendString);
                                                           -- find string length
    outStringRight := outString'right;
    while outString(outStringRight) = ' ' loop
      outStringRight := outStringRight-1;
    end loop;
                                                              -- send characters
    for index in outString'left to outStringRight loop
      outChar <= outString(index);
--print(sprintf("%2X", character'pos(outChar)));
      sendChar <= '1', '0' after 1 ns;
      wait for characterPeriod;
    end loop;
                                                         -- send carriage return
    outChar <= cr;
    sendChar <= '1', '0' after 1 ns;
    wait for characterPeriod;

  end process uartSendString;

  ------------------------------------------------------------------------------
                                                   -- send character on RxD line
  uartSendChar: process
    variable outChar_unsigned: unsigned(uartDataBitNb-1 downto 0);
  begin
                                                             -- wait for trigger
    RxD <= '1';
    wait until rising_edge(sendChar);
                                                 -- transform char to bit vector
    outChar_unsigned := to_unsigned(
      character'pos(outChar),
      outChar_unsigned'length
    );
    outChar_unsigned(outChar_unsigned'high) := '1';
    if sendParity = '1' then
      outChar_unsigned(outChar_unsigned'high) := parityInit;
      for index in uartDataBitNb-2 downto 0 loop
        outChar_unsigned(outChar_unsigned'high)
          := outChar_unsigned(outChar_unsigned'high)
          xor outChar_unsigned(index);
      end loop;
    end if;
    outChar_debug <= outChar_unsigned;
                                                               -- send start bit
    RxD <= '0';
    wait for baudPeriod;
                                                               -- send data bits
    for index in outChar_unsigned'reverse_range loop
      RxD <= outChar_unsigned(index);
      wait for baudPeriod;
    end loop;
  end process uartSendChar;

END ARCHITECTURE RTL;
