--
-- VHDL Architecture Sensors_test.ultrasound_tester.test
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 11:22:22 16/09/2024
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

LIBRARY std;
  USE std.textio.ALL;

LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;

LIBRARY Common_test;
  USE Common_test.testutils.all;

Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE test OF ultrasound_tester IS

  -- Clock and reset
  signal lsig_clock : std_uLogic := '0';
  signal lisg_reset : std_uLogic := '1';

  -- Test "info" banner
  signal testInfo   : string(1 to 40) := (others => ' ');

  constant c_WAIT_NEXT_COUNT : time := 340 ms;

BEGIN

  -- Clock and reset
  lisg_reset <= '1', '0' after 4*g_clockPeriod;
  reset <= lisg_reset;

  lsig_clock <= not lsig_clock after g_clockPeriod/2;
  clock <= transport lsig_clock after 0.9*g_clockPeriod;


  -- Test sequence
  process
  begin
    
    -- Init
    testInfo <= pad("Init", testInfo'length);
    write(output, "System init" & lf & lf & lf & lf);

    distancePulse <= '0';
    testMode <= '0';

      -- Wait for reset done
    wait until reset = '0';
      -- Synchronise on clock
    wait until rising_edge(clock);

    -- Ultrasound should output a pulse each 49ms of a length between 0.88 and 37.5ms

    -- Wait until startNextCount pulse, wait a bit more, and generate a pulse
    testInfo <= pad("Simple pulse of 15ms", testInfo'length);
    write(output, "Simple pulse 15ms test at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    wait for c_WAIT_NEXT_COUNT;
    wait for 0.7 ms;
    distancePulse <= '1';
    wait for 15 ms;
    distancePulse <= '0';
    wait for 20 ms;
    assert distance /= 15000
      report "Simple pulse 15ms test done"
      severity note;
    assert distance = 15000
      report "Simple pulse 15ms test failed - distance=" & integer'image(to_integer(distance)) & " expected=15000"
      severity failure;
    wait for 30 ms;

    testInfo <= pad("Simple pulse of 32ms", testInfo'length);
    write(output, "Simple pulse 32ms test at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    wait for c_WAIT_NEXT_COUNT;
    wait for 2 ms;
    distancePulse <= '1';
    wait for 32 ms;
    distancePulse <= '0';
    wait for 10 ms;
    assert distance /= 32000
      report "Simple pulse 32ms test done"
      severity note;
    assert distance = 32000
      report "Simple pulse 32ms test failed - distance=" & integer'image(to_integer(distance)) & " expected=32000"
      severity failure;
    wait for 90 ms;

    testInfo <= pad("Three pulses after startNextCount", testInfo'length);
    write(output, "Three pulses after startNextCount at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    wait for c_WAIT_NEXT_COUNT;
    wait for 1 ms;
    distancePulse <= '1';
    wait for 31 ms;
    distancePulse <= '0';
    wait for 4 ms;
    assert distance /= 31000
      report "Three pulses 31ms test 1 done"
      severity note;
    assert distance = 31000
      report "Three pulses 31ms test 1 failed - distance=" & integer'image(to_integer(distance)) & " expected=31000"
      severity failure;
    wait for 14 ms;
    distancePulse <= '1';
    wait for 13 ms;
    distancePulse <= '0';
    wait for 3 ms;
    assert distance /= 31000
      report "Three pulses 31ms test 2 done"
      severity note;
    assert distance = 31000
      report "Three pulses 31ms test 2 failed - distance=" & integer'image(to_integer(distance)) & " expected=31000"
      severity failure;
    wait for 33 ms;
    distancePulse <= '1';
    wait for 27 ms;
    distancePulse <= '0';
    wait for 5 ms;
    assert distance /= 31000
      report "Three pulses 31ms test 3 done"
      severity note;
    assert distance = 31000
      report "Three pulses 31ms test 3 failed - distance=" & integer'image(to_integer(distance)) & " expected=31000"
      severity failure;
    wait for 5 ms;

    testInfo <= pad("Bad pulse of 0.52 ms", testInfo'length);
    write(output, "Bad pulse test at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    wait for c_WAIT_NEXT_COUNT;
    wait for 1 ms;
    distancePulse <= '1';
    wait for 0.52 ms;
    distancePulse <= '0';
    wait for 10 ms;
    report "Pulse of 0.52 ms - test result depends on implementation" severity note;
    wait for 90 ms;
    
    testInfo <= pad("Bad pulse of 40 ms", testInfo'length);
    write(output, "Bad pulse test at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    wait for c_WAIT_NEXT_COUNT;
    wait for 5 ms;
    distancePulse <= '1';
    wait for 40 ms;
    distancePulse <= '0';
    wait for 10 ms;
    report "Pulse of 40 ms - test result depends on implementation" severity note;
    wait for 90 ms;

    -- End of tests
    write(output, "Simulation end" & lf & lf & lf);
    testInfo <= pad("End of simulation", testInfo'length);
    wait for 1 ms;
    report "End of simulation" severity failure;
    wait;

  end process;

END ARCHITECTURE test;
