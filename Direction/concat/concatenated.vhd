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

  -- Direction motor

  constant REG_DMOT_ADDR : natural := 1;
    -- How many writable registers
  constant DMOT_REG_COUNT : positive := 4;
    -- Total count of register
  constant DMOT_TOT_REG_COUNT : positive := 4;

  -- Regs defs
  constant DMOT_TARGETANGLE_REG_POS : natural := 0;
  constant DMOT_CUSTOM1_REG_POS : natural := 1;
  constant DMOT_CUSTOM2_REG_POS : natural := 2;
  constant DMOT_CUSTOM3_REG_POS : natural := 3;

  -- Others
  constant DMOT_TARGETCMD_BIT_NB : positive := 8;
  constant DMOT_MINCMD_uS : positive := 1000; -- 1ms, MUST correspond to servomotor minimal pulse time to avoid it burning
  constant DMOT_MAXCMD_uS : positive := 2000; -- 2ms, MUST correspond to servomotor maximal pulse time to avoid it burning
  constant DMOT_MINCMD_CLOCKS : positive := positive(real(DMOT_MINCMD_uS) * 1.0E-6 * CLOCK_FREQUENCY);
  constant DMOT_MAXCMD_CLOCKS : positive := positive(real(DMOT_MAXCMD_uS) * 1.0E-6 * CLOCK_FREQUENCY);
  constant DMOT_CMD_CLOCKS_STEP : positive := positive(real(DMOT_MAXCMD_CLOCKS - DMOT_MINCMD_CLOCKS) / real(2**DMOT_TARGETCMD_BIT_NB - 1));

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




-- VHDL Entity Stepper.dmotMotorController.symbol
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 15:24:55 28.04.2026
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;

LIBRARY Kart;
USE Kart.Kart.ALL;

ENTITY dmotMotorController IS
    PORT( 
        addressIn         : IN     symbolSizeType;
        clock             : IN     std_ulogic;
        dataIn            : IN     dataRegisterType;
        dmotSendAuth      : IN     std_ulogic;
        regWr             : IN     std_ulogic;
        reset             : IN     std_ulogic;
        directionServo    : OUT    std_ulogic;
        dmotAddressToSend : OUT    symbolSizeType;
        dmotDataToSend    : OUT    dataRegisterType;
        dmotSendRequest   : OUT    std_ulogic
    );

-- Declarations

END dmotMotorController ;





-- VHDL Entity Stepper.directionControl.symbol
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 10:57:01 29.04.2026
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;


LIBRARY Kart;
USE Kart.Kart.ALL;

ENTITY directionControl IS
    PORT( 
        clock          : IN     std_uLogic;
        customReg1     : IN     std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg2     : IN     std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg3     : IN     std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        reset          : IN     std_uLogic;
        target         : IN     unsigned (VALUE_BIT_NB-1 DOWNTO 0);
        directionServo : OUT    std_ulogic
    );

-- Declarations

END directionControl ;





LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE gates IS

--  constant gateDelay: time := 1 ns;
  constant gateDelay: time := 0.1 ns;

END gates;




-- VHDL Entity sequential.freqDivider.symbol
--
-- Created:
--          by - francois.francois (Aphelia)
--          at - 13:46:18 08/28/19
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;
LIBRARY gates;
  USE gates.gates.all;

ENTITY freqDivider IS
    GENERIC( 
        divideValue : positive := 256;
        delay       : time     := gateDelay
    );
    PORT( 
        clock  : IN     std_ulogic;
        reset  : IN     std_ulogic;
        enable : OUT    std_ulogic
    );

-- Declarations

END freqDivider ;





