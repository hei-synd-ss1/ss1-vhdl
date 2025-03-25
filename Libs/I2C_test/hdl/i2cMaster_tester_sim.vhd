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

ARCHITECTURE sim OF i2cMaster_tester IS
  
  constant c_CLOCK_PERIOD   : time          := 1.0/real(g_CLOCK_FREQUENCY) * 1 sec;
  signal lsig_clock         : std_ulogic    := '1';
  signal lsig_reset         : std_ulogic ;

  -- I2C Slave lsig_state machine
  type t_state_type is (
    ST_IDLE,
    ST_WRITE,
    ST_READ
  ); 

  signal lsig_state : t_state_type;
  signal lsig_test_info: string(1 to 40) := (others => ' ');
  signal lsig_master_fail_ack : std_ulogic;
  signal lsig_slave_fail_ack : std_ulogic;


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

    o_master_data_to_send <= X"00";
    o_master_ncs <= '1';
    o_master_write_data <= '1'; 
    lsig_master_fail_ack <= '0';
    lsig_slave_fail_ack <= '0';
    o_slave_wait <= '0';
    o_master_repeated_start <= '0';
    wait for 10 us;

    lsig_test_info <= pad("Write 1 byte to slave", lsig_test_info'length);
    o_master_data_to_send <= X"AB";
    o_master_ncs <= '0';
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"CD";
    wait until i_master_new_data = '1';
    o_master_ncs <= '1';
    wait for 50 us;

    lsig_test_info <= pad("Read 2 bytes from slave", lsig_test_info'length);
    o_master_data_to_send <= X"AA";
    o_master_ncs <= '0';
    o_master_write_data <= '0'; 
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    lsig_master_fail_ack <= '1';
    wait until i_slave_transfer_done = '1';
    o_master_ncs <= '1';
    lsig_master_fail_ack <= '0';
    wait for 10 us;

    lsig_test_info <= pad("Write 3 bytes to slave", lsig_test_info'length);
    o_master_write_data <= '1'; 
    o_master_data_to_send <= X"AB";
    o_master_ncs <= '0';
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"AB";
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"CD";
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"EF";
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_ncs <= '1';
    wait for 50 us;

    lsig_test_info <= pad("Read 1 byte", lsig_test_info'length);
    o_master_data_to_send <= X"AA";
    o_master_ncs <= '0';
    o_master_write_data <= '0'; 
    lsig_master_fail_ack <= '1';
    wait until i_slave_transfer_done = '1';
    lsig_slave_fail_ack <= '0';
    o_master_ncs <= '1';
    wait for 50 us;

    lsig_test_info <= pad("Write 1 byte, fail slave ack", lsig_test_info'length);
    o_master_write_data <= '1'; 
    o_master_data_to_send <= X"AB";
    o_master_ncs <= '0';
    lsig_master_fail_ack <= '0';
    lsig_slave_fail_ack <= '1';
    wait until i_master_error = '1';
    o_master_ncs <= '1';
    wait for 50 us;

    lsig_test_info <= pad("Write 3 bytes to slave, clock streching", lsig_test_info'length);
    lsig_master_fail_ack <= '0';
    lsig_slave_fail_ack <= '0';
    o_master_write_data <= '1'; 
    o_master_data_to_send <= X"AB";
    o_master_ncs <= '0';
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"AB";
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"CD";
    wait for 10 us; 
    o_slave_wait <= '1';
    wait for 200 us; 
    o_slave_wait <= '0';
    wait for 5 us; 
    o_slave_wait <= '1';
    wait for 50 us;
    o_slave_wait <= '0';
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"EF";
    wait until i_slave_request_ack = '1'; 
    o_slave_wait <= '1';
    wait for 50 us;
    o_slave_wait <= '0';
    wait until i_master_new_data = '1';   
    o_master_ncs <= '1';
    wait for 50 us;

    
    -- write data to slave
    lsig_test_info <= pad("Write 1 byte, read 1 byte with repeated start", lsig_test_info'length);
    o_master_data_to_send <= X"AB";
    o_master_ncs <= '0';
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"CD";
    wait until i_master_new_data = '1';
    wait until i_master_new_data = '0';
    o_master_data_to_send <= X"AA";
    o_master_repeated_start <= '1';
    wait for c_CLOCK_PERIOD; 
    o_master_repeated_start <= '0';
    o_master_ncs <= '0';
    o_master_write_data <= '0'; 
    lsig_master_fail_ack <= '1';
    wait until i_slave_transfer_done = '1';
    o_master_ncs <= '1';
    wait for 50 us;

    lsig_test_info <= pad("Stop communication ", lsig_test_info'length);
    o_master_ncs <= '1';
    lsig_test_info <= pad("Simulation End", lsig_test_info'length);
    wait for 50 us;
    stop;
  end process testSequence;

  -- i2c slave 
  process(clock, reset)
  begin 
    if reset = '1' then
      o_slave_ack <= '0';
      lsig_state <= ST_IDLE;
      o_slave_data_to_send <= (others => '0');
      o_slave_write_mode <= '0';
    elsif rising_edge(clock) then
      o_slave_ack <= '0';
      case lsig_state is
        when ST_IDLE => 
          if i_slave_request_ack = '1' then
            if lsig_slave_fail_ack = '1' then 
              o_slave_ack <= '0';
            else 
              o_slave_ack <= '1';
            end if;
            if i_slave_data_received(0) = '1' then 
              o_slave_write_mode <= '0';
              lsig_state <= ST_READ;
            else
              o_slave_write_mode <= '1';
              lsig_state <= ST_WRITE;
            end if; 
          end if; 

        when ST_WRITE => 
          if i_slave_transfer_done = '1' then 
            lsig_state <= ST_IDLE;
          elsif i_slave_new_data = '1' then 
            o_slave_data_to_send <= x"AE";
          end if; 

        when ST_READ => 
          o_slave_ack <= '0'; 
          lsig_state <= ST_IDLE;
  
        when others => 
          lsig_state <= ST_IDLE;
      end case;
    end if;
  end process;

  -- i2c master 
  process(clock, reset)
  begin
    if reset = '1' then
      o_master_ack <= '0';
    elsif rising_edge(clock) then 
      o_master_ack <= '0';
      if i_master_request_ack = '1' then 
        if lsig_master_fail_ack = '1' then 
          o_master_ack <= '0';
        else 
          o_master_ack <= '1';
        end if;
      end if; 
    end if; 
  end process; 
END ARCHITECTURE sim;