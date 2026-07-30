LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE RTL OF clockDriver IS
                                                                   -- parameters
  constant clockPeriodInit: time := 2 ns;
  signal clockFrequency : real;
  signal clockPeriod: time := clockPeriodInit;
  signal clock_int: std_ulogic := '1';
  signal reset_int: std_ulogic := '0';

BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  interpretTransaction: process(driverTransaction)
    variable myLine : line;
    variable commandPart : line;
    variable frequency_nat : natural;
  begin
    reset_int <= '0';
    write(myLine, driverTransaction);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "clock_frequency" then
      read(myLine, frequency_nat);
      clockFrequency <= real(frequency_nat);
    elsif commandPart.all = "reset" then
      reset_int <= '1';
    end if;
    deallocate(myLine);
  end process interpretTransaction;

  clockPeriod <= 1.0/clockFrequency * 1 sec when clockFrequency > 0.0;

  --============================================================================
                                                                        -- clock
  clock_int <= not clock_int after clockPeriod/2;
  clock <= transport clock_int after clockPeriod*9/10;
                                                                        -- reset
  driveReset: process
  begin
    reset <= '1';
    while clockPeriod = clockPeriodInit loop
      wait until clockPeriod'event;
    end loop;
    wait for 2*clockPeriod;
    reset <= '0';
    wait until rising_edge(reset_int);
  end process driveReset;

END ARCHITECTURE RTL;
