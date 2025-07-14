--
-- VHDL Architecture Sensors_test.hall_tester.test
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 10:40:41 16/09/2024
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

ARCHITECTURE test OF hall_tester IS

  -- Clock and reset
  signal lsig_clock : std_uLogic := '0';
  signal lisg_reset : std_uLogic := '1';

  -- Test "info" banner
  signal testInfo   : string(1 to 40) := (others => ' ');

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

    zeroPos <= (others => '0');
    hallPulses <= (others => '0');

      -- Wait for reset done
    wait until reset = '0';
      -- Synchronise on clock
    wait until rising_edge(clock);



    -- Your tests here
    testInfo <= pad("My test 1", testInfo'length);
    write(output, "My test 1 at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    zeroPos <= (others => '1');
    hallPulses <= (others => '0');
    wait for 1000 * g_clockPeriod; -- wait for 10 clock cycles

    
    testInfo <= pad("My test 2", testInfo'length);
    write(output, "My test 2 at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    zeroPos <= (others => '0');
    hallPulses <= (others => '1');
    wait for 1 ms; -- wait for 1 ms

    
    testInfo <= pad("My test 3", testInfo'length);
    write(output, "My test 3 at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    zeroPos <= (others => '1');
    hallPulses <= (others => '1');
    wait until rising_edge(clock); -- wait for rising edge of clock
    wait for 500 us;



    -- End of tests
    write(output, "Simulation end" & lf & lf & lf);
    testInfo <= pad("End of simulation", testInfo'length);
    wait for 1 ms;
    assert false
      report "End of simulation"
      severity failure;
    wait;

  end process;

END ARCHITECTURE test;
