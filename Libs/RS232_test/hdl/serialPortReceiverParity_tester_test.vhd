--====================================================================--
-- Design units : RS232_test.serialPortReceiverParity_tester.test
--
-- File name : serialPortReceiverParity_tester.vhd
--
-- Purpose :
--
-- Note : This model can be synthesized by Xilinx Vivado.
--
-- Limitations : 
--
-- Errors : 
--
-- Library : RS232_test
--
-- Dependencies : None
--
-- Author : remy.borgeat
-- HES-SO Valais/Wallis
-- Route de l'Industrie 23
-- 1950 Sion
-- Switzerland
--
-- Design tool : HDL Designer 2023.4 Built on 6 Oct 2023 at 01:57:26
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author Date           Changes
-- 1.0            26.11.2024
-- 
-- 
------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

ARCHITECTURE test OF serialPortReceiverParity_tester IS
  -- reset and clock
  constant c_CLOCK_PERIOD: time := (1.0/g_CLOCK_FREQUENCY) * 1 sec;
  signal clock_int: std_uLogic := '1';

  -- RS232 speed
  constant c_RS232_FREQUENCY: real := g_BAUD_RATE;
  constant c_RS232_PERIOD: time := (1.0/c_RS232_FREQUENCY) * 1 sec;

  constant c_DATA_TO_SEND: std_ulogic_vector(7 downto 0) := "10101010";

  signal parityBit: std_ulogic;

  signal dbg_info: string(1 to 24);

BEGIN
  
  ------------------------------------------------------------------------------
  -- reset and clock
  reset <= '1', '0' after 2*c_CLOCK_PERIOD;
  
  clock_int <= not clock_int after c_CLOCK_PERIOD/2;
  clock <= transport clock_int after c_CLOCK_PERIOD*9/10;

  ------------------------------------------------------------------------------
  -- RS232 Rx test
  process
  begin
  
    -- reset 
    RxD <= '1';
    parityBit <= '0';
    wait for 5*c_CLOCK_PERIOD;
    
    ---------------------------------------------------------------------------
    -- Test 1: Send 0xAA successfully
    ---------------------------------------------------------------------------
    dbg_info <= "Send 0xAA successfully  ";
    -- start 
    RxD <= '0';
    wait for c_RS232_PERIOD;

    -- data
    for i in 0 to g_DATA_BIT_NB-1 loop
      RxD <= c_DATA_TO_SEND(i);
      parityBit <= parityBit xor c_DATA_TO_SEND(i);
      wait for c_RS232_PERIOD;
    end loop;

    -- parity
    RxD <= parityBit;
    wait for c_RS232_PERIOD;
    
    -- stop
    RxD <= '1';
    wait for 5*c_RS232_PERIOD;
    
    ---------------------------------------------------------------------------
    -- Test 2: Send 0xAA fail
    ---------------------------------------------------------------------------
    dbg_info <= "Send 0xAA failure       ";
    -- start 
    RxD <= '0';
    wait for c_RS232_PERIOD;

    -- data
    for i in 0 to g_DATA_BIT_NB-1 loop
      RxD <= c_DATA_TO_SEND(i);
      parityBit <= parityBit xor c_DATA_TO_SEND(i);
      wait for c_RS232_PERIOD;
    end loop;

    -- parity
    RxD <= not parityBit;
    wait for c_RS232_PERIOD;
    
    -- stop
    RxD <= '1';
    wait for c_RS232_PERIOD;

    ---------------------------------------------------------------------------
    -- Test 3: Send 0xAA successfully
    ---------------------------------------------------------------------------
    dbg_info <= "Send 0xAA successfully  ";
    -- start 
    RxD <= '0';
    wait for c_RS232_PERIOD;

    -- data
    for i in 0 to g_DATA_BIT_NB-1 loop
      RxD <= c_DATA_TO_SEND(i);
      parityBit <= parityBit xor c_DATA_TO_SEND(i);
      wait for c_RS232_PERIOD;
    end loop;

    -- parity
    RxD <= parityBit;
    wait for c_RS232_PERIOD;
    
    -- stop
    RxD <= '1';
  wait for 5*c_RS232_PERIOD;
    wait;
  end process;


  verify: process(byte, byteError, byteReceived)
  begin

    -- verify case success
    if byteReceived = '1' then
      if byte = c_DATA_TO_SEND then
        report "Test passed" severity note;
      else
        report "Test failed" severity error;
      end if;
    end if;

    -- verify case parity failure
    if byteError = '1' then
      if byte = c_DATA_TO_SEND then
        report "Test passed" severity note;
      else
        report "Test failed" severity error;
      end if;
    end if;

  end process verify;
END ARCHITECTURE test;