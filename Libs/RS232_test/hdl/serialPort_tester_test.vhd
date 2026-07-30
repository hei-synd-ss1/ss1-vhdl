--====================================================================--
-- Design units : RS232_test.serialPort_tester.test
--
-- File name : serialPort_tester.vhd
--
-- Purpose : Tester for both serialPort receivers and transmitters
--  Writes a string to UART and checks that read data from receiver block is the same.
--  No automated test for transmitter.
--
-- Library : RS232_test
--
-- Dependencies : None
--
-- Author : Axam
-- HES-SO Valais/Wallis
-- Route de l'Industrie 23
-- 1950 Sion
-- Switzerland
--
-- Design tool : HDL Designer 2019.2 (Build 5)
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author Date           Changes
-- 1.0     AMA    16.04.2025     Initial release
--

USE std.textio.ALL;
  use std.env.stop;

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

LIBRARY Common_test;
  USE Common_test.testutils.all;

ARCHITECTURE test OF serialPort_tester IS

  -- Clock
  constant clockFrequency: real := g_CLOCK_FREQUENCY;
  constant clockPeriod: time := (1.0/clockFrequency) * 1 sec;
  signal sClock: std_uLogic := '1';

  -- Test metadata
  signal testInfo, subTestInfo : string(1 to 40) := (others => ' ');
    -- Separator for output write
  constant separator : string := "----------------------------------------" & lf & lf;

  -- For test
  signal lvec_data_out : std_uLogic_vector(7 downto 0);
  constant c_BAUD_PERIOD: time := clockPeriod * g_BAUD_RATE_DIVIDER;

BEGIN

  -- Clock / rst generation
  sClock <= not sClock after clockPeriod/2;
  clk <= transport sClock after 6*clockPeriod + clockPeriod*9/10;
  rst <= 'U', '0' after 2*clockPeriod, '1' after 4*clockPeriod, '0' after 15.3*clockPeriod;

  process
    -- String which will be sent
    variable send_str : string(1 to 15) := "Hello World 123";
  begin

    -- Default values
    testInfo <= pad("Wait reset done", testInfo'length);
    subTestInfo <= pad("Wait reset done", subTestInfo'length);
    wait for 1.3*clockPeriod;
    rxd <= '1';

    -- Wait reset done
    wait until falling_edge(rst);
    write(output,
      "[TB] Reset done" & lf &
      "    at time " & integer'image(now/1 ns) & " ns" &
      lf & lf
    );
    write(output, separator);
    wait until rising_edge(clk);
    testInfo <= pad("Reset done", testInfo'length);
    wait for 100 * clockPeriod;


    -- Send all characters of the string
    for i in send_str'range loop

      lvec_data_out <= std_ulogic_vector( to_unsigned( character'pos( send_str(i) ), lvec_data_out'length ) );
      wait for 0 ns; -- needed for lvec_data_out to update

      -- Send start bit
      testInfo <= pad("Send data: " & to_string(lvec_data_out), testInfo'length);
      subTestInfo <= pad("Send start", subTestInfo'length);
      write(output,
        "[TB] Send start" & lf &
        "    at time " & integer'image(now/1 ns) & " ns" &
        lf & lf
      );
      write(output, separator);
      rxd <= '0'; -- Start bit
      wait for c_BAUD_PERIOD;

      -- Send all bits of vector
      for i in 0 to 7 loop
        subTestInfo <= pad("Send bit: " & integer'image(i), subTestInfo'length);
        write(output,
          "[TB] Send bit: " & integer'image(i) & lf &
          "    at time " & integer'image(now/1 ns) & " ns" &
          lf & lf
        );
        write(output, separator);
        if g_LSB_FIRST then
          rxd <= lvec_data_out(i);
        else
          rxd <= lvec_data_out(7 - i);
        end if;
        wait for c_BAUD_PERIOD;
      end loop;

      -- Send parity
      if g_USE_PARITY = '1' then
        subTestInfo <= pad("Send parity", subTestInfo'length);
        write(output,
          "[TB] Send parity" & lf &
          "    at time " & integer'image(now/1 ns) & " ns" &
          lf & lf
        );
        write(output, separator);
        if g_PARITY_IS_EVEN = '1' then
          rxd <= xor lvec_data_out;
        else
          rxd <= xnor lvec_data_out;
        end if;
        wait for c_BAUD_PERIOD;
      end if;

      -- Stop
      subTestInfo <= pad("Send stop", subTestInfo'length);
      write(output,
        "[TB] Send stop" & lf &
        "    at time " & integer'image(now/1 ns) & " ns" &
        lf & lf
      );
      write(output, separator);
      rxd <= '1';
      wait for c_BAUD_PERIOD;

      -- Check if input byte is the same as sent byte
      assert read_byte = lvec_data_out report "Data received is not correct" severity failure;

    end loop;
  
    -- Wait for transmitter to echo all characters
    testInfo <= pad("Wait for send to finish", testInfo'length);
    subTestInfo <= pad("Wait for send to finish", subTestInfo'length);
    write(output,
      "[TB] Wait for send to finish" & lf &
      "    at time " & integer'image(now/1 ns) & " ns" &
      lf & lf
    );
    write(output, separator);
    wait until falling_edge(is_sending);
    testInfo <= pad("Done", testInfo'length);
    subTestInfo <= pad("Done", subTestInfo'length);
    write(output,
      "[TB] Done" & lf &
      "    at time " & integer'image(now/1 ns) & " ns" &
      lf & lf
    );
    write(output, separator);
    wait for 100 * clockPeriod;

    -- Send a bad start bit to see if the system reacts
    testInfo <= pad("Send bad start bit", testInfo'length);
    subTestInfo <= pad("Send bad start bit", subTestInfo'length);
    write(output,
      "[TB] Send bad start bit" & lf &
      "    at time " & integer'image(now/1 ns) & " ns" &
      lf & lf
    );
    write(output, separator);
    rxd <= '0';
    wait for 10 * clockPeriod;
    rxd <= '1';
    wait for 12 * c_BAUD_PERIOD;

    -- End of simulation
    wait for 10 * clockPeriod;
    testInfo <= pad("Simulation End", testInfo'length);
    subTestInfo <= pad("Simulation End", subTestInfo'length);
    wait for 100 * clockPeriod;
    write(output,
      "[TB] Testbench end" & lf &
      "    at time " & integer'image(now/1 ns) & " ns" &
      lf & lf
    );
    --stop;
    wait;

  end process;

END ARCHITECTURE test;
