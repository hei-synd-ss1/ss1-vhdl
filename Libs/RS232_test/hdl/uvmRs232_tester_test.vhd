LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE test OF uvmRs232_tester IS
                                                              -- reset and clock
  constant clockPeriod: time := (1.0/clockFrequency) * 1 sec;
  signal clock_int: std_uLogic := '1';
                                                                  -- RS232 speed
  constant rs232Period: time := (1.0/rs232BaudRate) * 1 sec;
                                                                     -- RS232 Rx
  signal rs232RxChar : character := ' ';
                                                                     -- RS232 Tx
  signal rs232TxString : string(1 to 32);
  signal rs232SendString: std_uLogic;
  signal rs232SendDone: std_uLogic;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  reset <= '1', '0' after 2*clockPeriod;

  clock_int <= not clock_int after clockPeriod/2;
  clock <= transport clock_int after clockPeriod*9/10;

  ------------------------------------------------------------------------------
                                                                  -- Tx sequence
  txSequence : process
  begin
    rs232SendString <= '0';
    rs232TxString <= (others => ' ');
    wait for 500 us;
                                                                    -- send 'Hi'
    rs232TxString <= pad("Hi", rs232TxString'length);
    rs232SendString <= '1', '0' after 1 ns;
    wait until rs232SendDone = '1';
                                                          -- end of transmission
    wait;
  end process txSequence;

  --============================================================================
                                                                     -- RS232 Rx
  storeRxByte: process(clock_int)
  begin
    if rising_edge(clock_int) then
      if dataValid = '1' then
        rs232RxChar <= character'val(to_integer(unsigned(dataOut)));
      end if;
    end if;
  end process storeRxByte;

  ------------------------------------------------------------------------------
                                                                     -- RS232 Tx
  rsSendString: process
    constant rs232CharPeriod : time := 15*rs232Period;
    variable outStringRight: natural;
    variable outchar: character;
  begin
                                                             -- wait for command
    send <= '0';
    dataIn <= (others => '0');
    rs232SendDone <= '0';
    wait until rising_edge(rs232SendString);
                                                           -- find string length
    outStringRight := rs232TxString'right;
    while rs232TxString(outStringRight) = ' ' loop
      outStringRight := outStringRight-1;
    end loop;
                                                              -- send characters
    for index in rs232TxString'left to outStringRight loop
      outchar := rs232TxString(index);
      dataIn <= std_ulogic_vector(to_unsigned(
        character'pos(outchar), dataIn'length
      ));
      wait until rising_edge(clock_int);
      send <= '1', '0' after clockPeriod;
      wait for rs232CharPeriod;
    end loop;
                                                         -- send carriage return
    outchar := cr;
    dataIn <= std_ulogic_vector(to_unsigned(
      character'pos(outchar), dataIn'length
    ));
    wait until rising_edge(clock_int);
    send <= '1', '0' after clockPeriod;
    wait for rs232CharPeriod;
                                                        -- signal end of sending
    rs232SendDone <= '1';
    wait for 1 ns;

  end process rsSendString;

END ARCHITECTURE test;
