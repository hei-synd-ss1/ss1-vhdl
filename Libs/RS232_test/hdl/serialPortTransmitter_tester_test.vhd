-- restart -f ; run 34 ms

ARCHITECTURE test OF serialPortTransmitter_tester IS
                                                              -- reset and clock
  constant clockPeriod: time := (1.0/clockFrequency) * 1 sec;
  signal clock_int: std_uLogic := '1';
                                                                      -- Tx test
  constant rs232Frequency: real := baudRate;
  constant rs232Period: time := (1.0/rs232Frequency) * 1 sec;
  constant rs232WriteInterval: time := 20*rs232Period;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  reset <= '1', '0' after 2*clockPeriod;

  clock_int <= not clock_int after clockPeriod/2;
  clock <= transport clock_int after clockPeriod*9/10;

  ------------------------------------------------------------------------------
                                                                      -- Tx test
  process
  begin

    dataIn <= (others => '0');
    send <= '0';
    wait for rs232Period;

    for index in 0 to 2**dataBitNb-1 loop
      dataIn <= std_ulogic_vector(to_unsigned(index, dataIn'length));
      wait until rising_edge(clock_int);
      send <= '1';
      wait until rising_edge(clock_int);
      send <= '0';
      wait for rs232WriteInterval;
    end loop;

    wait;

  end process;

END ARCHITECTURE test;