--------------------------------------------------------------------------------
-- Copyright 2012 HES-SO Valais Wallis (www.hevs.ch)
--------------------------------------------------------------------------------
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program IS distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with
-- this program. If not, see <http://www.gnu.org/licenses/>
-- -----------------------------------------------------------------------------
-- Common Lib
--
-- -----------------------------------------------------------------------------
--  Authors:
--    cof: [François Corthay](francois.corthay@hevs.ch)
--    guo: [Oliver A. Gubler](oliver.gubler@hevs.ch)
-- -----------------------------------------------------------------------------
-- Changelog:
--   2016-06 : guo
--     added function sel
--   2015-06 : guo
--     added counterBitNb
--     added documentation
-- -----------------------------------------------------------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

PACKAGE CommonLib IS

  ------------------------------------------------------------------------------
  -- Returns the number of bits needed to represent the given val
  -- Examples:
  --   requiredBitNb(1) = 1   (1)
  --   requiredBitNb(2) = 2   (10)
  --   requiredBitNb(3) = 2   (11)
  function requiredBitNb(val : integer) return integer;

  ------------------------------------------------------------------------------
  -- Returns the number of bits needed to count val times (0 to val-1)
  -- Examples:
  --   counterBitNb(1) = 1    (0)
  --   counterBitNb(2) = 1    (0->1)
  --   counterBitNb(3) = 2    (0->1->10)
  function counterBitNb(val : integer) return integer;

  ------------------------------------------------------------------------------
  -- Functions to return one or the other input based on a boolean.
  -- Can be used to build conditional constants.
  -- Example:
  --   constant bonjour_c : string := sel(ptpRole = master, "fpga20", "fpga02");
  function sel(Cond : BOOLEAN; If_True, If_False : integer)
                                            return integer;
  function sel(Cond : BOOLEAN; If_True, If_False : string)
                                            return string;
  function sel(Cond : BOOLEAN; If_True, If_False : std_ulogic_vector)
                                            return std_ulogic_vector;
  function sel(Cond : BOOLEAN; If_True, If_False : unsigned)
                                            return unsigned;
  function sel(Cond : BOOLEAN; If_True, If_False : signed)
                                            return signed;

END CommonLib;




--------------------------------------------------------------------------------
-- Copyright 2012 HES-SO Valais Wallis (www.hevs.ch)
--------------------------------------------------------------------------------
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program IS distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with
-- this program. If not, see <http://www.gnu.org/licenses/>
-- -----------------------------------------------------------------------------
-- Often used functions
--
-- -----------------------------------------------------------------------------
--  Authors:
--    cof: [François Corthay](francois.corthay@hevs.ch)
--    guo: [Oliver A. Gubler](oliver.gubler@hevs.ch)
-- -----------------------------------------------------------------------------
-- Changelog:
--   2016-06 : guo
--     added function sel
--   2015-06 : guo
--     added counterBitNb
-- -----------------------------------------------------------------------------
PACKAGE BODY CommonLib IS

  function requiredBitNb (val : integer) return integer is
    variable powerOfTwo, bitNb : integer;
  begin
    powerOfTwo := 1;
    bitNb := 0;
    while powerOfTwo <= val loop
      powerOfTwo := 2 * powerOfTwo;
      bitNb := bitNb + 1;
    end loop;
    return bitNb;
  end requiredBitNb;

  function counterBitNb (val : integer) return integer is
    variable powerOfTwo, bitNb : integer;
  begin
    powerOfTwo := 1;
    bitNb := 0;
    while powerOfTwo < val loop
      powerOfTwo := 2 * powerOfTwo;
      bitNb := bitNb + 1;
    end loop;
    return bitNb;
  end counterBitNb;

  function sel(Cond : BOOLEAN; If_True, If_False : integer)
                                            return integer is
  begin
    if (Cond = TRUE) then
      return (If_True);
    else
      return (If_False);
    end if;
  end function sel;

  function sel(Cond : BOOLEAN; If_True, If_False : string)
                                            return string is
  begin
    if (Cond = TRUE) then
      return (If_True);
    else
      return (If_False);
    end if;
  end function sel;

  function sel(Cond : BOOLEAN; If_True, If_False : std_ulogic_vector)
                                            return std_ulogic_vector is
  begin
    if (Cond = TRUE) then
      return (If_True);
    else
      return (If_False);
    end if;
  end function sel;

  function sel(Cond : BOOLEAN; If_True, If_False : unsigned)
                                            return unsigned is
  begin
    if (Cond = TRUE) then
      return (If_True);
    else
      return (If_False);
    end if;
  end function sel;

  function sel(Cond : BOOLEAN; If_True, If_False : signed)
                                            return signed is
  begin
    if (Cond = TRUE) then
      return (If_True);
    else
      return (If_False);
    end if;
  end function sel;

