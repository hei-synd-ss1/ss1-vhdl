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
  constant STD_ENDSW_NUMBER : natural := 4;
  
  -- Wired outputs
    -- LEDs and SERVOs have shared registers, so the total of LEDS + SERVOS must be less or equal to 8
  constant STD_LEDS_NUMBER : natural := 4;
  constant STD_SERVOS_NUMBER : natural := 4;

  -- To easily change user-specific outputs from custom blocks, modify this
  constant STD_USER_OUTPUTS_NUMBER : natural := 2;

END Kart_Student;




--
-- VHDL Package Body Kart.Kart_Student
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:03:49 23.06.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--
PACKAGE BODY Kart_Student IS
END Kart_Student;




--
-- VHDL Package Header Kart.Kart
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 11:30:31 11.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

--------------------------------------------------------------------------------
-- YOUUUUUUUUU SHALL NOTTTTTTT TOUCH
--------------------------------------------------------------------------------

-- "Interesting" values to modify are highlighted as
  --|||||||||||||||
  --|||||||||||||||
    -- Interesting Value Description
  -- Value definition;
  --|||||||||||||||
  --|||||||||||||||

LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;

Library Kart;
  Use Kart.Kart_Student.all;

PACKAGE Kart IS

-- Redefine student constants to make them available through this package
  constant TESTMODE_PRESCALER_BIT_NB : positive := TESTMODE_PRESCALER_BIT_NB;
  constant HALLSENS_2PULSES_PER_TURN : std_ulogic := HALLSENS_2PULSES_PER_TURN;
  constant STD_HALL_NUMBER : positive := STD_HALL_NUMBER;
  function check_hall_count return std_ulogic;
  constant STD_ENDSW_NUMBER : natural := STD_ENDSW_NUMBER;
  function check_endsw_count return std_ulogic;
  constant STD_LEDS_NUMBER : natural := STD_LEDS_NUMBER;
  constant STD_SERVOS_NUMBER: natural := STD_SERVOS_NUMBER;
  function check_outputs_count return std_ulogic;
  constant STD_USER_OUTPUTS_NUMBER : natural := STD_USER_OUTPUTS_NUMBER;

