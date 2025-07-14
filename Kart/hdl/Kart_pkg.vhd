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
  constant STP_PWM_DC : real := 0.72; --Should never be higher than 0.75 (12V * 0.75 = 9V, max voltage for stepper). A bit lower to avoid overheating.
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
