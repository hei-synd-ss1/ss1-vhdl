--
-- VHDL Architecture I2C_test.i2cMaster_tester.sim
--
-- Created:
--          by - remy.borgeat.UNKNOWN (WE10993)
--          at - 08:49:24 14.01.2025
--
-- using Mentor Graphics HDL Designer(TM) 2023.4 Built on 6 Oct 2023 at 01:57:26
--
LIBRARY std;
  USE std.textio.ALL;
  use std.env.stop;
LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;
LIBRARY Common_test;
  USE Common_test.testutils.all;

ARCHITECTURE sim OF i2cMasterSlave_tester IS
  
  constant c_CLOCK_PERIOD   : time          := 1.0/real(g_CLOCK_FREQUENCY) * 1 sec;
  signal lsig_clock         : std_ulogic    := '1';
  signal lsig_reset         : std_ulogic ;

  signal lvec_test_info: string(1 to 40) := (others => ' ');
  signal lvec_test_subinfo: string(1 to 40) := (others => ' ');

BEGIN
  ------------------------------------------------------------------------------
  -- reset and clock
  lsig_reset <= '1', '0' after 4*c_CLOCK_PERIOD;
  reset <= lsig_reset;
  
  lsig_clock <= not lsig_clock after c_CLOCK_PERIOD/2;
  clock <= transport lsig_clock after 0.9*c_CLOCK_PERIOD;

  ------------------------------------------------------------------------------
  -- test sequence
  testSequence: process
  begin

    o_master_ncs <= '1';
    o_master_repeated_start <= '0';
    o_master_write_data <= '0'; 
    o_master_data_to_send <= X"00";
    o_master_ack <= '0';
    o_slave_wait <= '0';
    o_slave_data_to_send <= x"00";
    o_slave_address <= to_unsigned(16#42#, o_slave_address'length);
    o_slave_address_10b <= '0';
    o_slave_ack <= '0';
    wait for 10 us;


    lvec_test_info <= pad("Write 2 bytes", lvec_test_info'length);
    lvec_test_subinfo <= pad("Start", lvec_test_subinfo'length);
    -- Start
    o_master_ncs <= '0';
    wait until i_master_request_transaction = '1';
    -- Slave addr
    lvec_test_subinfo <= pad("Slave address - write", lvec_test_subinfo'length);
    o_master_data_to_send <= std_ulogic_vector(o_slave_address(6 downto 0)) & '0';
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_master_request_transaction = '1';
    -- Data 1
    lvec_test_subinfo <= pad("Data 1 - 0xAB", lvec_test_subinfo'length);
    o_slave_ack <= '1';
    o_master_data_to_send <= X"AB";
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_master_request_transaction = '1';
    -- Data 2
    lvec_test_subinfo <= pad("Data 2 - 0xCD", lvec_test_subinfo'length);
    o_master_data_to_send <= X"CD";
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_master_request_transaction = '1';
    -- End
    lvec_test_subinfo <= pad("Stop", lvec_test_subinfo'length);
    o_master_ncs <= '1';
    wait for 50 us;


    lvec_test_info <= pad("Read 2 bytes", lvec_test_info'length);
    lvec_test_subinfo <= pad("Start", lvec_test_subinfo'length);
    -- Start
    o_master_ncs <= '0';
    wait until i_master_request_transaction = '1';
    -- Slave addr   
    lvec_test_subinfo <= pad("Slave address - read", lvec_test_subinfo'length); 
    o_master_data_to_send <= std_ulogic_vector(o_slave_address(6 downto 0)) & '1';
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_slave_new_data = '1';
    lvec_test_subinfo <= pad("Data 1 - 0xAA", lvec_test_subinfo'length);
    o_slave_data_to_send <= x"AA";
    wait until i_master_request_transaction = '1';
    o_master_ack <= '1';
    -- Data 1
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_slave_new_data = '1';
    lvec_test_subinfo <= pad("Data 2 - 0x55", lvec_test_subinfo'length);
    o_slave_data_to_send <= x"55";
    wait until i_master_request_transaction = '1';
    -- Data 2
    o_master_write_data <= '1';
    o_master_ack <= '0'; -- is last data, so NACK
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_master_request_transaction = '1';
    -- End
    lvec_test_subinfo <= pad("Stop", lvec_test_subinfo'length);
    o_master_ncs <= '1';
    wait for 50 us;


    lvec_test_info <= pad("Write command + read 3 bytes", lvec_test_info'length);
    -- Start
    lvec_test_subinfo <= pad("Start", lvec_test_subinfo'length);
    o_master_ncs <= '0';
    wait until i_master_request_transaction = '1';
    -- Slave addr    
    lvec_test_subinfo <= pad("Slave address - write", lvec_test_subinfo'length);
    o_master_data_to_send <= std_ulogic_vector(o_slave_address(6 downto 0)) & '0';
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_master_request_transaction = '1';
    -- Command
    lvec_test_subinfo <= pad("Command - 0x2F", lvec_test_subinfo'length);
    o_master_data_to_send <= x"2F";
    o_slave_ack <= '1';
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_master_request_transaction = '1';
    -- Restart
    lvec_test_subinfo <= pad("Restart", lvec_test_subinfo'length);
    o_master_repeated_start <= '1';
    wait until i_master_request_transaction = '0';
    o_master_repeated_start <= '0';
    wait until i_master_request_transaction = '1';
    -- Slave addr    
    lvec_test_subinfo <= pad("Slave address - read", lvec_test_subinfo'length);
    o_master_data_to_send <= std_ulogic_vector(o_slave_address(6 downto 0)) & '1';
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_slave_new_data = '1';
    lvec_test_subinfo <= pad("Data 1 - 0xAA", lvec_test_subinfo'length);
    o_slave_data_to_send <= x"AA";
    wait until i_master_request_transaction = '1';
    o_master_ack <= '1';
    -- Data 1
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_slave_new_data = '1';
    lvec_test_subinfo <= pad("Data 2 - 0x55", lvec_test_subinfo'length);
    o_slave_data_to_send <= x"55";
    wait until i_master_request_transaction = '1';
    -- Data 2
    o_master_write_data <= '1';
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    wait until i_slave_new_data = '1';
    lvec_test_subinfo <= pad("Data 3 - 0x36", lvec_test_subinfo'length);
    o_slave_data_to_send <= x"36";
    wait until i_master_request_transaction = '1';
    -- Data 2
    o_master_write_data <= '1';
    o_master_ack <= '0'; -- is last data, so NACK
    wait until i_master_request_transaction = '0';
    o_master_write_data <= '0';
    lvec_test_subinfo <= pad("Extra data - should not be sent", lvec_test_subinfo'length);
    o_slave_data_to_send <= x"DD";
    wait until i_master_request_transaction = '1';
    wait for 10 * c_CLOCK_PERIOD; -- wait for the slave to not send data
    assert i_master_request_transaction = '1'
      report "Master should not be doing anything" severity failure;
    -- End
    lvec_test_subinfo <= pad("Stop", lvec_test_subinfo'length);
    o_master_ncs <= '1';
    wait for 50 us;


    lvec_test_info <= pad("Simulation End", lvec_test_info'length);
    lvec_test_subinfo <= pad("Stop communication", lvec_test_subinfo'length);
    o_master_ncs <= '1';
    wait for 20 us;
    lvec_test_subinfo <= pad("End", lvec_test_subinfo'length);
    wait for 50 us;
    stop;



    
    -- lvec_test_info <= pad("Write 1 byte, fail slave ack", lvec_test_info'length);
    -- o_master_write_data <= '1'; 
    -- o_master_data_to_send <= X"AB";
    -- o_master_ncs <= '0';
    -- lsig_master_fail_ack <= '0';
    -- lsig_slave_fail_ack <= '1';
    -- wait until i_master_error = '1';
    -- o_master_ncs <= '1';
    -- wait for 50 us;

    -- lvec_test_info <= pad("Write 3 bytes to slave, clock streching", lvec_test_info'length);
    -- lsig_master_fail_ack <= '0';
    -- lsig_slave_fail_ack <= '0';
    -- o_master_write_data <= '1'; 
    -- o_master_data_to_send <= X"AB";
    -- o_master_ncs <= '0';
    -- wait until i_master_new_data = '1';
    -- wait until i_master_new_data = '0';
    -- o_master_data_to_send <= X"AB";
    -- wait until i_master_new_data = '1';
    -- wait until i_master_new_data = '0';
    -- o_master_data_to_send <= X"CD";
    -- wait for 10 us; 
    -- o_slave_wait <= '1';
    -- wait for 200 us; 
    -- o_slave_wait <= '0';
    -- wait for 5 us; 
    -- o_slave_wait <= '1';
    -- wait for 50 us;
    -- o_slave_wait <= '0';
    -- wait until i_master_new_data = '1';
    -- wait until i_master_new_data = '0';
    -- o_master_data_to_send <= X"EF";
    -- wait until i_slave_request_ack = '1'; 
    -- o_slave_wait <= '1';
    -- wait for 50 us;
    -- o_slave_wait <= '0';
    -- wait until i_master_new_data = '1';   
    -- o_master_ncs <= '1';
    -- wait for 50 us;

    lvec_test_info <= pad("Stop communication ", lvec_test_info'length);
    o_master_ncs <= '1';
    lvec_test_info <= pad("Simulation End", lvec_test_info'length);
    wait for 50 us;
    stop;
  end process testSequence;

END ARCHITECTURE sim;