LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF rs232DriverUVM IS
                                                                   -- parameters
  signal baudRate_int: real;
  signal baudPeriod, characterPeriod: time;
  constant uartDataBitNb: positive := 8;
  constant maxStringLength: positive := uartTransaction'length;
                                                                   -- Rx signals
  signal outString : string(1 to maxStringLength);
  signal sendString: std_uLogic := '0';
  signal outChar: character;
  signal sendChar: std_ulogic := '0';

BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  interpretTransaction: process(uartTransaction)
    variable myLine : line;
    variable commandPart : line;
    variable baudRate_nat : natural;
  begin
    write(myLine, uartTransaction);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "uart_baud" then
      read(myLine, baudRate_nat);
      baudRate_int <= real(baudRate_nat);
    elsif commandPart.all = "uart_send" then
      outString <= pad(myLine.all, outString'length);
      sendString <= '1', '0' after 1 ns;
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
      sendChar <= '1', '0' after 1 ns;
      wait for characterPeriod;
    end loop;

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
                                                               -- send start bit
    RxD <= '0';
    wait for baudPeriod;
                                                               -- send data bits
    for index in outChar_unsigned'reverse_range loop
      RxD <= outChar_unsigned(index);
      wait for baudPeriod;
    end loop;
  end process uartSendChar;

END ARCHITECTURE rtl;

