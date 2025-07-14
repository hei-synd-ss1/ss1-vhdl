--====================================================================--
-- Design units : RS232_test.serialPortTransmitterParity_tester.test
--
-- File name : serialPortTransmitterParity_tester.vhd
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
-- Design tool : HDL Designer 2019.2 (Build 5)
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author Date           Changes
-- 1.0            02.12.2024
-- 
-- 
------------------------------------------------
ARCHITECTURE test OF serialPortTransmitterParity_tester IS
  -- reset and clock
  constant c_CLOCK_PERIOD: time := (1.0/g_CLOCK_FREQUENCY) * 1 sec;
  signal lsig_clock_int: std_uLogic := '1';
                                                                      -- Tx test
  constant c_RS232_FREQUENCY: real := g_BAUD_RATE;
  constant c_RS232_PERIOD: time := (1.0/c_RS232_FREQUENCY) * 1 sec;
  constant c_RS232_WRITE_INTERVAL: time := 20*c_RS232_PERIOD;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  reset <= '1', '0' after 2*c_CLOCK_PERIOD;

  lsig_clock_int <= not lsig_clock_int after c_CLOCK_PERIOD/2;
  clock <= transport lsig_clock_int after c_CLOCK_PERIOD*9/10;

  ------------------------------------------------------------------------------
                                                                      -- Tx test
  process
  begin

    o_data <= (others => '0');
    o_send <= '0';
    wait for c_RS232_PERIOD;

    for index in 0 to 2**g_DATA_BIT_NB-1 loop
      o_data <= std_ulogic_vector(to_unsigned(index, o_data'length));
      wait until rising_edge(lsig_clock_int);
      o_send <= '1';
      wait until rising_edge(lsig_clock_int);
      o_send <= '0';
      wait for c_RS232_WRITE_INTERVAL;
    end loop;
    
    wait;

  end process;

  
  ------------------------------------------------------------------------------
                                                              -- Tx Verification

  verif_tx: process(byteReceived)

  begin
    if byteReceived = '1' then
      if o_data = byte then
        report "Tx test passed" severity note;
      else
        report "Tx test failed" severity error;
      end if;

      if byteError = '1' then
        report "Tx test failed" severity error;
      end if;
  
    end if;
  end process verif_tx;
END ARCHITECTURE test;

