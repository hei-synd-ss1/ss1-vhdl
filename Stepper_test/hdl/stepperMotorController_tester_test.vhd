LIBRARY std;
  USE std.textio.ALL;

LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;

LIBRARY Common_test;
  USE Common_test.testutils.all;

Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE test OF stepperMotorController_tester IS

  constant clockPeriod  : time := 1.0/CLOCK_FREQUENCY * 1 sec;
  signal sClock         : std_uLogic := '1';
  signal sReset         : std_uLogic ;

  constant testInterval : time := 200 us;
  signal testInfo       : string(1 to 40) := (others => ' ');


  -- DUT readout values
  signal dutReached: std_ulogic;
  signal dutPosition: natural;

  -- Coils analysis
  signal coils, prevCoils: std_ulogic_vector(1 to 5);
  signal turn1to4, turnBack: std_ulogic;
  signal lastCoilOn : natural;
  signal lastEvent: time;
  signal onTime: integer;

  -- Steering values
    -- f of 100kHz / divideValue, here 10kHz
  constant stepDivideValue: positive := 10;
  constant angleMaxValue: positive := 1E3;
  signal hardwareOrientation: natural;

  -- Registers definitions
  constant stpBaseReadAddr : natural := REG_STEP_ADDR * 2**6;
  constant stpBaseWriteAddr : natural := stpBaseReadAddr + 1 * 2**5;

  constant prescalerWRAddr : natural :=
    stpBaseWriteAddr + STP_CLOCKDIVIDER_REG_POS;
  constant targetAngleWRAddr : natural :=
    stpBaseWriteAddr + STP_TARGETANGLE_REG_POS;

  constant actualAngleRDAddr : natural := stpBaseReadAddr + STP_ANGLE_EXT_REG_POS;
  constant hwRDAddr : natural := stpBaseReadAddr + STP_HW_EXT_REG_POS;

  constant stpPeriod : time := 1 sec / (STP_MAX_FREQ / real(stepDivideValue));

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  sReset <= '1', '0' after 4*clockPeriod;
  reset <= sReset;

  sClock <= not sClock after clockPeriod/2;
  clock <= transport sClock after 0.9*clockPeriod;

  ------------------------------------------------------------------------------
                                                                       -- others
  hwOrientation <= dataRegisterType
  (
    to_unsigned(hardwareOrientation, hwOrientation'length)
  );

  ------------------------------------------------------------------------------
                                                                -- test sequence
  process

      procedure setReg(constant address : in natural;
                       constant data    : in natural) is
      begin
        assert(
          to_unsigned(address, addressIn'length)(REG_ADDR_GET_BIT_POSITION)
          = '1') report "Address is not writable" severity failure;
        addressIn <= symbolSizeType(to_unsigned(address, addressIn'length));
        dataIn <= dataRegisterType(to_unsigned(data, dataIn'length));
        regWr <= '1', '0' after clockPeriod * 1.1;
      end procedure;


      procedure readReg(constant address : in natural) is
      begin
        assert(
          to_unsigned(address, addressIn'length)(REG_ADDR_GET_BIT_POSITION)
          = '0') report "Address is not readable" severity failure;
        addressIn <= symbolSizeType(to_unsigned(address, addressIn'length));
        dataIn <= dataRegisterType(to_unsigned(0, dataIn'length));
        regWr <= '1', '0' after clockPeriod * 1.1;
      end procedure;

      variable time1, time2 : time := 0 ns;

  begin
    -- Init signals
    testMode <= '0';
    stepperEnd <= '0';
    hardwareOrientation <= 2#111#;
    dataIn <= (others=>'0');
    addressIn <= (others=>'0');
    regWr <= '0';
    stepperSendAuth <= '1';
    dutReached <= '1';
    dutPosition <= 0;

    wait for 1 ns;
    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );

                                                               -- send prescaler
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending step divider value " & sprintf("%d", stepDivideValue) &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(prescalerWRAddr, stepDivideValue);
    wait for testInterval;

                                                                 -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= 16#10# + hardwareOrientation;
    wait for testInterval/10;
    wait for 5*testInterval;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

                                                              -- Release restart
    testInfo <= pad("Restart off", testInfo'length);
    write(output,
      "Setting restart bit low - motor should continue to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= hardwareOrientation - 16#10#;
    wait for 3*testInterval;

                                                           -- actuate end switch
    testInfo <= pad("End switch local", testInfo'length);
    wait for 3*testInterval;
    wait until rising_edge(coil4) for 1 ms;
    write(output,
      "Actuating end of turn switch" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    if coil4 = '0' then
      write(output,
      "Error : coil4 should be '1' - continuing with the simulation anyway" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    end if;
    stepperEnd <= '1';
    wait for 6*testInterval;
    
                                                           -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    case lastCoilOn is
      when 1 =>
        wait until rising_edge(coil1) for 1 ms;
        if coil1 = '0' then
          write(output,
            "Error : Coil problem detected - coil1 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 2 =>
        wait until rising_edge(coil2) for 1 ms;
        if coil2 = '0' then
          write(output,
            "Error : Coil problem detected - coil2 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 3 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 4 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when others =>
        write(output,
            "Error : Coil problem detected - no coil rose since beginning -" &
            " continuing simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
    end case;
    stepperEnd <= '0';
    wait for testInterval;

                                                               -- ask for status 
                    -- wait for less than quarter angle delay and ask for status
    wait for angleMaxValue/4 * stpPeriod / 4;
    --testInfo <= pad("Ask for status", testInfo'length);
    write(output,
      "Asking for status" &
      " at time " & integer'image(now/1 us) & " us" &
      lf &
      "  Reached should be 0" &
      lf & lf
    );
    readReg(hwRDAddr);
    stepperSendAuth <= '0';
    wait until stepperSendRequest = '1';
    dutReached <= stepperDataToSend(1);
    stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
    assert dutReached /= '0'
      report "Reached flag error"
      severity error;
    assert dutReached = '0'
      report "Reached flag OK"
      severity note;
    assert turn1to4 = not turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report"Coil direction OK"
      severity note;
    write(output, "" & lf);

                                      -- wait for end of turn and ask for status
    --testInfo <= pad("Turn 1/4", testInfo'length);
    wait for angleMaxValue/4 * stpPeriod;
    --testInfo <= pad("Ask for status", testInfo'length);
    write(output,
      "Asking for status" &
      " at time " & integer'image(now/1 us) & " us" &
      lf &
      "    Reached should be 1" &
      lf & lf
    );
    readReg(hwRDAddr);
    stepperSendAuth <= '0';
    wait until stepperSendRequest = '1';
    dutReached <= stepperDataToSend(1);
    stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
    assert dutReached /= '1'
      report "Reached flag error"
      severity error;
    assert dutReached = '1'
      report "Reached flag OK"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

                                                             -- ask for position
    --testInfo <= pad("Ask for position", testInfo'length);
    write(output,
      "Asking for position" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    readReg(actualAngleRDAddr);
    stepperSendAuth <= '0';
    wait until stepperSendRequest = '1';
    dutPosition <= natural(to_integer(unsigned(stepperDataToSend)));
    stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
    assert dutPosition /= angleMaxValue/2
      report "Position readback error"
      severity error;
    assert dutPosition = angleMaxValue/2
      report "Position readback OK"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

                                                              -- send half angle
    testInfo <= pad("Turn 1/2", testInfo'length);
    write(output,
      "Sending turn control to half angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue);
    case lastCoilOn is
      when 1 =>
        wait until rising_edge(coil1) for 1 ms;
        if coil1 = '0' then
          write(output,
            "Error : Coil problem detected - coil1 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 2 =>
        wait until rising_edge(coil2) for 1 ms;
        if coil2 = '0' then
          write(output,
            "Error : Coil problem detected - coil2 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 3 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 4 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when others =>
        write(output,
            "Error : Coil problem detected - no coil rose since beginning -" &
            " continuing simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
    end case;
    stepperEnd <= '0';
    wait for angleMaxValue/3 * stpPeriod;
    wait for testInterval/2;

                                                              -- send zero angle
    testInfo <= pad("Turn back", testInfo'length);
    write(output,
      "Sending turn control to angle zero" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, 0);
    wait for 4*testInterval;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    -- Wait for position zero
    write(output,
      "Waiting for actual to be zero" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    time1 := now;
    loop
      readReg(actualAngleRDAddr);
      stepperSendAuth <= '0';
      wait until stepperSendRequest = '1';
      dutPosition <= natural(to_integer(unsigned(stepperDataToSend)));
      stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
      wait for 2*clockPeriod;
      time2 := now;
      exit when (dutPosition = 0 or time2-time1 > 90 ms);
    end loop;

    if dutPosition /= 0 then
      write(output,
        "Error : Stopped waiting for actual to be 0" &
        " at time " & integer'image(now/1 us) & " us" &
        lf & lf
      );
    end if;
    stepperEnd <= '1';
    wait for 20*testInterval;


                                                              -- send half angle
    testInfo <= pad("Turn 1/2", testInfo'length);
    write(output,
      "Sending turn control to half angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/2);
    case lastCoilOn is
      when 1 =>
        wait until rising_edge(coil1) for 1 ms;
        if coil1 = '0' then
          write(output,
            "Error : Coil problem detected - coil1 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 2 =>
        wait until rising_edge(coil2) for 1 ms;
        if coil2 = '0' then
          write(output,
            "Error : Coil problem detected - coil2 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 3 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 4 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when others =>
        write(output,
            "Error : Coil problem detected - no coil rose since beginning -" &
            " continuing simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
    end case;
    stepperEnd <= '0';
    wait for 5 ms;
    wait for angleMaxValue/2 * stpPeriod * 0.3;


    -- HW Orientation changed
                                                  -- change hardware orientation
    testInfo <= pad("Restart on - changed hwOrientation", testInfo'length);
    write(output,
      "Setting restart bit high with a different HWOrientation " &
      "- motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= 2#011# + 16#10#;
    wait for 4*testInterval;
    assert turn1to4 /= turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    wait for 10*testInterval;

                                                                   -- Angle to 0
    write(output,
      "Setting angle to 0" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, 0);
    wait for 5*testInterval;

                                                         -- deassert restart bit
    testInfo <= pad("Restart off - changed hwOrientation", testInfo'length);
    write(output,
      "Setting restart bit low - motor should continue to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= 2#011#;
    wait for 20*testInterval;

                                                           -- actuate end switch
    testInfo <= pad("End switch local - changed hwOrientation", testInfo'length);
    wait until falling_edge(coil4) for 1 ms;
    write(output,
      "Actuating end of turn switch" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    stepperEnd <= '1';
    wait for 6*testInterval;

                                                           -- send quarter angle
    testInfo <= pad("Turn 1/4 - changed hwOrientation", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    case lastCoilOn is
      when 1 =>
        wait until rising_edge(coil1) for 1 ms;
        if coil1 = '0' then
          write(output,
            "Error : Coil problem detected - coil1 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 2 =>
        wait until rising_edge(coil2) for 1 ms;
        if coil2 = '0' then
          write(output,
            "Error : Coil problem detected - coil2 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 3 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 4 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when others =>
        write(output,
            "Error : Coil problem detected - no coil rose since beginning -" &
            " continuing simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
    end case;
    stepperEnd <= '0';
    wait for testInterval;

                                                              -- ask for status 
                    -- wait for less than quarter angle delay and ask for status
    wait for angleMaxValue/4 * stpPeriod / 4;
    --testInfo <= pad("Ask for status", testInfo'length);
    write(output,
      "Asking for status" &
      " at time " & integer'image(now/1 us) & " us" &
      lf &
      "  Reached should be 0" &
      lf & lf
    );
    readReg(hwRDAddr);
    stepperSendAuth <= '0';
    wait until stepperSendRequest = '1';
    dutReached <= stepperDataToSend(1);
    stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
    assert dutReached /= '0'
      report "Reached flag error"
      severity error;
    assert dutReached = '0'
      report "Reached flag OK"
      severity note;
    assert turn1to4 = not turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report"Coil direction OK"
      severity note;
    write(output, "" & lf);

                                      -- wait for end of turn and ask for status
    --testInfo <= pad("Turn 1/4", testInfo'length);
    wait for angleMaxValue/4 * stpPeriod;
    --testInfo <= pad("Ask for status", testInfo'length);
    write(output,
      "Asking for status" &
      " at time " & integer'image(now/1 us) & " us" &
      lf &
      "    Reached should be 1" &
      lf & lf
    );
    readReg(hwRDAddr);
    stepperSendAuth <= '0';
    wait until stepperSendRequest = '1';
    dutReached <= stepperDataToSend(1);
    stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
    assert dutReached /= '1'
      report "Reached flag error"
      severity error;
    assert dutReached = '1'
      report "Reached flag OK"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

                                                             -- ask for position
    --testInfo <= pad("Ask for position", testInfo'length);
    write(output,
      "Asking for position" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    readReg(actualAngleRDAddr);
    stepperSendAuth <= '0';
    wait until stepperSendRequest = '1';
    dutPosition <= natural(to_integer(unsigned(stepperDataToSend)));
    stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
    assert dutPosition /= angleMaxValue/2
      report "Position readback error"
      severity error;
    assert dutPosition = angleMaxValue/2
      report "Position readback OK"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

                                                              -- send zero angle
    testInfo <= pad("Turn back - changed hwOrientation", testInfo'length);
    write(output,
      "Sending turn control to angle zero" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, 0);
    wait for 4*testInterval;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    -- Wait for position zero
    write(output,
      "Waiting for actual to be zero" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    time1 := now;
    loop
      readReg(actualAngleRDAddr);
      stepperSendAuth <= '0';
      wait until stepperSendRequest = '1';
      dutPosition <= natural(to_integer(unsigned(stepperDataToSend)));
      stepperSendAuth <= '1', '0' after 1.1 * clockPeriod, '1' after 2 * clockPeriod;
      wait for 2*clockPeriod;
      time2 := now;
      exit when (dutPosition = 0 or time2-time1 > 90 ms);
    end loop;

    if dutPosition /= 0 then
      write(output,
        "Error : Stopped waiting for actual to be 0" &
        " at time " & integer'image(now/1 us) & " us" &
        lf & lf
      );
    end if;
    stepperEnd <= '1';
    wait for 20*testInterval;

    testInfo <= pad("Turn 1/2", testInfo'length);
    write(output,
      "Sending turn control to half angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/2);
    case lastCoilOn is
      when 1 =>
        wait until rising_edge(coil1) for 1 ms;
        if coil1 = '0' then
          write(output,
            "Error : Coil problem detected - coil1 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 2 =>
        wait until rising_edge(coil2) for 1 ms;
        if coil2 = '0' then
          write(output,
            "Error : Coil problem detected - coil2 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 3 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when 4 =>
        wait until rising_edge(coil3) for 1 ms;
        if coil3 = '0' then
          write(output,
            "Error : Coil problem detected - coil3 did not rise on time - continuing" &
            "simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
        end if;
      when others =>
        write(output,
            "Error : Coil problem detected - no coil rose since beginning -" &
            " continuing simulation anyway" &
            " at time " & integer'image(now/1 us) & " us" &
            lf & lf
          );
    end case;
    stepperEnd <= '0';
    wait for 10 ms;


    -- Restart with emulated endSW

                                                                -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= 16#10# + hardwareOrientation;
    wait for testInterval/10;
    wait for 5*testInterval;
    write(output, "" & lf);
    wait for testInterval;

                                                                   -- Angle to 0
    write(output,
      "Setting angle to 0" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, 0);
    wait for 5*testInterval;

                                                              -- Release restart
    testInfo <= pad("Restart off", testInfo'length);
    write(output,
      "Setting restart bit low - motor should continue to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= hardwareOrientation - 16#10#;
    wait for 8*testInterval;

                                                 -- assert end contact HWControl
    testInfo <= pad("Emulated end switch ON", testInfo'length);
    write(output,
      "Emulating end switch to ON" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= 16#08# + hardwareOrientation;
    wait for 20*testInterval;
                                             -- deassert end contact from master
    write(output,
      "Emulating end switch to OFF" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= hardwareOrientation - 16#08#;
    wait for testInterval;

                                                            -- end of simulation
    testInfo <= pad("End of simulation", testInfo'length);
    wait for 10*testInterval;
    assert false
      report "End of simulation"
      severity failure;
    wait;
  end process;

  ------------------------------------------------------------------------------
                                                                -- coil analysis
  coils <= (coil1, coil2, coil3, coil4, coil1);

  findDir: process(coils)
    variable onTime_var: integer;
  begin
    if coil1 = '1' then
      lastCoilOn <= 1;
    elsif coil2 = '1' then
      lastCoilOn <= 2;
    elsif coil3 = '1' then
      lastCoilOn <= 3;
    elsif coil4 = '1' then
      lastCoilOn <= 4;
    end if;


    turn1to4 <= '0';
    for index in 2 to coils'right loop
      if coils(index) = '1' then
        if prevCoils(index-1) = '1' then
          turn1to4 <= '1';
        end if;
      end if;
    end loop;
    prevCoils <= coils after 1 ns;
    if unsigned(prevCoils) /= 0 then
      onTime_var := integer( (now - lastEvent) / clockPeriod);
      onTime <= onTime_var;
      if unsigned(coils) /= 0 then
        assert onTime_var <= stpPeriod / clockPeriod
          report "Coil on for too long"
          severity error;
      end if;
    end if;
    lastEvent <= now;
  end process findDir;

  turnBack <= '1' when (hardwareOrientation/2 = 1) or (hardwareOrientation/2 = 2)
    else '0';

END ARCHITECTURE test;
