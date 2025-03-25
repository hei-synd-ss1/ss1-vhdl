--
-- VHDL Architecture I2C.i2cSlaveController.rtl
--
-- Created:
--          by - remy.borgeat.UNKNOWN (WE10993)
--          at - 14:51:20 14.01.2025
--
-- using Mentor Graphics HDL Designer(TM) 2023.4 Built on 6 Oct 2023 at 01:57:26
--
ARCHITECTURE rtl OF i2cSlaveController IS

  type t_state_type is (
    ST_IDLE,
    ST_GET_BYTE,
    ST_ACK_PREPARE,
    ST_ACK_SEND,
    ST_ACK_WAIT,
    ST_SEND_DATA_DONE,
    ST_SEND_DATA,
    ST_SEND_DATA_WAIT,
    ST_SEND_DATA_WAIT_BUSY,
    ST_READ,
    ST_WAIT_STOP,
    ST_END, 
    ST_ERROR
  );

  signal lvec_state : t_state_type;
  signal lsig_scl_delayed : std_logic;
  signal lvec_data_received : std_ulogic_vector(g_DATA_BIT_NB-1 DOWNTO 0);
  signal lsig_sending_ack : std_ulogic;
  signal lsig_start_condition, lsig_stop_condition : std_ulogic;
  signal lsig_ack_to_send : std_ulogic;
  signal lsig_sending_ack_end : std_ulogic;
  signal lvec_i_data_reg : std_ulogic_vector(g_DATA_BIT_NB-1 downto 0);