END CommonLib;




LIBRARY Common;
  USE Common.CommonLib.all;

ARCHITECTURE RTL OF freqDivider IS

  signal count: unsigned(requiredBitNb(divideValue)-1 downto 0);

BEGIN

  countEndlessly: process(reset, clock)
  begin
    if reset = '1' then
      count <= (others => '0');
    elsif rising_edge(clock) then
      if count = 0 then
        count <= to_unsigned(divideValue-1, count'length);
      else
        count <= count-1 ;
      end if;
    end if;
  end process countEndlessly;

  enable <= '1' after delay when count = 0
    else '0' after delay;

END ARCHITECTURE RTL;




-- VHDL Entity Sensors.servoController.symbol
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 15:14:56 26/06/2024
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

ENTITY servoController IS
    PORT( 
        clock        : IN     std_ulogic;
        count_target : IN     dataRegisterType;
        pulse_20ms   : IN     std_ulogic;
        reset        : IN     std_ulogic;
        servo        : OUT    std_ulogic
    );

-- Declarations

END servoController ;





Library Kart;
  Use Kart.Kart.ALL;

ARCHITECTURE masterVersion OF servoController IS

  signal lvec_pulse_counter: unsigned(count_target'range);

BEGIN

  ------------------------------------------------------------------------------
                                                  -- Start the pulse when needed
  process(reset, clock)
  begin
  	if reset = '1' then
  		lvec_pulse_counter <= (others => '0');
  	elsif rising_edge(clock) then
  		if pulse_20ms = '1' then
  			lvec_pulse_counter <= unsigned(count_target);
  		elsif lvec_pulse_counter /= 0 then
  			lvec_pulse_counter <= lvec_pulse_counter - 1;
  		end if;
  	end if;  		
  end process;

  servo <= '1' when lvec_pulse_counter /= 0 else '0';

END ARCHITECTURE masterVersion;





--
-- VHDL Architecture Stepper.directionControl.masterVersion
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 11:00:18 29.04.2026
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;
LIBRARY gates;
  USE gates.gates.all;

LIBRARY Kart;
USE Kart.Kart.ALL;

LIBRARY Sensors;
LIBRARY sequential;

ARCHITECTURE masterVersion OF directionControl IS

    -- Architecture declarations

    -- Internal signal declarations
    SIGNAL lsig_20ms_pulse   : std_ulogic;
    SIGNAL lvec_count_target : dataRegisterType;


    -- Component Declarations
    COMPONENT servoController
    PORT (
        clock        : IN     std_ulogic ;
        count_target : IN     dataRegisterType ;
        pulse_20ms   : IN     std_ulogic ;
        reset        : IN     std_ulogic ;
        servo        : OUT    std_ulogic 
    );
    END COMPONENT;
    COMPONENT freqDivider
    GENERIC (
        divideValue : positive := 256;
        delay       : time     := gateDelay
    );
    PORT (
        clock  : IN     std_ulogic ;
        reset  : IN     std_ulogic ;
        enable : OUT    std_ulogic 
    );
    END COMPONENT;

    -- Optional embedded configurations
    -- pragma synthesis_off
    FOR ALL : freqDivider USE ENTITY sequential.freqDivider;
    FOR ALL : servoController USE ENTITY Sensors.servoController;
    -- pragma synthesis_on


BEGIN
    -- Architecture concurrent statements
    -- HDL Embedded Text Block 1 eb1
    lvec_count_target <= dataRegisterType(target);


    -- Instance port mappings.
    I_servo_controller : servoController
        PORT MAP (
            clock        => clock,
            count_target => lvec_count_target,
            pulse_20ms   => lsig_20ms_pulse,
            reset        => reset,
            servo        => directionServo
        );
    I0 : freqDivider
        GENERIC MAP (
            divideValue => 20 * CLOCK_1MS_DIVIDER,
            delay       => gateDelay
        )
        PORT MAP (
            clock  => clock,
            reset  => reset,
            enable => lsig_20ms_pulse
        );

END masterVersion;




-- VHDL Entity Stepper.dmotMotorRegisters.symbol
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 10:55:32 29.04.2026
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;

LIBRARY Kart;
USE Kart.Kart.ALL;

ENTITY dmotMotorRegisters IS
    PORT( 
        addressIn         : IN     symbolSizeType;
        clock             : IN     std_ulogic;
        dataIn            : IN     dataRegisterType;
        dmotSendAuth      : IN     std_ulogic;
        regWr             : IN     std_ulogic;
        reset             : IN     std_ulogic;
        customReg1        : OUT    std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg2        : OUT    std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg3        : OUT    std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        dmotAddressToSend : OUT    symbolSizeType;
        dmotDataToSend    : OUT    dataRegisterType;
        dmotSendRequest   : OUT    std_ulogic;
        target            : OUT    unsigned (VALUE_BIT_NB-1 DOWNTO 0)
    );

-- Declarations

END dmotMotorRegisters ;





-- VHDL Entity Kart.reg_addr_decoder.symbol
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 14:39:40 13.05.2022
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;

LIBRARY Common;
  USE Common.CommonLib.ALL;

LIBRARY Kart;
  USE Kart.Kart.ALL;

ENTITY reg_addr_decoder IS
    GENERIC( 
        moduleAddr : natural := 0
    );
    PORT( 
        address      : IN     symbolSizeType;
        wr           : IN     std_ulogic;
        loadRegister : OUT    std_ulogic;
        readRegister : OUT    std_ulogic
    );

-- Declarations

END reg_addr_decoder ;





--
-- VHDL Architecture Kart.reg_addr_decoder.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 10:49:17 12.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.all;

ARCHITECTURE rtl OF reg_addr_decoder IS

signal p_module_selected : std_ulogic;

BEGIN

  p_module_selected <= '1' when address(address'high downto address'high - 
      REG_ADDR_MSB_NB_BITS + 1) = std_ulogic_vector(to_unsigned(moduleAddr, REG_ADDR_MSB_NB_BITS)) and wr = '1' else '0';

  loadRegister <= '1' when p_module_selected = '1' and address(REG_ADDR_GET_BIT_POSITION) = FRAME_WBIT_VALUE else '0';
  readRegister <= '1' when p_module_selected = '1' and address(REG_ADDR_GET_BIT_POSITION) = not FRAME_WBIT_VALUE else '0';

END ARCHITECTURE rtl;




-- VHDL Entity Stepper.dmotPulseTargetFormatter.interface
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 10:55:32 29.04.2026
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

ENTITY dmotPulseTargetFormatter IS
    PORT( 
        clock         : IN     std_ulogic;
        reset         : IN     std_ulogic;
        targetCommand : IN     unsigned (DMOT_TARGETCMD_BIT_NB-1 DOWNTO 0);
        target        : OUT    unsigned (VALUE_BIT_NB-1 DOWNTO 0)
    );

-- Declarations

END dmotPulseTargetFormatter ;





-- Format input command to a corresponding clock pulse count value
-- Axam

LIBRARY Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE RTL OF dmotPulseTargetFormatter IS

  signal lvec_target : unsigned( VALUE_BIT_NB-1 DOWNTO 0 );

BEGIN

  process(reset, clock)
  begin
    if reset = '1' then
      lvec_target <= (others => '0');
    elsif rising_edge(clock) then
      lvec_target <= DMOT_MINCMD_CLOCKS + resize((DMOT_CMD_CLOCKS_STEP * targetCommand), lvec_target'length);
    end if;
  end process;

  target <= lvec_target;

END ARCHITECTURE RTL;




-- VHDL Entity Kart.registerManager.symbol
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 14:57:34 13.05.2022
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;

LIBRARY Common;
  USE Common.CommonLib.ALL;

LIBRARY Kart;
  USE Kart.Kart.ALL;

ENTITY registerManager IS
    GENERIC( 
        registersNb : positive := 7
    );
    PORT( 
        addressIn : IN     symbolSizeType;
        clock     : IN     std_ulogic;
        dataIn    : IN     dataRegisterType;
        loadNew   : IN     std_ulogic;
        reset     : IN     std_ulogic;
        bankData  : OUT    registersHolderType (registersNb-1 DOWNTO 0)
    );

-- Declarations

END registerManager ;





--
-- VHDL Architecture Kart.registerManager.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:15:36 12.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF registerManager IS

  -- Registers
    -- Actual registers bank
  signal p_registers : registersHolderType(registersNb-1 downto 0);
  signal p_int_reg_addr : REG_COUNT_RANGE;
BEGIN

  p_int_reg_addr <= to_integer(unsigned(addressIn(REG_ADDR_REG_RANGE)));

  -- Registers read
  bankData <= p_registers;

  --------------------------------------------------------------

  -- Registers input
  register_input: process(reset,clock)
  begin
    if reset = '1' then
      p_registers <= (others=>(others=>'0'));
    elsif rising_edge(clock) then
      -- On load + ensure register exists
      if loadNew = '1' and p_int_reg_addr < registersNb then
        p_registers(p_int_reg_addr) <= dataIn;
      end if;
    end if;
  end process register_input;

END ARCHITECTURE rtl;




-- VHDL Entity Stepper.dmotMotorRegisterSender.symbol
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 15:28:27 28.04.2026
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

ENTITY dmotMotorRegisterSender IS
    GENERIC( 
        registersNb   : positive := 8;
        moduleAddr    : natural  := 1;
        inRegistersNb : natural  := 4
    );
    PORT( 
        addressIn         : IN     symbolSizeType;
        bankData          : IN     registersHolderType (inRegistersNb-1 DOWNTO 0);
        clock             : IN     std_ulogic;
        dmotSendAuth      : IN     std_ulogic;
        readRegister      : IN     std_ulogic;
        reset             : IN     std_ulogic;
        dmotAddressToSend : OUT    symbolSizeType;
        dmotDataToSend    : OUT    dataRegisterType;
        dmotSendRequest   : OUT    std_ulogic
    );

-- Declarations

END dmotMotorRegisterSender ;





--
-- VHDL Architecture Stepper.stepperMotorRegisterSender.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 16:55:03 13.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF dmotMotorRegisterSender IS

  -- Send state machine states
  type statesType is (
      idle, request
    );
  signal p_state : statesType;

      -- Address that will be output
  signal p_addr_out : symbolSizeType;
  signal p_data_out : dataRegisterType;
  signal p_request : std_ulogic;
  signal p_int_reg_addr : REG_COUNT_RANGE;

  constant regExtAddrBegin : std_ulogic_vector(REG_ADDR_MSB_NB_BITS downto 0)
    := std_ulogic_vector(to_unsigned(moduleAddr, REG_ADDR_MSB_NB_BITS)) & FRAME_WBIT_VALUE;

BEGIN

  p_int_reg_addr <= to_integer(unsigned(addressIn(REG_ADDR_REG_RANGE)));

  register_send: process(reset, clock)
  begin
    if reset = '1' then
      p_request <= '0';
      p_addr_out <= (others=>'0');
      p_data_out <= (others=>'0');
      p_state <= idle;
    elsif rising_edge(clock) then
      case p_state is
        -- Check for send request
        when idle =>
          -- Request from Rx
          if readRegister = '1' then
            -- Ensure the requested register exists
            if p_int_reg_addr < registersNb then
              p_addr_out <= addressIn;
              p_request <= '1';
              p_state <= request;
              -- Check if is a standard or "external" register
              if p_int_reg_addr < inRegistersNb then
                p_data_out <= bankData(p_int_reg_addr);
              else
                p_state <= idle;
              end if;
            end if;
          end if;

        when request =>
          if dmotSendAuth = '1' then
            p_request <= '0';
            p_state <= idle;
          end if;

        when others => p_state <= idle;

      end case;
    end if;
  end process register_send;

  dmotSendRequest <= p_request;
  dmotAddressToSend <= p_addr_out;
  dmotDataToSend <= p_data_out;

END ARCHITECTURE rtl;




--
-- VHDL Architecture Stepper.dmotMotorRegisters.struct
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 11:02:41 29.04.2026
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

LIBRARY Stepper;

ARCHITECTURE struct OF dmotMotorRegisters IS

    -- Architecture declarations

    -- Internal signal declarations
    SIGNAL bankData      : registersHolderType(DMOT_REG_COUNT-1 DOWNTO 0);
    SIGNAL loadRegister  : std_ulogic;
    SIGNAL readRegister  : std_ulogic;
    SIGNAL targetCommand : unsigned(DMOT_TARGETCMD_BIT_NB-1 DOWNTO 0);


    -- Component Declarations
    COMPONENT reg_addr_decoder
    GENERIC (
        moduleAddr : natural := 0
    );
    PORT (
        address      : IN     symbolSizeType ;
        wr           : IN     std_ulogic ;
        loadRegister : OUT    std_ulogic ;
        readRegister : OUT    std_ulogic 
    );
    END COMPONENT;
    COMPONENT registerManager
    GENERIC (
        registersNb : positive := 7
    );
    PORT (
        addressIn : IN     symbolSizeType ;
        clock     : IN     std_ulogic ;
        dataIn    : IN     dataRegisterType ;
        loadNew   : IN     std_ulogic ;
        reset     : IN     std_ulogic ;
        bankData  : OUT    registersHolderType (registersNb-1 DOWNTO 0)
    );
    END COMPONENT;
    COMPONENT dmotMotorRegisterSender
    GENERIC (
        registersNb   : positive := 8;
        moduleAddr    : natural  := 1;
        inRegistersNb : natural  := 4
    );
    PORT (
        addressIn         : IN     symbolSizeType ;
        bankData          : IN     registersHolderType (inRegistersNb-1 DOWNTO 0);
        clock             : IN     std_ulogic ;
        dmotSendAuth      : IN     std_ulogic ;
        readRegister      : IN     std_ulogic ;
        reset             : IN     std_ulogic ;
        dmotAddressToSend : OUT    symbolSizeType ;
        dmotDataToSend    : OUT    dataRegisterType ;
        dmotSendRequest   : OUT    std_ulogic 
    );
    END COMPONENT;
    COMPONENT dmotPulseTargetFormatter
    PORT (
        clock         : IN     std_ulogic ;
        reset         : IN     std_ulogic ;
        targetCommand : IN     unsigned (DMOT_TARGETCMD_BIT_NB-1 DOWNTO 0);
        target        : OUT    unsigned (VALUE_BIT_NB-1 DOWNTO 0)
    );
    END COMPONENT;

    -- Optional embedded configurations
    -- pragma synthesis_off
    FOR ALL : dmotMotorRegisterSender USE ENTITY Stepper.dmotMotorRegisterSender;
    FOR ALL : dmotPulseTargetFormatter USE ENTITY Stepper.dmotPulseTargetFormatter;
    FOR ALL : reg_addr_decoder USE ENTITY Kart.reg_addr_decoder;
    FOR ALL : registerManager USE ENTITY Kart.registerManager;
    -- pragma synthesis_on


BEGIN
    -- Architecture concurrent statements
    -- HDL Embedded Text Block 2 eb2
    targetCommand <= resize(unsigned(bankData(DMOT_TARGETANGLE_REG_POS)), targetCommand'length);
    customReg1 <= std_ulogic_vector(bankData(DMOT_CUSTOM1_REG_POS));
    customReg2 <= std_ulogic_vector(bankData(DMOT_CUSTOM2_REG_POS));
    customReg3 <= std_ulogic_vector(bankData(DMOT_CUSTOM3_REG_POS));


    -- Instance port mappings.
    U_decoder : reg_addr_decoder
        GENERIC MAP (
            moduleAddr => REG_DMOT_ADDR
        )
        PORT MAP (
            address      => addressIn,
            wr           => regWr,
            loadRegister => loadRegister,
            readRegister => readRegister
        );
    U_manager : registerManager
        GENERIC MAP (
            registersNb => DMOT_TOT_REG_COUNT
        )
        PORT MAP (
            addressIn => addressIn,
            clock     => clock,
            dataIn    => dataIn,
            loadNew   => loadRegister,
            reset     => reset,
            bankData  => bankData
        );
    U_sender : dmotMotorRegisterSender
        GENERIC MAP (
            registersNb   => DMOT_TOT_REG_COUNT,
            moduleAddr    => REG_DMOT_ADDR,
            inRegistersNb => DMOT_REG_COUNT
        )
        PORT MAP (
            addressIn         => addressIn,
            bankData          => bankData,
            clock             => clock,
            dmotSendAuth      => dmotSendAuth,
            readRegister      => readRegister,
            reset             => reset,
            dmotAddressToSend => dmotAddressToSend,
            dmotDataToSend    => dmotDataToSend,
            dmotSendRequest   => dmotSendRequest
        );
    U_dmotPulseTargetFormatter : dmotPulseTargetFormatter
        PORT MAP (
            clock         => clock,
            reset         => reset,
            targetCommand => targetCommand,
            target        => target
        );

END struct;




-- VHDL Entity Stepper.dmotServoPulseValidator.interface
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 09:21:24 29.04.2026
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

ENTITY dmotServoPulseValidator IS
    PORT( 
        clock          : IN     std_ulogic;
        dirServoRaw    : IN     std_ulogic;
        reset          : IN     std_ulogic;
        directionServo : OUT    std_ulogic
    );

-- Declarations

END dmotServoPulseValidator ;





-- Validate servomotor pulse duration to avoid burning the motor
-- Axam

ARCHITECTURE RTL OF dmotServoPulseValidator IS

  signal lvec_pulse_cnt : unsigned( requiredBitNb(DMOT_MAXCMD_CLOCKS + DMOT_CMD_CLOCKS_STEP) - 1 DOWNTO 0 );
  signal lsig_servo : std_ulogic;

BEGIN

  process(reset, clock)
  begin
    if reset = '1' then
      lvec_pulse_cnt <= (OTHERS => '0');
      lsig_servo <= '0';
    elsif rising_edge(clock) then
      -- Start the count
      if lvec_pulse_cnt = 0 then
        lsig_servo <= '0';
        -- Start pulse
        if pulse = '1' then
          lvec_pulse_cnt <= lvec_pulse_cnt + 1;
          lsig_servo <= '1';
        end if;
      -- Stop if the pulse exceeds the maximum allowed duration
      elsif lvec_pulse_cnt >= DMOT_MAXCMD_CLOCKS then
        lsig_servo <= '0';
        if pulse = '0' then
          lvec_pulse_cnt <= (others => '0');
        end if;
      -- Allows stopping if the minimal time has been reached
      elsif lvec_pulse_cnt >= DMOT_MINCMD_CLOCKS then
          lvec_pulse_cnt <= lvec_pulse_cnt + 1;
          if pulse = '0' then
            lvec_pulse_cnt <= (others => '0');
            lsig_servo <= '0';
          end if;
      -- Counting the minimal pulse
      else
        lvec_pulse_cnt <= lvec_pulse_cnt + 1;
      end if;
    end if;
  end process;

  directionServo <= lsig_servo;

END ARCHITECTURE RTL;




--
-- VHDL Architecture Stepper.dmotMotorController.struct
--
-- Created:
--          by - Axam.UNKNOWN (WE10628)
--          at - 10:58:32 29.04.2026
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

LIBRARY Stepper;

ARCHITECTURE struct OF dmotMotorController IS

    -- Architecture declarations

    -- Internal signal declarations
    SIGNAL customReg1  : std_ulogic_vector(VALUE_BIT_NB-1 DOWNTO 0);
    SIGNAL customReg2  : std_ulogic_vector(VALUE_BIT_NB-1 DOWNTO 0);
    SIGNAL customReg3  : std_ulogic_vector(VALUE_BIT_NB-1 DOWNTO 0);
    SIGNAL dirServoRaw : std_ulogic;
    SIGNAL targetAngle : unsigned(VALUE_BIT_NB-1 DOWNTO 0);


    -- Component Declarations
    COMPONENT directionControl
    PORT (
        clock          : IN     std_uLogic ;
        customReg1     : IN     std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg2     : IN     std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg3     : IN     std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        reset          : IN     std_uLogic ;
        target         : IN     unsigned (VALUE_BIT_NB-1 DOWNTO 0);
        directionServo : OUT    std_ulogic 
    );
    END COMPONENT;
    COMPONENT dmotMotorRegisters
    PORT (
        addressIn         : IN     symbolSizeType ;
        clock             : IN     std_ulogic ;
        dataIn            : IN     dataRegisterType ;
        dmotSendAuth      : IN     std_ulogic ;
        regWr             : IN     std_ulogic ;
        reset             : IN     std_ulogic ;
        customReg1        : OUT    std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg2        : OUT    std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        customReg3        : OUT    std_ulogic_vector (VALUE_BIT_NB-1 DOWNTO 0);
        dmotAddressToSend : OUT    symbolSizeType ;
        dmotDataToSend    : OUT    dataRegisterType ;
        dmotSendRequest   : OUT    std_ulogic ;
        target            : OUT    unsigned (VALUE_BIT_NB-1 DOWNTO 0)
    );
    END COMPONENT;
    COMPONENT dmotServoPulseValidator
    PORT (
        clock          : IN     std_ulogic ;
        dirServoRaw    : IN     std_ulogic ;
        reset          : IN     std_ulogic ;
        directionServo : OUT    std_ulogic 
    );
    END COMPONENT;

    -- Optional embedded configurations
    -- pragma synthesis_off
    FOR ALL : directionControl USE ENTITY Stepper.directionControl;
    FOR ALL : dmotMotorRegisters USE ENTITY Stepper.dmotMotorRegisters;
    FOR ALL : dmotServoPulseValidator USE ENTITY Stepper.dmotServoPulseValidator;
    -- pragma synthesis_on


BEGIN

    -- Instance port mappings.
    I_angleControl : directionControl
        PORT MAP (
            clock          => clock,
            customReg1     => customReg1,
            customReg2     => customReg2,
            customReg3     => customReg3,
            reset          => reset,
            target         => targetAngle,
            directionServo => dirServoRaw
        );
    I_registers : dmotMotorRegisters
        PORT MAP (
            addressIn         => addressIn,
            clock             => clock,
            dataIn            => dataIn,
            dmotSendAuth      => dmotSendAuth,
            regWr             => regWr,
            reset             => reset,
            customReg1        => customReg1,
            customReg2        => customReg2,
            customReg3        => customReg3,
            dmotAddressToSend => dmotAddressToSend,
            dmotDataToSend    => dmotDataToSend,
            dmotSendRequest   => dmotSendRequest,
            target            => targetAngle
        );
    U_dmotServoPulseValidator : dmotServoPulseValidator
        PORT MAP (
            clock          => clock,
            dirServoRaw    => dirServoRaw,
            reset          => reset,
            directionServo => directionServo
        );

END struct;




