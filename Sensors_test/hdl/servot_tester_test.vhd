--
-- VHDL Architecture Sensors_test.servot_tester.test
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 11:43:36 16/09/2024
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

ARCHITECTURE test OF servo_tester IS

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

    count_target <= std_ulogic_vector(to_unsigned(0, count_target'length));

      -- Wait for reset done
    wait until reset = '0';
      -- Synchronise on clock
    wait until rising_edge(clock);



    -- Your tests here
    testInfo <= pad("My test 1", testInfo'length);
    write(output, "My test 1 at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    count_target <= std_ulogic_vector(to_unsigned(0, count_target'length));
    wait for 5500 * g_clockPeriod; -- wait for 5500 clock cycles

    
    testInfo <= pad("My test 2", testInfo'length);
    write(output, "My test 2 at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    count_target <= std_ulogic_vector(to_unsigned(5678, count_target'length));
    wait for 3 ms; -- wait for 3 ms

    
    testInfo <= pad("My test 3", testInfo'length);
    write(output, "My test 3 at time " & integer'image(now/1 us) & " us" & lf & lf & lf & lf);
    count_target <= std_ulogic_vector(to_unsigned(1234, count_target'length));
    wait until rising_edge(clock); -- wait for rising edge of clock
    wait for 3 ms;



    -- End of tests
    write(output, "Simulation end" & lf & lf & lf);
    testInfo <= pad("End of simulation", testInfo'length);
    wait for 1 ms;
    assert false
      report "End of simulation"
      severity failure;
    wait;

  end process;

  process
  begin
    while true loop
      pulse_20ms <= '0';
      wait for 30000.0 * g_clockPeriod;
      wait for 0.5 * g_clockPeriod;
      pulse_20ms <= '1';
      wait until rising_edge(clock);
    end loop;
  end process;

END ARCHITECTURE test;