BEGIN

  ------------------------------------------------------------------------
  -- state_machine:
  -- The process implements the state machine of the I2C slave controller
  ------------------------------------------------------------------------
  state_machine: process(clock, reset)
  begin
    if reset = '1' then 
      lvec_state <= ST_IDLE;
      lvec_data_received <= (others => '0');
    elsif rising_edge(clock) then 
      case lvec_state is

        when ST_IDLE => 
          if lsig_start_condition = '1' then -- start received
            lvec_state <= ST_GET_BYTE;
          end if;
        
        -- get the first byte
        when ST_GET_BYTE =>
          if lsig_stop_condition = '1' then
            -- stop bit received --> end
            lvec_state <= ST_END;
          elsif i_data_valid = '1' then 
            lvec_data_received <= i_data_received(lvec_data_received'range);
            lvec_state <= ST_ACK_PREPARE;
          end if;

        -- ask sensor for acknoledgement
        when ST_ACK_PREPARE =>
          if lsig_stop_condition = '1' then
            -- stop bit received --> end
            lvec_state <= ST_END;
          else
            lvec_state <= ST_ACK_SEND; 
          end if;

        -- send ack
        when ST_ACK_SEND =>
          if lsig_stop_condition = '1' then
            -- stop bit received --> end
            lvec_state <= ST_END;
          else
            lvec_state <= ST_ACK_WAIT; 
          end if;

        -- wait ack sent
        when ST_ACK_WAIT => 
          if lsig_stop_condition = '1' then
            -- stop bit received --> end
            lvec_state <= ST_END;
          else
            if lsig_sending_ack_end = '1' then -- wait for ack to be sent
              if i_we = '1' then 
                lvec_state <= ST_SEND_DATA_DONE;
              else 
                lvec_state <= ST_READ;
              end if; 
            end if;
          end if;

        -- send data
        when ST_SEND_DATA =>
          lvec_i_data_reg <= i_data;
          if(lsig_stop_condition = '1') then
            -- stop bit received --> end
            lvec_state <= ST_END;
          else 
            lvec_state <= ST_SEND_DATA_WAIT;
          end if; 

        -- wait for data to be sent
        when ST_SEND_DATA_WAIT => 
          if(lsig_stop_condition = '1') then 
            -- stop bit received --> end
            lvec_state <= ST_END;
          elsif i_ack_bit = '1' and i_data_valid = '1' and (i_data_received(i_data'range) = lvec_i_data_reg) then
            lvec_state <= ST_SEND_DATA_WAIT_BUSY;
          elsif (i_ack_bit = '0' and i_data_valid = '1') then -- end of read
            lvec_state <= ST_WAIT_STOP;
          elsif (i_data_received(i_data'range) /= lvec_i_data_reg) and (i_data_valid = '1') then
            lvec_state <= ST_ERROR; -- incorrect data send
          end if;
        
        -- write finished
        when ST_SEND_DATA_WAIT_BUSY => 
          if(lsig_stop_condition = '1') then
            -- stop bit received --> end
            lvec_state <= ST_END;
          elsif i_busy = '0' then 
            -- continue to send byte
            lvec_state <= ST_SEND_DATA_DONE;
          end if;

          -- data sent
        when ST_SEND_DATA_DONE =>
          if(lsig_stop_condition = '1') then 
            -- stop bit received --> end
            lvec_state <= ST_END;
          else
            lvec_state <= ST_SEND_DATA;
          end if;

        -- read data
        when ST_READ =>
          if lsig_stop_condition = '1' then
            -- stop bit received --> end
            lvec_state <= ST_END;
          elsif i_data_valid = '1' and lsig_start_condition = '0' then
            -- new data received --> send ack
            lvec_data_received <= i_data_received(lvec_data_received'range);
            lvec_state <= ST_ACK_PREPARE;
          end if;

        -- wait for stop bit, when no more data to send
        when ST_WAIT_STOP => 
          if lsig_stop_condition = '1' then 
            lvec_state <= ST_END;
          end if;

        when ST_ERROR => 
          lvec_state <= ST_IDLE;
        
        -- end of communication 
        when ST_END => 
          lvec_state <= ST_IDLE;
        
        -- error occurred
        when others => 
          lvec_state <= ST_END;

      end case;
    end if;
  end process state_machine; 
  
  o_wait <= '1' when lvec_state /= ST_IDLE and i_wait = '1' else '0';
  lsig_stop_condition <= '1' when i_data_valid = '1' and  i_stop_received = '1' else '0';
  lsig_start_condition <= '1' when i_data_valid = '1' and i_start_received = '1' else '0';
  
  --------------------------------------------------------------------
  -- state_machine_output:
  -- generate the state machine outputs
  --------------------------------------------------------------------
  state_machine_output: process(lvec_state, lvec_data_received, lsig_start_condition, lsig_stop_condition)
  begin
    o_data_to_send <= (others => '0');
    o_data <= (others => '0');
    o_request_ack <= '0';
    o_request_new_data <= '0';
    o_send <= '0';
    o_is_transmitting <= '0';
    o_transfer_done <= '0';
    o_error <= '0';
    o_repeated_start <= '0'; 

    case lvec_state is 
      
      when ST_ACK_PREPARE => 
        o_data <= lvec_data_received;
        o_request_ack <= '1';

      when ST_SEND_DATA_DONE => 
        o_request_new_data <= '1';
        o_is_transmitting <= '1';
      
      when ST_READ => 
        o_repeated_start <= lsig_start_condition;
      
      when ST_SEND_DATA =>
        if lsig_stop_condition = '0' then 
          o_send <= '1';
          -- Send data
          o_data_to_send <= i_data; 
          o_is_transmitting <= '1';
        end if; 
    
      when ST_SEND_DATA_WAIT | ST_SEND_DATA_WAIT_BUSY => 
        o_is_transmitting <= '1';

      when ST_END => 
        o_transfer_done <= '1';
      
      when ST_ERROR => 
        o_error <= '1';
      
      when others =>
        NULL;
    end case;
  end process state_machine_output;

  --------------------------------------------------------------------
  -- Acknowledge generation
  --------------------------------------------------------------------
  ack_generation : process(clock, reset)
  begin
    if reset = '1' then
      o_ack <= '1';
      lsig_sending_ack <= '0';
      lsig_ack_to_send <= '0';
      lsig_sending_ack_end <= '0';
      lsig_scl_delayed <= '0';
    elsif rising_edge(clock) then
      lsig_scl_delayed <= i_scl;
      lsig_sending_ack_end <= '0';

      if lvec_state = ST_ACK_SEND then     
        lsig_ack_to_send <= i_ack; -- send ack
      elsif lvec_state = ST_ACK_WAIT then 
        if lsig_scl_delayed = '1' and i_scl = '0' then --on falling edge of scl
          if lsig_sending_ack = '1' then 
            o_ack <= '1'; -- next falling edge of scl, release SDA line
            lsig_sending_ack <= '0';
            lsig_sending_ack_end <= '1';
            lsig_ack_to_send <= '0';
          else 
            o_ack <= not lsig_ack_to_send; -- next falling edge of scl, hold SDA line
            lsig_sending_ack <= '1';
          end if;
        end if;
      else 
        o_ack <= '1';
        lsig_sending_ack <= '0';
        lsig_ack_to_send <= '0';
        lsig_sending_ack_end <= '0';
        lsig_scl_delayed <= '0';
      end if;
    end if;
  end process ack_generation;

END ARCHITECTURE rtl;

