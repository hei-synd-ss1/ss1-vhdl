LIBRARY std;
  USE std.textio.ALL;

LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;

LIBRARY Common_test;
  USE Common_test.testutils.all;

Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE test OF dcMotorController_tester IS

  constant clockPeriod  : time := 1.0/CLOCK_FREQUENCY * 1 sec;
  signal sClock         : std_uLogic := '1';
  signal sReset         : std_uLogic ;

  constant testInterval : time := 1 ms;
  signal testInfo       : string(1 to 40) := (others => ' ');

  signal hardwareOrientation : natural;

  -- Control values
  constant restart: natural := 16#10#;
  constant btConnected_bit: natural := 16#20#;
  signal absSpeed: integer;
  constant pwmDivideValue: positive := 10;
  constant pwmPeriod : time :=
    (2.0**(DC_pwmStepsBitNb-1) * real(pwmDivideValue) * sec) / CLOCK_FREQUENCY;
  constant speedMaxValue: positive := 2**(DC_pwmStepsBitNb-1) - 1;
                                                               
  -- PWM mean value
  constant pwmLowpassShift: positive := 8;
  signal pwmLowpassAccumulator, motorSpeed: real := 0.0;
  signal motorSpeed_int: integer := 0;

  -- Registers definitions
  constant baseReadAddr : natural := REG_DCMOT_ADDR * 2**6;
  constant baseWriteAddr : natural := baseReadAddr + 1 * 2**5;

  constant prescalerWRAddr : natural :=
    baseWriteAddr + DC_PRESCALER_REG_POS;
  constant speedWRAddr : natural :=
    baseWriteAddr + DC_SPEED_REG_POS;

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
                     data    : in integer) is
    begin
      assert(
        to_unsigned(address, addressIn'length)(REG_ADDR_GET_BIT_POSITION)
        = '1') report "Address is not writable" severity failure;
      addressIn <= symbolSizeType(to_unsigned(address, addressIn'length));
      dataIn <= dataRegisterType(to_signed(data, dataIn'length));
      regWr <= '1', '0' after clockPeriod * 1.1;
    end procedure;

  begin
    -- Init signals
    hardwareOrientation <= 0;
    dataIn <= (others=>'0');
    addressIn <= (others=>'0');
    regWr <= '0';
    dcMotorSendAuth <= '1';
    absSpeed <= 65535;
    btConnected <= '0';

    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );
                                                             -- send hardwareOrientation
    testInfo <= pad("Init", testInfo'length);
    write(output,
      "Setting hardware hardwareOrientation" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= btConnected_bit + 2#111#;
    btConnected <= '1';
    wait for testInterval;

                                                               -- send prescaler
    testInfo <= pad("Sending prescaler", testInfo'length);
    write(output,
      "Sending prescaler value" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(prescalerWRAddr, pwmDivideValue);
    wait for testInterval;

                                                               -- send 1/3 speed
    testInfo <= pad("speed 1/3", testInfo'length);
    write(output,
      "Sending speed control to 1/3 max value forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue / 3;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '1'
      report "Direction error"
      severity error;
    assert forwards /= '1'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int-absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                               -- send 2/3 speed
    testInfo <= pad("speed 2/3", testInfo'length);
    write(output,
      "Sending speed control to 2/3 max value forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue * 2/3;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '1'
      report "Direction error"
      severity error;
    assert forwards /= '1'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int-absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                              -- send full speed
    testInfo <= pad("full speed", testInfo'length);
    write(output,
      "Sending speed control to max value forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '1'
      report "Direction error"
      severity error;
    assert forwards /= '1'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int-absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                     -- send 1/3 speed backwards
    testInfo <= pad("speed 1/3 back", testInfo'length);
    write(output,
      "Sending speed control to 1/3 max value backwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue / 3;
    wait for clockPeriod;
    setReg(speedWRAddr, -absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '0'
      report "Direction error"
      severity error;
    assert forwards /= '0'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int+absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int+absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                     -- send 2/3 speed backwards
    testInfo <= pad("speed 2/3 back", testInfo'length);
    write(output,
      "Sending speed control to 2/3 max value backwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue * 2/3;
    wait for clockPeriod;
    setReg(speedWRAddr, -absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '0'
      report "Direction error"
      severity error;
    assert forwards /= '0'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int+absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int+absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                    -- send full speed backwards
    testInfo <= pad("full speed back", testInfo'length);
    write(output,
      "Sending speed control to max value backwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue;
    wait for clockPeriod;
    setReg(speedWRAddr, -absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '0'
      report "Direction error"
      severity error;
    assert forwards /= '0'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int+absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int+absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                   -- change hardwareOrientation
    testInfo <= pad("hardwareOrientation", testInfo'length);
    write(output,
      "Changing hardware hardwareOrientation" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= btConnected_bit + 2#110#;
    wait for testInterval;

                                                              -- send half speed
    testInfo <= pad("half speed", testInfo'length);
    write(output,
      "Sending speed control to half max value forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= (speedMaxValue+1) / 2;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '0'
      report "Direction error"
      severity error;
    assert forwards /= '0'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int-absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                              -- send full speed
    testInfo <= pad("full speed", testInfo'length);
    write(output,
      "Sending speed control to max value forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '0'
      report "Direction error"
      severity error;
    assert forwards /= '0'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int-absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                    -- send half speed backwards
    testInfo <= pad("half speed back", testInfo'length);
    write(output,
      "Sending speed control to half max value backwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= (speedMaxValue+1) / 2;
    wait for clockPeriod;
    setReg(speedWRAddr, -absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '1'
      report "Direction error"
      severity error;
    assert forwards /= '1'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int+absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int+absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                    -- send full speed backwards
    testInfo <= pad("full speed back", testInfo'length);
    write(output,
      "Sending speed control to max value backwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= speedMaxValue;
    wait for clockPeriod;
    setReg(speedWRAddr, -absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '1'
      report "Direction error"
      severity error;
    assert forwards /= '1'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int+absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int+absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                                 -- send speed 2
    testInfo <= pad("speed 2", testInfo'length);
    write(output,
      "Sending speed control to 2 forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= 2;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert motorSpeed_int > 0
      report "PWM error"
      severity error;
    assert motorSpeed_int <= 0
      report "PWM Ok"
      severity note;
    wait for testInterval;

                                                                 -- send restart
    testInfo <= pad("restart", testInfo'length);
    write(output,
      "Sending restart control" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= restart + btConnected_bit + 2#111#;
    wait for 10*pwmPeriod;
    assert motorSpeed_int = 0
      report "PWM error"
      severity error;
    assert motorSpeed_int /= 0
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                                 -- stop restart
    write(output,
      "Stopping restart control" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= btConnected_bit + 2#111#;
    wait for 10*pwmPeriod;
    assert motorSpeed_int > 0
      report "PWM error"
      severity error;
    assert motorSpeed_int <= 0
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                          -- loose BT connection
    testInfo <= pad("loose BT connection", testInfo'length);
    write(output,
      "Loosing BT connection" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= 2#111#;
    btConnected <= '0';
    wait for 10*pwmPeriod;
    assert motorSpeed_int = 0
      report "PWM error"
      severity error;
    assert motorSpeed_int /= 0
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                      -- retrieve BT connection
    testInfo <= pad("Retrieve BT connection", testInfo'length);
    write(output,
      "Retrieving BT connection" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= btConnected_bit + 2#111#;
    btConnected <= '1';
    wait for 10*pwmPeriod;
    assert motorSpeed_int = 0
      report "PWM error"
      severity error;
    assert motorSpeed_int /= 0
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                              -- send 0
    testInfo <= pad("Stopped", testInfo'length);
    write(output,
      "Sending speed control to 0" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= 0;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert abs(motorSpeed_int-absSpeed) <= 0
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 0
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                              -- send half speed
    testInfo <= pad("half speed", testInfo'length);
    write(output,
      "Sending speed control to half max value forwards" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    absSpeed <= (speedMaxValue+1) / 2;
    wait for clockPeriod;
    setReg(speedWRAddr, absSpeed);
    wait for 10*pwmPeriod;
    assert forwards = '1'
      report "Direction error"
      severity error;
    assert forwards /= '1'
      report "Direction OK"
      severity note;
    assert abs(motorSpeed_int-absSpeed) <= 2
      report "PWM error"
      severity error;
    assert abs(motorSpeed_int-absSpeed) > 2
      report "PWM OK"
      severity note;
    wait for testInterval;

                                                            -- end of simulation
    assert false
      report "End of simulation"
      severity failure;
    wait;
  end process;

  --============================================================================
                                                                  -- PWM lowpass
  lowpassIntegrator: process
  begin
    wait until rising_edge(clock);
    if pwm = '1' then
      if (forwards xor to_unsigned(hardwareOrientation, hwOrientation'length)(0))
           = '0' then
        pwmLowpassAccumulator <= pwmLowpassAccumulator - motorSpeed + 1.0;
      else
        pwmLowpassAccumulator <= pwmLowpassAccumulator - motorSpeed - 1.0;
      end if;
    else
      pwmLowpassAccumulator <= pwmLowpassAccumulator - motorSpeed;
    end if;
  end process lowpassIntegrator;

  motorSpeed <= pwmLowpassAccumulator / 2.0**pwmLowpassShift;
  motorSpeed_int <= integer(real(speedMaxValue) * motorSpeed);

END ARCHITECTURE test;
