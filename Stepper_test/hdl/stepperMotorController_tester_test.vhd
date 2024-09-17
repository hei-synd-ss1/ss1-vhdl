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
  signal lastCoilOn, lastCoilOnReset : natural;
  signal lastEvent: time;
  signal onTime: integer;

  -- Steering values
    -- f of 100kHz / divideValue, here 10kHz
  constant stepDivideValue: positive := 10;
  constant angleMaxValue: positive := 1E3;

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

  constant HC_FORWARDS : positive := 2#01#;
  constant HC_CLOCKWISE : positive := 2#10#;
  constant HC_SENSOR_LEFT : positive := 2#100#;
  constant HC_STEPPER_END_EMULATION : positive := 2#1000#;
  constant HC_RESTART : positive := 2#10000#;
  signal hardwareOrientation: natural;
  signal lvec_hwOrientationUnsigned : unsigned(hwOrientation'range);

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  sReset <= '1', '0' after 4*clockPeriod;
  reset <= sReset;

  sClock <= not sClock after clockPeriod/2;
  clock <= transport sClock after 0.9*clockPeriod;

  ------------------------------------------------------------------------------
                                                                       -- others
  lvec_hwOrientationUnsigned <= to_unsigned(hardwareOrientation, hwOrientation'length);
  hwOrientation <= dataRegisterType(lvec_hwOrientationUnsigned);

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
    hardwareOrientation <= HC_FORWARDS;
    dataIn <= (others=>'0');
    addressIn <= (others=>'0');
    regWr <= '0';
    stepperSendAuth <= '1';
    dutReached <= '1';
    dutPosition <= 0;
    lastCoilOnReset <= lastCoilOn;

    wait for 1 ns;
    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );

    -- Send prescaler
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending step divider value " & sprintf("%d", stepDivideValue) &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(prescalerWRAddr, stepDivideValue);
    wait for testInterval;

    -- Does nothing
    testInfo <= pad("Waiting", testInfo'length);
    wait for testInterval;
    write(output,
    "Waiting a bit - should not move" &
    " at time " & integer'image(now/1 us) & " us" &
    lf & lf
    );
    wait for testInterval/2;
    if lastCoilOn /= 0 then
      write(output,
        "Error : Coil problem detected - no coil should have risen - continuing" &
        "simulation anyway" &
        " at time " & integer'image(now/1 us) & " us" &
        lf & lf
      );
    else 
      write(output,
        "** Note: No coil has moved - OK" &
        " at time " & integer'image(now/1 us) & " us" &
        lf & lf
      );
    end if;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is too high"
      severity error;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power is reduced correctly"
      severity note;
    write(output, "" & lf);
    wait for testInterval/2;

    -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_RESTART + HC_FORWARDS;
    wait for testInterval/10;
    wait for 5*testInterval;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

    -- actuate end switch and thus restart stops
    testInfo <= pad("End switch", testInfo'length);
    wait for 3*testInterval;
    write(output,
      "Actuating end of turn switch" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    stepperEnd <= '1';
    wait for clockPeriod;
    hardwareOrientation <= HC_FORWARDS;
    wait for 6*testInterval;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is too high"
      severity error;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power is reduced correctly"
      severity note;
    write(output, "" & lf);
    
    -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    wait for 500 us;
    assert turn1to4 /= turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    stepperEnd <= '0';
    wait for 500 us;

    testInfo <= pad("Switching clockwise", testInfo'length);
    write(output,
      "Setting CLOCKWISE bit - coils should change direction" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_CLOCKWISE + HC_FORWARDS;
    wait for 500 us;
    assert turn1to4 /= turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for 500 us;

    -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_RESTART + HC_CLOCKWISE + HC_FORWARDS;
    wait for testInterval/10;
    wait for 5*testInterval;
    assert turn1to4 /= turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

    -- actuate end switch and thus restart stops
    testInfo <= pad("End switch", testInfo'length);
    wait for 3*testInterval;
    write(output,
      "Actuating end of turn switch" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    stepperEnd <= '1';
    wait for clockPeriod;
    hardwareOrientation <= HC_CLOCKWISE + HC_FORWARDS;
    wait for testInterval/2;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);

    -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    stepperEnd <= '0';
    wait for 500 us;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for 500 us;

    -- Reset for sensorLeft test
    testInfo <= pad("Reset for half", testInfo'length);
    write(output,
      "Resetting system for sensorLeft tests" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_RESTART + HC_FORWARDS;
    setReg(targetAngleWRAddr, 0);
    wait for 1 ms;
    stepperEnd <= '1';
    wait for clockPeriod;
    hardwareOrientation <= HC_FORWARDS;
    testInfo <= pad("HALF OF THE TESTS", testInfo'length);
    write(output, "" & lf & lf & lf & lf & lf & lf);
    lastCoilOnReset <= lastCoilOn;
    wait for 5 ms;







    -- Does nothing
    testInfo <= pad("Waiting", testInfo'length);
    wait for testInterval;
    write(output,
    "Waiting a bit - should not move" &
    " at time " & integer'image(now/1 us) & " us" &
    lf & lf
    );
    hardwareOrientation <= HC_SENSOR_LEFT + HC_FORWARDS;
    wait for testInterval/2;
    if lastCoilOn /= lastCoilOnReset then
      write(output,
        "Error : Coil problem detected - coils have changed when should be idle - continuing" &
        "simulation anyway" &
        " at time " & integer'image(now/1 us) & " us" &
        lf & lf
      );
    else 
      write(output,
        "** Note: No coil has moved - OK" &
        " at time " & integer'image(now/1 us) & " us" &
        lf & lf
      );
    end if;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is too high"
      severity error;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power is reduced correctly"
      severity note;
    write(output, "" & lf);
    wait for testInterval/2;

    -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_SENSOR_LEFT + HC_RESTART + HC_FORWARDS;
    wait for testInterval/10;
    wait for 5*testInterval;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

    -- actuate end switch and thus restart stops
    testInfo <= pad("End switch", testInfo'length);
    wait for 3*testInterval;
    write(output,
      "Actuating end of turn switch" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    stepperEnd <= '1';
    wait for clockPeriod;
    hardwareOrientation <= HC_SENSOR_LEFT + HC_FORWARDS;
    wait for 6*testInterval;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is too high"
      severity error;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power is reduced correctly"
      severity note;
    write(output, "" & lf);
    
    -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    wait for 500 us;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    stepperEnd <= '0';
    wait for 500 us;
    
    testInfo <= pad("Switching clockwise", testInfo'length);
    write(output,
      "Setting CLOCKWISE bit - coils should change direction" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_SENSOR_LEFT + HC_CLOCKWISE + HC_FORWARDS;
    wait for 500 us;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for 500 us;

    -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_SENSOR_LEFT + HC_RESTART + HC_CLOCKWISE + HC_FORWARDS;
    wait for testInterval/10;
    wait for 5*testInterval;
    assert turn1to4 /= turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for testInterval;

    -- actuate end switch and thus restart stops
    testInfo <= pad("End switch", testInfo'length);
    wait for 3*testInterval;
    write(output,
      "Actuating end of turn switch" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    stepperEnd <= '1';
    wait for clockPeriod;
    hardwareOrientation <= HC_SENSOR_LEFT + HC_CLOCKWISE + HC_FORWARDS;
    wait for testInterval/2;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);

    -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    stepperEnd <= '0';
    wait for 500 us;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for 500 us;

    -- Reset for sensorLeft test
    testInfo <= pad("Reset", testInfo'length);
    write(output,
      "Resetting tests" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_RESTART + HC_FORWARDS;
    setReg(targetAngleWRAddr, 0);
    wait for 1 ms;
    stepperEnd <= '1';
    wait for clockPeriod;
    hardwareOrientation <= HC_FORWARDS;
    wait for 2 ms;





    -- Let run to 1/8 and back a bit
    testInfo <= pad("Turn 20", testInfo'length);
    write(output,
      "Sending turn control to 20" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, 20);
    wait for 500 us;
    assert turn1to4 /= turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 = turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for 2 ms;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is too high"
      severity error;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power is reduced correctly"
      severity note;
    write(output, "" & lf);
    wait for 1 ms;

    testInfo <= pad("Turn 10", testInfo'length);
    write(output,
      "Sending turn control to 10" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, 10);
    wait for 500 us;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    assert magnetizing_power >= "1000"
      report "Coil magnetization power may be too low"
      severity error;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is increased correctly"
      severity note;
    write(output, "" & lf);
    wait for 2 ms;
    assert magnetizing_power < "1000"
      report "Coil magnetization power is too high"
      severity error;
    assert magnetizing_power >= "1000"
      report "Coil magnetization power is reduced correctly"
      severity note;
    write(output, "" & lf);
    wait for 1 ms;



    -- end of simulation
    write(output, "" & lf & lf & lf & lf & lf & lf);
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
    else
      lastCoilOn <= 0;
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
      -- if unsigned(coils) /= 0 then
      --   assert onTime_var <= stpPeriod / clockPeriod
      --     report "Coil on for too long"
      --     severity error;
      -- end if;
    end if;
    lastEvent <= now;
  end process findDir;

  --turnBack <= '1' when (hardwareOrientation/2 = 1) or (hardwareOrientation/2 = 2)
  --  else '0';

  turnBack <= '1' when (lvec_hwOrientationUnsigned(1) xor lvec_hwOrientationUnsigned(2)) = '1'
    else '0';

END ARCHITECTURE test;
