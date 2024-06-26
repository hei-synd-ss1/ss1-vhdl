LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Kart_Student IS

--------------------------------------------------------------------------------
-- CHANGE THEM AS NEEDED, YOU CAN
--------------------------------------------------------------------------------
  -- When the circuit is in test mode
    --  (Stepper -> stepperMotorController -> testMode = '1'), the counter can count
    --  more or less fast to analyze the signals.
    -- The following defines how many bits the counter should use.
    -- It simply creates a counter with that number of bits generating a pulse
    -- when it overflows, i.e. a pulse each 2**n / 10MHz => n = 8 : 25.6 [us]
  constant TESTMODE_PRESCALER_BIT_NB : positive := 8;

    -- If the hallCounters block generates 2 pulses per turn (on rising AND 
    --  falling edges of the hallPulses, = '1') or only on rising edge (= '0')
  constant HALLSENS_2PULSES_PER_TURN : std_ulogic := '1';

    -- The number of hall sensors used (1 or 2)
  constant STD_HALL_NUMBER : positive := 1;

    -- The number of inputs (a.k.a end switches in the program) wired (max 16)
  constant STD_ENDSW_NUMBER : positive := 4;
  
  -- The number of outputs (a.k.a leds in the program) wired (max 8)
  constant STD_LEDS_NUMBER : positive := 8;
  
  -- The number of servo outputs (a.k.a servos in the program) wired (max 8)
  constant STD_SERVOS_NUMBER : positive := 8;

END Kart_Student;