-- Sensors
    -- If changed, the memory layout would change -> need a new smartphone and PC app
    -- The maximal number of outputs registers
  constant NUMBER_OF_OUTPUTS : positive := 8;
    -- Since servos share the leds registers, they share the same var

    -- The number of user-registers
  constant NUMBER_OF_USER_REGISTERS : positive := 8;

    -- The (maximum) number of hall sensors
  constant NUMBER_OF_HALL_SENSORS : positive := 2;

    -- The number of external end switches (or any 0 - 3.3V input signal)
    -- A signal is sent to the smartphone on either rising or falling edge
  constant NUMBER_OF_EXT_END_SWITCHES : positive := 16;
      -- If has to inhibit buttons events
  constant INHIBIT_ENDSW_SEND : std_ulogic := '0';
      -- If has to inhibit the current events
  constant SENS_CURR_INHIBIT_SEND : std_ulogic := '0';
      -- Can choose to select the connected bit from the "old" HardwareControl
      --  or from the new dedicated register
  constant USE_BT_CONNECTED_FROM_NEWREG : std_ulogic := '1';
      -- Define if the write bit on event is a 1 or, as for a read, is a 0
  constant WBIT_VALUE_ON_EVENT : std_ulogic := '0';

  -- Clocks	
  constant CLOCK_FREQUENCY  : real := 10.0E6;
  constant CLOCK_PERIOD 	: real := 1.0 / CLOCK_FREQUENCY;
  -- Sub clocks dividers (for counter based frequency dividers)
  constant CLOCK_1US_DIVIDER : positive := positive(CLOCK_FREQUENCY / 1.0E6);
  constant CLOCK_250US_DIVIDER : positive := 250*CLOCK_1US_DIVIDER;
  constant CLOCK_1MS_DIVIDER : positive := positive(CLOCK_FREQUENCY / 1.0E3);
  constant CLOCK_1S_DIVIDER : positive := positive(CLOCK_FREQUENCY / 1.0);

  --------------------------------------------

  -- UART

    -- Number of bits of data for each symbol
  constant UART_BIT_NB : positive  := 8;
    -- Number of bits to receive or send one symbol (i.e. data + start + stop)
  constant UART_TXRX_BIT_NB : positive  := UART_BIT_NB + 1 + 1;
  --|||||||||||||||
  --|||||||||||||||
    -- Baud rate
  constant UART_BAUD_RATE : positive  := 115200;
  --|||||||||||||||
  --|||||||||||||||
      -- Baud rate divider
  constant UART_BAUD_RATE_DIVIDER : positive :=
    positive(real(CLOCK_FREQUENCY) / real(UART_BAUD_RATE));

  -- CRC
    -- Size of bits sent before actual data
  constant HEADER_BIT_NB  : positive  := 8; -- 0xAA
    -- Address size
  constant ADDRESS_BIT_NB : positive  := 8;
    -- Value size
  constant VALUE_BIT_NB   : positive  := 16;
    -- CRC size
  constant CRC_BIT_NB     : positive  := 8;
    -- CRC-8/itu final xoring
  constant CRC_FINAL_XOR     : std_ulogic_vector(CRC_BIT_NB-1 downto 0)  := 
    std_ulogic_vector(to_unsigned(16#55#, CRC_BIT_NB));

  -- Frame (composed of 5 bytes as 0xAA | addr | data_high | data_low | crc)
    -- Header byte sent at the beginning of the frame
  constant FRAME_HEADER_BYTE : natural  := 16#AA#;
    -- Total frame size in bits
  constant FRAME_BIT_NB : positive := HEADER_BIT_NB + ADDRESS_BIT_NB 
      + VALUE_BIT_NB + CRC_BIT_NB;
    -- Total frame size in bytes
  constant FRAME_BYTES_NB : real := real(FRAME_BIT_NB) / real(UART_BIT_NB);
    -- Symbols per frame
  constant NB_SYMBOL_P_FRAME : natural := natural(FRAME_BIT_NB / UART_BIT_NB);

  -- Tx buffer
  --|||||||||||||||
  --|||||||||||||||
    -- Depth of the Tx buffer
    -- MUST BE POWER OF 2, else will SIGSEV !!!
  constant TX_BUFFER_WANTED_DEPTH : positive := 64;
  --|||||||||||||||
  --|||||||||||||||
    -- Will be calculated
  function check_pow_2(size : positive) return positive;
  constant TX_BUFFER_SIZE : positive;


  --------------------------------------------

  -- Data definition

    -- Size of a symbol (i.e. a byte)
  subtype symbolSizeType is std_ulogic_vector(UART_BIT_NB-1 downto 0);
    -- Size of the frame
  type frameSizeType is array(NB_SYMBOL_P_FRAME-1 downto 0)
    of symbolSizeType;
    -- Array of register
  subtype dataRegisterType is std_ulogic_vector(VALUE_BIT_NB-1 downto 0);
  type dataRegisterArrayType is array(ADDRESS_BIT_NB-1 downto 0) 
      of dataRegisterType;
      -- Unconstrained array, defined on instanciation
  type registersHolderType is array(integer range <>)
      of dataRegisterType;


  -- How registers and address are decoded
    -- Address byte definition :
      -- b 7 .. 6 : module address
      -- b 5      : write to (FRAME_WBIT_VALUE) - read from (!FRAME_WBIT_VALUE)
      -- b 4 .. 0 : which register

    -- How many bits (MSB side) will define the module
  constant REG_ADDR_MSB_NB_BITS : positive := 2;
    -- Where the write/read bit is located
  constant REG_ADDR_GET_BIT_POSITION : positive
    := UART_BIT_NB - REG_ADDR_MSB_NB_BITS - 1;
    -- How many bits to define actual register per module (2**n)
  constant REG_ADDR_MAXNBREG_BITS : positive
    := UART_BIT_NB - REG_ADDR_MSB_NB_BITS - 1;
    -- Where actual register is located in address byte
  subtype REG_ADDR_REG_RANGE is natural range REG_ADDR_MAXNBREG_BITS-1 downto 0;
    -- How many registers are possible per module
  subtype REG_COUNT_RANGE is integer range 0 to (2**REG_ADDR_MAXNBREG_BITS)-1;
  --|||||||||||||||
  --|||||||||||||||
    -- Value of the W bit when wanting to write into a register
  constant FRAME_WBIT_VALUE : std_ulogic := '1';
  --|||||||||||||||
  --|||||||||||||||


  -- I2C
    -- Data bits (8) + special coding for transceiver (2)
  constant I2C_BIT_NB : positive := 10;


  --------------------------------------------

  -- DC motor

  constant REG_DCMOT_ADDR : natural := 0;
    -- How many writable registers
  constant DC_REG_COUNT : positive := 2;
    -- Total count of register
  constant DC_TOT_REG_COUNT : positive := 2;

  -- Regs defs
  constant DC_PRESCALER_REG_POS : natural := 0;
  constant DC_SPEED_REG_POS : natural := 1;

  -- Others
  constant DC_prescalerBitNb : positive := 16;
  constant DC_speedBitNb : positive := 16;
  constant DC_pwmStepsBitNb : positive := 5; -- +- 15
    -- Each tick rate [ms], the DC speed can do +-1 to reach the requested speed
  constant DC_accelerationTickRateMS : positive := CLOCK_1MS_DIVIDER * 12;


  --------------------------------------------

  -- Stepper motor

  constant REG_STEP_ADDR : natural := 1;
    -- How many writable registers
  constant STP_REG_COUNT : positive := 2;
    -- Total count of register
  constant STP_TOT_REG_COUNT : positive := 4;

  -- Regs defs
  constant STP_CLOCKDIVIDER_REG_POS : natural := 0;
  constant STP_TARGETANGLE_REG_POS : natural := 1;
  constant STP_ANGLE_EXT_REG_POS : natural := 2;
  constant STP_HW_EXT_REG_POS : natural := 3;

  -- Event based definitions
  --|||||||||||||||
  --|||||||||||||||
    -- Motor def
  constant STP_STEPS_P_TURN : positive := 48;
  constant STP_REDUCTOR : real := 100.0;
    -- Motor has 4800 steps / 360° => 40 steps is 3° resol.
  constant STP_ANGLE_DELTA_DEG : positive := 2;
  --|||||||||||||||
  --|||||||||||||||
  constant STP_ANGLE_DELTA : integer :=
    integer(real(STP_ANGLE_DELTA_DEG mod 360) * (real(STP_STEPS_P_TURN) *
      STP_REDUCTOR) / 360.0);

  -- Others
  constant STP_testPrescalerBitNb : positive := TESTMODE_PRESCALER_BIT_NB;
  constant STP_dividerBitNb : positive := 16;
  constant STP_angleBitNb : positive := 12;
    -- The stepper base frequency which the prescaler is then applied to
  constant STP_MAX_FREQ : real := 100.0E3;
    -- Output coil PWM freq, too high input freqs will be wiped away
  constant STP_PWM_FREQ : real := 30.0E3;
    -- Output coil DC
  constant STP_PWM_DC : real := 0.65; --Should never be higher than 0.75 (12V * 0.75 = 9V, max voltage for stepper). A bit lower to avoid overheating.
    -- Output coil PWM cnt target
  constant STP_PWM_CNT_TARGET : positive :=
    positive(CLOCK_FREQUENCY / STP_PWM_FREQ);
    -- Output coil DC cnt target
  constant STP_PWM_CNT_ON : positive := positive(
    real(STP_PWM_CNT_TARGET) * STP_PWM_DC);


  --------------------------------------------

  -- Sensors

    -- Required for registers definition
  constant SENS_ledNb : positive := NUMBER_OF_OUTPUTS;
  constant SENS_userRegNb : positive := NUMBER_OF_USER_REGISTERS;
  constant SENS_hallSensorNb : positive := NUMBER_OF_HALL_SENSORS;
  constant SENS_endSwitchNb : positive := NUMBER_OF_EXT_END_SWITCHES;
  
  constant REG_SENS_ADDR : natural := 2;
    -- How many writable registers
  constant SENS_REG_COUNT : positive := SENS_ledNb + SENS_userRegNb;
    -- Total count of register
  constant SENS_TOT_REG_COUNT : positive :=
    SENS_REG_COUNT + SENS_hallSensorNb +  4;
      
  -- Regs defs
  constant SENS_LEDS_REG_POS : natural := 0; -- up to SENS_ledNb-1
  constant SENS_USER_REG_POS : natural := SENS_ledNb; -- up to SENS_ledNb+SENS_userRegNb-1
  constant SENS_BATTERY_EXT_REG_POS : natural := SENS_ledNb + SENS_userRegNb;
  constant SENS_CURRENT_EXT_REG_POS : natural := SENS_ledNb + SENS_userRegNb + 1;
  constant SENS_RANGEFNDR_EXT_REG_POS : natural := SENS_ledNb + SENS_userRegNb + 2;
  constant SENS_ENDSWITCHES_EXT_REG_POS : natural := SENS_ledNb + SENS_userRegNb + 3;
  constant SENS_HALLCNT_EXT_REG_POS : natural := SENS_ledNb + SENS_userRegNb + 4;
      -- up to SENS_ledNb + SENS_userRegNb + 4 + SENS_hallSensorNb - 1

  -- Event based definitions
  --|||||||||||||||
  --|||||||||||||||
      -- Voltage value is n * 250uV * 7.8 [V] => delta of 100mV = 51.28
  constant SENS_BATT_DELTA_MV : positive := 50;
    -- Delta for current
      -- Current value is n * 250uA / (100 * 5m) [A] => delta of 100mA = 200
  constant SENS_CURR_DELTA_MA : positive := 50;
      -- Distance value is n * 25.4 / (147u * (fclk/rangedvd)) [mm] => delta of 10mm = 57.87
  constant SENS_RANGEFNDR_CLK_DIVIDER : positive :=
    positive(CLOCK_FREQUENCY / 1000000.0);
        -- if zero, no auto send
  constant SENS_RANGEFNDR_MM : natural := 60;
        -- min value for send
  constant SENS_RANGEFNDR_MIN_MM : natural := 152;
        -- max value for send
  constant SENS_RANGEFNDR_MAX_MM : positive := 1500;
      -- HallCount definition
        -- How many 1/2 turns before the hall speed is sent
  constant SENS_HALLCOUNT_HALF_TURN_DELTA : positive := 20;
        -- Base time for Hall Count
  constant SENS_HALL_CLOCK_DIVIDER : positive := 4*CLOCK_1MS_DIVIDER;
        -- Number of clocks the signal must be stable for registering
  constant SENS_HALL_NB_CLOCKS_FILTER : positive := 7;

  --|||||||||||||||
  --|||||||||||||||
        -- Delta in "register unit"
  constant SENS_BATT_DELTA : positive :=
    positive(real(SENS_BATT_DELTA_MV) / (1000.0 * 7.8 * 250.0E-6));
  constant SENS_CURR_DELTA : positive :=
    positive((real(SENS_CURR_DELTA_MA) * 100.0 * 5.0E-3) / (1000.0 * 250.0E-6));
  constant SENS_RANGEFNDR_DELTA : natural :=
    natural(
      (real(SENS_RANGEFNDR_MM) * 0.000147 *
      (CLOCK_FREQUENCY / real(SENS_RANGEFNDR_CLK_DIVIDER))) / 25.4
    );
  constant SENS_RANGEFNDR_MIN_DELTA : natural  :=
    natural(
      (real(SENS_RANGEFNDR_MIN_MM) * 0.000147 *
      (CLOCK_FREQUENCY / real(SENS_RANGEFNDR_CLK_DIVIDER))) / 25.4
    );
  constant SENS_RANGEFNDR_MAX_DELTA : positive :=
    positive(
      (real(SENS_RANGEFNDR_MAX_MM) * 0.000147 *
      (CLOCK_FREQUENCY / real(SENS_RANGEFNDR_CLK_DIVIDER))) / 25.4
    );
  function hall_check return positive;
  constant SENS_HALLCOUNT_TURN_DELTA : positive;

  -- Others
    -- Battery
      -- I2C baudrate
  --|||||||||||||||
  --|||||||||||||||
  constant SENS_batteryBaudRate: real := 100.0E3;
  --|||||||||||||||
  --|||||||||||||||
  constant SENS_batteryBaudRateDivide: positive :=
    integer(CLOCK_FREQUENCY/SENS_batteryBaudRate / 4.0);
      -- How many tries before cancelling transaction with battery reader
  constant SENS_BATT_READ_RETRIES : positive := 5;
      -- Sens read timeout
        -- With 60 SPS -> time of arnd. 17 ms
  constant SENS_BATT_READ_TMOUT_MS : positive := 20;
    -- Ranger
  constant SENS_rangeBitNb : positive := 16;
      -- Time in MS the pulse should not exceed and/or min time btw. two reads
      --  (i.e. problem with sensor or unwired)
  constant SENS_rangeTimeoutBeforeStartMS : positive := 300;
    -- Hall sensors
  constant SENS_hallCountBitNb : positive := 16;

  -- If uses new count system as described below or just counts and send
  constant SENS_HALL_USE_NEW_COUNT_SYSTEM : std_ulogic := '0';
  constant SENS_HALL_OLD_SEND_TIMEOUT_MS : positive := 100;

      -- Number of bits that can be used for counter. Final register is such as:
      --  5bits   : number of 1/2 turns done
      --  11 bits : time elapsed for the number of turns counted in 4 ms 
  constant SENS_HALL_CNT_BITNB : positive := 11;
  constant SENS_HALL_TURNS_BITNB : positive :=
    SENS_hallCountBitNb - SENS_HALL_CNT_BITNB;
      -- If should count 2 pulses per turn or only 1
  constant SENS_HALL_COUNTS_2PULSES_P_TURN : std_ulogic
    := HALLSENS_2PULSES_PER_TURN;

  --------------------------------------------

  -- Control registers
  constant REG_CR_ADDR : natural := 3;
    -- How many writable registers
  constant CR_REG_COUNT : positive := 2;
    -- Total count of register
  constant CR_TOT_REG_COUNT : positive := 2;

  constant CR_HARDWARE_CONTROL_REG_POS : natural := 0;
  constant CR_BLE_STATIS_CONTROL_REG_POS : natural := 1;

  -- Hardware control bits
  constant HW_CTRL_FORWARDS_BIT : natural := 0;
  constant HW_CTRL_CLOCKWISE_BIT : natural := 1;
  constant HW_CTRL_ANGLES_BIT : natural := 2;
  constant HW_CTRL_ENDSW_BIT : natural := 3;
  constant HW_CTRL_RESTART_BIT : natural := 4;
  constant HW_CTRL_BLECONN_BIT : natural := 5;

  -- Bluetooth status bits
  constant BT_STATUS_CONNECTED_BIT : natural := 0;

END Kart;



package body Kart is

  -- Tx buffer
  function check_pow_2(size : positive) return positive is
  begin
    assert(
      (
        to_unsigned(size, 32) and to_unsigned(size-1, 32)
      ) = (32=>'0') )
      report "TX_BUFFER_WANTED_DEPTH must be a power of two" severity failure;
    return size;
  end function check_pow_2;

  constant TX_BUFFER_SIZE : positive := check_pow_2(TX_BUFFER_WANTED_DEPTH);

  -- Hall
  function hall_check return positive is
  begin
    if not (SENS_HALLCOUNT_HALF_TURN_DELTA < 2**SENS_HALL_TURNS_BITNB and SENS_HALLCOUNT_HALF_TURN_DELTA mod 2 = 0) then
      assert(false)
        report
        "SENS_HALLCOUNT_HALF_TURN_DELTA must be even and smaller than " &
          positive'image(2**SENS_HALL_TURNS_BITNB)
        severity failure;
      return 1;
    end if;
    return SENS_HALLCOUNT_HALF_TURN_DELTA;
  end function hall_check;

  constant SENS_HALLCOUNT_TURN_DELTA : positive :=
    hall_check;


  function check_hall_count return std_ulogic is
  begin
    if STD_HALL_NUMBER > SENS_hallSensorNb then
      assert(false)
        report
        "The number of hall sensors (a.k.a STD_HALL_NUMBER - " & positive'image(STD_HALL_NUMBER) & ") cannot exceed " & positive'image(SENS_hallSensorNb) & ". Change it in Kart_Student_pkg.vhd."
        severity failure;
      return '0';
    end if;
    return '1';
  end function check_hall_count;

  constant STD_HALL_NUMBER_OK : std_ulogic := check_hall_count;


  function check_endsw_count return std_ulogic is
  begin
    if STD_ENDSW_NUMBER > SENS_endSwitchNb then
      assert(false)
        report
        "The number of inputs (a.k.a STD_ENDSW_NUMBER - " & natural'image(STD_ENDSW_NUMBER) & ") cannot exceed " & positive'image(SENS_endSwitchNb) & ". Change it in Kart_Student_pkg.vhd."
        severity failure;
      return '0';
    end if;
    return '1';
  end function check_endsw_count;
  
  constant STD_ENDSW_NUMBER_OK : std_ulogic := check_endsw_count;

  function check_outputs_count return std_ulogic is
  begin
    if STD_LEDS_NUMBER + STD_SERVOS_NUMBER > SENS_ledNb then
      assert(false)
        report
        "The number of outputs combined (a.k.a STD_LEDS_NUMBER - " & natural'image(STD_LEDS_NUMBER) & " + STD_SERVOS_NUMBER - " & natural'image(STD_SERVOS_NUMBER) & ") cannot exceed " & positive'image(SENS_ledNb) & ". Change it in Kart_Student_pkg.vhd."
        severity failure;
      return '0';
    end if;
    assert(STD_LEDS_NUMBER /= 0)
      report
      "The number of outputs (a.k.a STD_LEDS_NUMBER - " & natural'image(STD_LEDS_NUMBER) & ") is set to 0 => LEDs outputs are not generated"
      severity note;
    assert(STD_SERVOS_NUMBER /= 0)
      report
      "The number of outputs (a.k.a STD_SERVOS_NUMBER - " & natural'image(STD_SERVOS_NUMBER) & ") is set to 0 => servos outputs are not generated"
      severity note;
    return '1';
  end function check_outputs_count;
  
  constant STD_OUTPUTS_NUMBER_OK : std_ulogic := check_outputs_count;
  
end package body Kart;




LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE gates IS

--  constant gateDelay: time := 1 ns;
  constant gateDelay: time := 0.1 ns;

END gates;




-- VHDL Entity Stepper_test.stepperMotorController_tester.interface
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:08:35 23.06.2022
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;
LIBRARY Kart;
USE Kart.Kart.ALL;
LIBRARY gates;
USE gates.gates.all;

ENTITY stepperMotorController_tester IS
    PORT( 
        coil1                : IN     std_ulogic;
        coil2                : IN     std_uLogic;
        coil3                : IN     std_uLogic;
        coil4                : IN     std_uLogic;
        stepperAddressToSend : IN     symbolSizeType;
        stepperDataToSend    : IN     dataRegisterType;
        stepperSendRequest   : IN     std_ulogic;
        addressIn            : OUT    symbolSizeType;
        clock                : OUT    std_ulogic;
        dataIn               : OUT    dataRegisterType;
        hwOrientation        : OUT    dataRegisterType;
        regWr                : OUT    std_ulogic;
        reset                : OUT    std_ulogic;
        stepperEnd           : OUT    std_ulogic;
        stepperSendAuth      : OUT    std_ulogic;
        testMode             : OUT    std_ulogic
    );

-- Declarations

END stepperMotorController_tester ;





LIBRARY std;
  USE std.textio.all;
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;

PACKAGE testUtils IS

  --============================================================================
  -- console output
  --

  procedure print(value : string);


  --============================================================================
  -- string manipulation
  --

                                                      -- conversion to lowercase
  function lc(value : string) return string;
  procedure lc(value : inout line);
                                                      -- conversion to uppercase
  function uc(value : string) return string;
  procedure uc(value : inout line);
                                            -- expand a string to a given length
  function pad(
    value           : string;
    string_length   : natural;
    fill_char       : character := ' ';
    right_justify   : boolean := false
  ) return string;
                     -- remove separator characters at beginning and end of line
  procedure rm_side_separators(
    value : inout line;
    separators : in string
  );
  procedure rm_side_separators(
    value : inout line
  );
                           -- remove multiple occurences of separator characters
  procedure trim_line(
    value : inout line;
    separators : in string
  );

  procedure trim_line(
    value : inout line
   );
                                -- remove all occurences of separator characters
  procedure rm_all_separators(
    value : inout line;
    separators : in string
  );

  procedure rm_all_separators(
    value : inout line
  );
                                                   -- find and remove first word
  procedure read_first(
    value : inout line;
    separators : in string;
    first : out line
  );

  procedure read_first(
    value : inout line;
    first : out line
   );
                                                    -- find and remove last word
  procedure read_last(
    value : inout line;
    separators : in string;
    last : out line
  );

  procedure read_last(
    value : inout line;
    last : out line
   );


  --============================================================================
  -- formatted string output
  --
  -- format codes:
  --  code  integer real std_logic std_(u)logic_vector (un)signed time
  --    b       v            v               v              v           binary
  --    c                                                               character
  --    d       v     v      v               v              v           decimal
  --    e                                                               real numbers, with power of 10 exponent
  --    f       v     v                                                 fixed point real numbers
  --    s                                                               string
  --    ts                                                          v   time in seconds
  --    tm                                                          v   time in milliseconds
  --    tu                                                          v   time in microseconds
  --    tn                                                          v   time in nanoseconds
  --    tp                                                          v   time in picoseconds
  --    x       v            v               v              v           hexadecimal
  --    X       v            v               v              v           hexadecimal with upper-case letters

  function sprintf(format : string; value : integer          ) return string;
  function sprintf(format : string; value : real             ) return string;
  function sprintf(format : string; value : std_logic        ) return string;
  function sprintf(format : string; value : std_ulogic_vector) return string;
  function sprintf(format : string; value : std_logic_vector ) return string;
  function sprintf(format : string; value : unsigned         ) return string;
  function sprintf(format : string; value : signed           ) return string;
  function sprintf(format : string; value : time             ) return string;

  --============================================================================
  -- formatted string input
  --
  subtype nibbleUlogicType is std_ulogic_vector(3 downto 0);
  subtype nibbleUnsignedType is unsigned(3 downto 0);

  function sscanf(value : character) return natural;
  function sscanf(value : character) return nibbleUlogicType;
  function sscanf(value : character) return nibbleUnsignedType;
  function sscanf(value : string   ) return natural;
  function sscanf(value : string   ) return unsigned;
  function sscanf(value : string   ) return std_ulogic_vector;
  function sscanf(value : string   ) return time;

  procedure sscanf(value : inout line; time_val : out time);

END testUtils;




PACKAGE BODY testUtils IS

  --============================================================================
  -- console output
  --

  procedure print(value : string) is
    variable my_line : line;
  begin
    write(my_line, value);
    writeLine(output, my_line);
    deallocate(my_line);
  end print;


  --============================================================================
  -- string manipulation
  --

  ------------------------------------------------------------------------------
  -- change to lowercase
  ------------------------------------------------------------------------------
  procedure lc(value: inout line) is
    variable out_line: line;
  begin
    for index in value'range loop
      if (value(index) >= 'A') and (value(index) <= 'Z') then
        value(index) := character'val(character'pos(value(index))
                                    - character'pos('A')
                                    + character'pos('a')
                                      );
      end if;
    end loop;
  end lc;

  function lc(value: string) return string is
    variable out_line: line;
  begin
    write(out_line, value);
    lc(out_line);
    return(out_line.all);
  end lc;

  ------------------------------------------------------------------------------
  -- change to uppercase
  ------------------------------------------------------------------------------
  procedure uc(value: inout line) is
    variable out_line: line;
  begin
    for index in value'range loop
      if (value(index) >= 'a') and (value(index) <= 'z') then
        value(index) := character'val(character'pos(value(index))
                                    - character'pos('a')
                                    + character'pos('A')
                                      );
      end if;
    end loop;
  end uc;

  function uc(value: string) return string is
    variable out_line: line;
  begin
    write(out_line, value);
    uc(out_line);
    return(out_line.all);
  end uc;

  ------------------------------------------------------------------------------
  -- formatted string output: padding and justifying
  ------------------------------------------------------------------------------
  function pad(
    value           : string;
    string_length   : natural;
    fill_char       : character := ' ';
    right_justify   : boolean := false
  ) return string is
    variable value_line : line;
    variable out_line : line;
    variable value_length : natural;
    variable shift_sign : boolean;
  begin
    write(value_line, value);
    value_length := value_line.all'length;
    if string_length = 0 then
      write(out_line, value_line.all);
    elsif string_length > value_length then
      if right_justify then
        if (value_line.all(value_line.all'left) <= '-') and not(fill_char = ' ') then
          shift_sign := true;
          write(out_line, value_line.all(value_line.all'left));
        end if;
        for index in 1 to string_length-value_length loop
          write(out_line, fill_char);
        end loop;
      end if;
      if shift_sign then
        write(out_line, value_line.all(value_line.all'left+1 to value_line.all'right));
      else
        write(out_line, value_line.all);
      end if;
      if not right_justify then
        for index in 1 to string_length-value_length loop
          write(out_line, fill_char);
        end loop;
      end if;
    elsif string_length < value_length then
      write(out_line, '#');
      write(out_line, value_line.all(value_length-string_length+2 to value_length));
    else
      write(out_line, value_line.all);
    end if;
    deallocate(value_line);
    return(out_line.all);
  end pad;

  ------------------------------------------------------------------------------
  -- remove separator characters at beginning and end of line
  ------------------------------------------------------------------------------
  procedure rm_side_separators(
    value : inout line;
    separators : in string
  ) is
    variable input_line : line    := value;
    variable found      : boolean := false;
    variable position   : integer := 0;
  begin
    -- remove all separators in the beginning
    position := -1;
    for character_index in input_line'range loop
      found := false;
      for separator_index in separators'range loop
        if input_line(character_index) = separators(separator_index) then
          found := true;
        end if;
      end loop;
      if found then
          position := character_index;
      else
          exit;
      end if;
   end loop;
   if position > -1 then
     input_line := new string'( input_line(position+1 to input_line'right) );
   end if;

   -- remove all separators in the end
    position := -1;
    for character_index in input_line'reverse_range loop
      found := false;
      for separator_index in separators'range loop
        if input_line(character_index) = separators(separator_index) then
          found := true;
        end if;
      end loop;
      if found then
          position := character_index;
      else
          exit;
      end if;
   end loop;
   if position > -1 then
     input_line := new string'( input_line(input_line'left to position-1) );
   end if;

   value := input_line;
  end;

  procedure rm_side_separators(value : inout line) is
  begin
    rm_side_separators(value, " :" & ht);
  end;

  ------------------------------------------------------------------------------
  -- remove multiple occurences of separator characters, keeping one single
  ------------------------------------------------------------------------------
  procedure trim_line(
    value : inout line;
    separators : in string
  ) is
    variable input_line: line := value;
    variable output_line: line := new string'("");
    variable is_separator, was_separator : boolean := false;
  begin
    rm_side_separators(input_line);
    for character_index in input_line'range loop
      is_separator := false;
      for separator_index in separators'range loop
        if input_line.all(character_index) = separators(separator_index) then
          is_separator := true;
        end if;
      end loop;
      if not (is_separator and was_separator) then
        write(output_line, input_line.all(character_index));
      end if;
      was_separator := is_separator;
    end loop;

    value := output_line;
  end;

  procedure trim_line(value : inout line) is
  begin
    trim_line(value, " :" & ht);
  end;

  ------------------------------------------------------------------------------
  -- remove all occurences of separator characters
  ------------------------------------------------------------------------------
  procedure rm_all_separators(
    value : inout line;
    separators : in string
  ) is
    variable input_line   : line    := value;
    variable is_separator : boolean := false;
  begin

    -- remove separators from beginn and end of the line
    -- rm_separator_be(value, separators);

    -- empty output line
    value := new string'("");

    -- find all separator symbols
    for character_index in input_line'range loop
      is_separator := false;
      for separator_index in separators'range loop
        if input_line(character_index) = separators(separator_index) then
          is_separator := true;
        end if;
      end loop;
      if not is_separator then
        write(value, input_line.all(character_index));
      end if;
    end loop;

  end;

  procedure rm_all_separators(value : inout line) is
  begin
    rm_all_separators(value, " _." & ht);
  end;

  ------------------------------------------------------------------------------
  -- read first "word" out of a line
  ------------------------------------------------------------------------------
  procedure read_first(
    value : inout line;
    separators : in string;
    first : out line
  ) is
    variable input_line: line;
    variable position: natural := 0;
  begin
    input_line := value;
    for character_index in input_line.all'reverse_range loop
      for separator_index in separators'range loop
        if input_line.all(character_index) = separators(separator_index) then
          position := character_index;
        end if;
      end loop;
    end loop;
    if position > 1 then
      first := new string'(input_line.all(input_line'left to position-1));
	    value := new string'(input_line(position+1 to input_line'right));
    else
      first := new string'(input_line.all);
	    value := new string'("");
    end if;
  end;

  procedure read_first(value : inout line; first : out line) is
  begin
    read_first(value, " :" & ht, first);
  end;

  ------------------------------------------------------------------------------
  -- read last "word" out of a line
  ------------------------------------------------------------------------------
  procedure read_last(
    value : inout line;
    separators : in string;
    last : out line
  ) is
    variable input_line: line := value;
    variable position: natural := 0;
  begin
    for character_index in input_line'range loop
      for separator_index in separators'range loop
        if input_line(character_index) = separators(separator_index) then
          position := character_index;
        end if;
      end loop;
    end loop;
    if position <= input_line'right and
       position >  0                then
      value := new string'(input_line(input_line'left to position-1));
      last  := new string'(input_line(position+1 to input_line'right));
    else
      last := new string'(input_line.all);
    end if;
  end;

  procedure read_last(value : inout line; last : out line) is
  begin
    read_last(value, " :" & ht, last);
  end;


  --============================================================================
  -- formatted string output, internal functions
  --

  ------------------------------------------------------------------------------
  -- get format specification
  ------------------------------------------------------------------------------
  procedure get_format_items(
    format          : string;
    right_justify   : out boolean;
    add_sign        : out boolean;
    fill_char       : out character;
    total_length    : out natural;
    point_precision : out natural;
    format_type     : inout line
  ) is
    variable find_sign : boolean := false;
    variable find_padding : boolean := false;
    variable find_length : boolean := false;
    variable find_precision : boolean := false;
    variable find_type : boolean := false;
    variable right_justify_int : boolean := true;
    variable total_length_int : natural := 0;
    variable point_precision_int : natural := 0;
  begin
    add_sign := false;
    fill_char := ' ';
    for index in 1 to format'length loop
      if find_type then
        write(format_type, format(index));
      end if;
      if find_precision then
        if (format(index) >= '0') and (format(index) <= '9') then
          point_precision_int := 10*point_precision_int + character'pos(format(index)) - character'pos('0');
          if format(index+1) >= 'A' then
            find_precision := false;
            find_type := true;
          end if;
        end if;
      end if;
      if find_length then
        if (format(index) >= '0') and (format(index) <= '9') then
          total_length_int := 10*total_length_int + character'pos(format(index)) - character'pos('0');
        end if;
        if format(index) = '.' then
          find_length := false;
          find_precision := true;
        elsif format(index+1) >= 'A' then
          find_length := false;
          find_type := true;
        end if;
      end if;
      if find_padding then
        if format(index) = '0' then
          if right_justify_int then
            fill_char := '0';
          end if;
        end if;
        find_padding := false;
        if format(index+1) >= 'A' then
          find_type := true;
        else
          find_length := true;
        end if;
      end if;
      if find_sign then
        if format(index) = '-' then
          right_justify_int := false;
        end if;
        if format(index) = '+' then
          add_sign := true;
        end if;
        find_sign := false;
        if format(index+1) <= '-' then
          find_sign := true;
        elsif format(index+1) = '0' then
          find_padding := true;
        elsif format(index+1) >= 'A' then
          find_type := true;
        else
          find_length := true;
        end if;
      end if;
      if format(index) = '%' then
        if format(index+1) <= '-' then
          find_sign := true;
        elsif format(index+1) = '0' then
          find_padding := true;
        elsif format(index+1) >= 'A' then
          find_type := true;
        else
          find_length := true;
        end if;
      end if;
    end loop;
    right_justify := right_justify_int;
    total_length := total_length_int;
    point_precision := point_precision_int;
  end get_format_items;


  ------------------------------------------------------------------------------
  -- formatted string output: converting std_ulogic to character
  ------------------------------------------------------------------------------
  function to_character(value: std_ulogic) return character is
    variable out_value: character;
  begin
    case value is
      when 'U' => out_value := 'U';
      when 'X' => out_value := 'X';
      when '0' => out_value := '0';
      when '1' => out_value := '1';
      when 'Z' => out_value := 'Z';
      when 'W' => out_value := 'W';
      when 'L' => out_value := 'L';
      when 'H' => out_value := 'H';
      when '-' => out_value := '-';
    end case;
    return(out_value);
  end to_character;

  ------------------------------------------------------------------------------
  -- formatted string output: binary integer
  ------------------------------------------------------------------------------
  function sprintf_b(value: std_ulogic_vector) return string is
    variable out_line : line;
  begin
    for index in value'range loop
      write(out_line, to_character(value(index)));
    end loop;
    return(out_line.all);
  end sprintf_b;

  ------------------------------------------------------------------------------
  -- formatted string output: decimal integer
  ------------------------------------------------------------------------------
  function sprintf_d(
    right_justify   : boolean;
    add_sign        : boolean;
    fill_char       : character;
    string_length   : natural;
    value           : integer
  ) return string is
    variable value_line : line;
  begin
    if add_sign and (value >= 0) then
      write(value_line, '+');
    end if;
    write(value_line, value);
    if string_length = 0 then
      return(value_line.all);
    else
      return(pad(value_line.all, string_length, fill_char, right_justify));
    end if;
  end sprintf_d;

  ------------------------------------------------------------------------------
  -- formatted string output: fixed point real
  ------------------------------------------------------------------------------
  function sprintf_f(
    right_justify   : boolean;
    add_sign        : boolean;
    fill_char       : character;
    string_length   : natural;
    point_precision : natural;
    value           : real
  ) return string is
    variable point_precision_int : natural;
    variable integer_part : integer;
    variable decimal_part : natural;
    variable value_line : line;
  begin
    if point_precision = 0 then
      point_precision_int := 6;
    else
      point_precision_int := point_precision;
    end if;
    if value >= 0.0 then
      integer_part := integer(value-0.5);
    else
      integer_part := - integer(-value-0.5);
    end if;
    decimal_part := abs(integer((value-real(integer_part))*(10.0**point_precision_int)));
    if add_sign and (value >= 0.0) then
      write(value_line, '+');
    end if;
    write(value_line, integer_part);
    write(value_line, '.');
    write(value_line, sprintf_d(true, false, '0', point_precision_int, decimal_part));
    if string_length = 0 then
      return(value_line.all);
    else
      return(pad(value_line.all, string_length, fill_char, right_justify));
    end if;
  end sprintf_f;

  ------------------------------------------------------------------------------
  -- formatted string output: hexadecimal integer
  ------------------------------------------------------------------------------
  function sprintf_X(
    extend_unsigned : boolean;
    value           : std_ulogic_vector
  ) return string is
    variable bit_count : positive;
    variable value_line : line;
    variable out_line : line;
    variable nibble: string(1 to 4);
  begin
    bit_count := value'length;
    while (bit_count mod 4) /= 0 loop
      if extend_unsigned then
        write(value_line, to_character('0'));
      else
        write(value_line, to_character(value(value'high)));
      end if;
      bit_count := bit_count + 1;
    end loop;
    write(value_line, sprintf_b(value));
    for index in value_line.all'range loop
      if (index mod 4) = 0 then
        nibble := value_line.all(index-3 to index);
        case nibble is
          when "0000" => write(out_line, 0);
          when "0001" => write(out_line, 1);
          when "0010" => write(out_line, 2);
          when "0011" => write(out_line, 3);
          when "0100" => write(out_line, 4);
          when "0101" => write(out_line, 5);
          when "0110" => write(out_line, 6);
          when "0111" => write(out_line, 7);
          when "1000" => write(out_line, 8);
          when "1001" => write(out_line, 9);
          when "1010" => write(out_line, 'A');
          when "1011" => write(out_line, 'B');
          when "1100" => write(out_line, 'C');
          when "1101" => write(out_line, 'D');
          when "1110" => write(out_line, 'E');
          when "1111" => write(out_line, 'F');
          when others => write(out_line, 'X');
        end case;
      end if;
    end loop;
    return(out_line.all);
  end sprintf_X;


  --============================================================================
  -- formatted string output, interface functions
  --

  ------------------------------------------------------------------------------
  -- integer
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : integer) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     string_length, point_precision, format_type);
    if format_type.all = "b" then
      if string_length = 0 then
        string_length := 8;
      end if;
      return(sprintf_b(std_ulogic_vector(to_signed(value, string_length+1)(string_length-1 downto 0))));
    elsif format_type.all = "d" then
      return(sprintf_d(right_justify, add_sign, fill_char, string_length, value));
    elsif format_type.all = "f" then
      return(sprintf_f(right_justify, add_sign, fill_char,
                       string_length, point_precision, real(value)));
    elsif (format_type.all = "X") or (format_type.all = "x") then
      if string_length = 0 then
        string_length := 8;
      end if;
      string_length := 4*string_length;
      if format_type.all = "X" then
        return(sprintf_X(false, std_ulogic_vector(to_signed(value, string_length+1)(string_length-1 downto 0))));
      else
        return(lc(sprintf_X(false, std_ulogic_vector(to_signed(value, string_length+1)(string_length-1 downto 0)))));
      end if;
    else
      return("Unhandled format type: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- real
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : real) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     string_length, point_precision, format_type);
    if (format_type.all = "d") or (point_precision = 0) then
      return(sprintf_d(right_justify, add_sign, fill_char,
                       string_length, integer(value)));
    elsif format_type.all = "f" then
      return(sprintf_f(right_justify, add_sign, fill_char,
                       string_length, point_precision, value));
    else
      return("Unhandled format type: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- std_logic
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : std_logic) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
    variable logic_vector: std_logic_vector(1 to 1);
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     string_length, point_precision, format_type);
    if (format_type.all = "b") or (format_type.all = "d") or
       (format_type.all = "X") or (format_type.all = "x") then
      logic_vector(1) := value;
      return(sprintf(format, std_ulogic_vector(logic_vector)));
    else
      return("Not a std_logic format: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- std_ulogic_vector
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : std_ulogic_vector) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable bit_string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     bit_string_length, point_precision, format_type);
    if format_type.all = "b" then
      return(pad(sprintf_b(value), bit_string_length, fill_char, right_justify));
    elsif format_type.all = "d" then
      return(sprintf_d(right_justify, add_sign, fill_char, bit_string_length, to_integer(unsigned(value))));
    elsif (format_type.all = "X") or (format_type.all = "x") then
      if format_type.all = "X" then
        return(pad(sprintf_X(true, value), bit_string_length, fill_char, right_justify));
      else
        return(lc(pad(sprintf_X(true, value), bit_string_length, fill_char, right_justify)));
      end if;
    else
      return("Not a std_ulogic_vector format: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- std_logic_vector
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : std_logic_vector) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     string_length, point_precision, format_type);
    if (format_type.all = "b") or (format_type.all = "d") or
       (format_type.all = "X") or (format_type.all = "x") then
      return(sprintf(format, std_ulogic_vector(value)));
    else
      return("Not a std_logic_vector format: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- unsigned
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : unsigned) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     string_length, point_precision, format_type);
    if (format_type.all = "b") or (format_type.all = "d") or
       (format_type.all = "X") or (format_type.all = "x") then
      return(sprintf(format, std_ulogic_vector(value)));
    else
      return("Not an unsigned format: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- signed
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : signed) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable bit_string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     bit_string_length, point_precision, format_type);
    if (fill_char = '0') and (value(value'left) = '1') then
      fill_char := '1';
    end if;
    if format_type.all = "b" then
      return(pad(sprintf_b(std_ulogic_vector(value)), bit_string_length, fill_char, right_justify));
    elsif format_type.all = "d" then
      return(sprintf_d(right_justify, add_sign, fill_char, bit_string_length, to_integer(signed(value))));
    elsif (format_type.all = "X") or (format_type.all = "x") then
      if fill_char = '1' then
        fill_char := 'F';
      end if;
      if format_type.all = "X" then
        return(pad(sprintf_X(true, std_ulogic_vector(value)), bit_string_length, fill_char, right_justify));
      else
        return(lc(pad(sprintf_X(true, std_ulogic_vector(value)), bit_string_length, fill_char, right_justify)));
      end if;
    else
      return("Not a signed format: '" & format_type.all & "'");
    end if;
  end sprintf;

  ------------------------------------------------------------------------------
  -- time
  ------------------------------------------------------------------------------
  function sprintf(format : string; value : time) return string is
    variable right_justify : boolean;
    variable add_sign : boolean;
    variable fill_char : character;
    variable string_length : natural;
    variable point_precision : natural;
    variable format_type : line;
    variable scaling : real;
    variable base_time : time;
    variable unit : string(1 to 3);
  begin
    get_format_items(format, right_justify, add_sign, fill_char,
                     string_length, point_precision, format_type);
    if format_type.all(format_type.all'left) = 't' then
      scaling := 10.0**point_precision;
      if format_type.all = "tp" then
        base_time := 1 ps;
        unit := " ps";
      elsif format_type.all = "tn" then
        base_time := 1 ns;
        unit := " ns";
      elsif format_type.all = "tu" then
        base_time := 1 us;
        unit := " us";
      elsif format_type.all = "tm" then
        base_time := 1 ms;
        unit := " ms";
      elsif format_type.all = "ts" then
        base_time := 1 sec;
        unit := " s.";
      else
        return("Undefined time format: '" & format_type.all & "'");
      end if;
      if point_precision = 0 then
        return(sprintf_d(right_justify, add_sign, fill_char,
                         string_length, value/base_time) & unit);
      else
        return(sprintf_f(right_justify, add_sign, fill_char, string_length,
                         point_precision, real(scaling*value/base_time)/scaling) & unit);
      end if;
    else
      return("Not a time format: '" & format_type.all & "'");
    end if;
  end sprintf;


  --============================================================================
  -- formatted string input
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- read a nibble out of a character
  ------------------------------------------------------------------------------
  function sscanf(value : character) return natural is
  begin
    if (value >= '0') and (value <= '9') then
      return(character'pos(value) - character'pos('0'));
    elsif (value >= 'a') and (value <= 'f') then
      return(character'pos(value) - character'pos('a') + 10);
    elsif (value >= 'A') and (value <= 'F') then
      return(character'pos(value) - character'pos('A') + 10);
    else
      return(0);
    end if;
  end sscanf;

  function sscanf(value : character) return nibbleUnsignedType is
  begin
    return(to_unsigned(sscanf(value), nibbleUnsignedType'length));
  end sscanf;

  function sscanf(value : character) return nibbleUlogicType is
    variable unsigned_value : nibbleUnsignedType;
  begin
    unsigned_value := sscanf(value);
    return(std_ulogic_vector(unsigned_value));
  end sscanf;

  ------------------------------------------------------------------------------
  -- read an binary word out of a string
  ------------------------------------------------------------------------------
  function sscanf(value : string) return natural is
    variable integer_value : natural;
  begin
    integer_value := 0;
    for index in value'left to value'right loop
      integer_value := integer_value*16 + sscanf(value(index));
    end loop;
    return(integer_value);
  end;

  function sscanf(value : string) return unsigned is
    variable unsigned_value : unsigned(4*value'length-1 downto 0);
  begin
    unsigned_value := to_unsigned(0,unsigned_value'length);
    for index in value'left to value'right loop
      unsigned_value := shift_left(unsigned_value,4) + to_unsigned(sscanf(value(index)),4);
    end loop;
    return(unsigned_value);
  end;

  function sscanf(value : string) return std_ulogic_vector is
    variable unsigned_value : unsigned(4*value'length-1 downto 0);
  begin
    unsigned_value := sscanf(value);
    return(std_ulogic_vector(unsigned_value));
  end;

  ------------------------------------------------------------------------------
  -- read time from a string
  -- time can be formated as follows:
  --   "1ps" or "1 ps" or " 1 ps " or " 1ps"
  -- possible time units are: hr, min, sec, ms, us, ns, ps, fs
  ------------------------------------------------------------------------------
  procedure sscanf(
     value    : inout line;
     time_val : out time
  ) is
      variable time_line  : line := value;
      variable time_base  : string(1 to 3);
      variable time_value : integer;
      variable time_int   : time;
  begin
    -- remove all spaces and tabs
    rm_all_separators(time_line);

    -- strip time base (3 last characters)
    time_base := time_line(time_line'right-2 to time_line'right);

    -- separate time value and base
    if time_base(2 to 3) = "hr" then
        time_int   := 1 hr;
        time_value := integer'value(time_line(time_line'left to time_line'right -2));
    elsif time_base = "min" then
        time_int   := 1 min;
        time_value := integer'value(time_line(time_line'left to time_line'right -3));
    elsif time_base = "sec" then
        time_int   := 1 sec;
        time_value := integer'value(time_line(time_line'left to time_line'right -3));
    elsif time_base(2 to 3) = "ms" then
        time_int   := 1 ms;
        time_value := integer'value(time_line(time_line'left to time_line'right -2));
    elsif time_base(2 to 3) = "us" then
        time_int   := 1 us;
        time_value := integer'value(time_line(time_line'left to time_line'right -2));
    elsif time_base(2 to 3) = "ns" then
        time_int   := 1 ns;
        time_value := integer'value(time_line(time_line'left to time_line'right -2));
    elsif time_base(2 to 3) = "ps" then
        time_int   := 1 ps;
        time_value := integer'value(time_line(time_line'left to time_line'right -2));
    elsif time_base(2 to 3) = "fs" then
        time_int   := 1 fs;
        time_value := integer'value(time_line(time_line'left to time_line'right -2));
    else
        time_int   := 0 ps;
        time_value := 1;
    end if;

    -- build time from value and base
    time_val := time_int * time_value;

  end;

  function sscanf(value : string) return time is
    variable value_line : line;
    variable time_val   : time;
  begin
    value_line := new string'(value);
    sscanf(value_line, time_val);
    return(time_val);
  end;

END testUtils;




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
    hardwareOrientation <= HC_FORWARDS;
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
    hardwareOrientation <= HC_FORWARDS;
    wait for 6*testInterval;
    
    -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    wait for testInterval;
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
      severity note;
    write(output, "" & lf);
    stepperEnd <= '0';
    wait for 5*testInterval;



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
    assert turn1to4 = turnBack
      report "Coil direction error"
      severity error;
    assert turn1to4 /= turnBack
      report "Coil direction OK"
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
    hardwareOrientation <= HC_CLOCKWISE + HC_FORWARDS;
    wait for testInterval;

    
    -- send quarter angle
    testInfo <= pad("Turn 1/4", testInfo'length);
    write(output,
      "Sending turn control to quarter angle" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(targetAngleWRAddr, angleMaxValue/4);
    stepperEnd <= '0';
    wait for 5*testInterval;





    testInfo <= pad("XXXXXXXXXXXX - 10", testInfo'length);
    hardwareOrientation <= HC_SENSOR_LEFT + HC_FORWARDS;
    wait for 1 ms;

    -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_RESTART + HC_SENSOR_LEFT + HC_FORWARDS;
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
    hardwareOrientation <= HC_SENSOR_LEFT + HC_FORWARDS;
    wait for 3*testInterval;

                                                          -- actuate end switch
    testInfo <= pad("End switch local", testInfo'length);
    wait for 3*testInterval;
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
    stepperEnd <= '0';
    wait for 5*testInterval;







    testInfo <= pad("XXXXXXXXXXXX - 11", testInfo'length);
    hardwareOrientation <= HC_SENSOR_LEFT + HC_CLOCKWISE + HC_FORWARDS;
    wait for 1 ms;

    -- send restart
    testInfo <= pad("Restart", testInfo'length);
    write(output,
      "Setting restart bit high - motor should begin to reset" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_RESTART + HC_SENSOR_LEFT + HC_CLOCKWISE + HC_FORWARDS;
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
    hardwareOrientation <= HC_SENSOR_LEFT + HC_CLOCKWISE + HC_FORWARDS;
    wait for 3*testInterval;

                                                          -- actuate end switch
    testInfo <= pad("End switch local", testInfo'length);
    wait for 3*testInterval;
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
    stepperEnd <= '0';
    wait for 5*testInterval;








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
    hardwareOrientation <= HC_RESTART + HC_CLOCKWISE + HC_FORWARDS;
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
    hardwareOrientation <= HC_CLOCKWISE + HC_FORWARDS;
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
    hardwareOrientation <= HC_RESTART + HC_CLOCKWISE + HC_FORWARDS;
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
    hardwareOrientation <= HC_CLOCKWISE + HC_FORWARDS;
    wait for 8*testInterval;

                                                 -- assert end contact HWControl
    testInfo <= pad("Emulated end switch ON", testInfo'length);
    write(output,
      "Emulating end switch to ON" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_STEPPER_END_EMULATION + HC_CLOCKWISE + HC_FORWARDS;
    wait for 20*testInterval;
                                             -- deassert end contact from master
    write(output,
      "Emulating end switch to OFF" &
      " at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    hardwareOrientation <= HC_CLOCKWISE + HC_FORWARDS;
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




