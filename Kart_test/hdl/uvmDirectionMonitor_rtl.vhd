LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmDirectionMonitor IS

  signal p_testmode : std_ulogic := '0';
  signal p_logCmd : std_ulogic := '0';
  signal p_servoCmd : natural := 0;
  signal p_logInPulse : std_ulogic := '0';
  signal p_per_servo_ontime : time := 0 ns;
  signal p_per_servo_offtime : time := 0 ns;

BEGIN

  interpretTransaction: process(transactionIn)
    variable myLine : line;
    variable commandPart, argPart : line;
    variable argm : natural := 0;
  begin
    p_logCmd <= '0';
    write(myLine, transactionIn);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "dmot_target_command" then
      -- Expected number of steps to do
      read_first(myLine, argPart);
      read(argPart, argm);
      p_logCmd <= '1';
      p_servoCmd <= argm;
    elsif commandPart.all = "dmot_testmode" then
      -- If testmode
      read_first(myLine, argPart);
      read(argPart, argm);
      p_testmode <= '1' when argm /= 0 else '0';
    end if;
    deallocate(myLine);
  end process interpretTransaction;

  testMode <= p_testmode;

  checkServo: process
    variable per_begin : time := 0 ns;
  begin
    -- Wait for pulse to begin
    wait until rising_edge(dirServo);
    while(true) loop
      p_logInPulse <= '0';
      -- Began, count time until pulse ends
      per_begin := now;
      wait until falling_edge(dirServo) for 20 ms;
      p_per_servo_ontime <= now - per_begin;
      -- Wait for rising edge again or timeout
      wait until rising_edge(dirServo) for 20 ms;
      p_per_servo_offtime <= now - per_begin - p_per_servo_ontime;
      -- Log
      p_logInPulse <= '1';
      wait for 1 ns; -- To acknowledge signals change
    end loop;
  end process checkServo;

  reportBusAccess: process(p_logInPulse, p_logCmd)
  begin
    if rising_edge(p_logInPulse) then
      dmotMonitor <= pad(
        "Got servo pulse " & sprintf("%d", natural(p_per_servo_ontime / 1 us)) & "us on - " & sprintf("%d", natural(p_per_servo_offtime / 1 us)) & "us off - " & sprintf("%d", natural((p_per_servo_ontime + p_per_servo_offtime) / 1 us)) & "us total",
        dmotMonitor'length
      );
    elsif rising_edge(p_logCmd) then
      dmotMonitor <= pad(
        "Got servo command " & sprintf("%d", natural(p_servoCmd)),
        dmotMonitor'length
      );
    end if;
  end process reportBusAccess;

END ARCHITECTURE rtl;
