--
-- VHDL Architecture I2C.i2cMasterController.rtl
--
-- Created:
--          by - remy.borgeat.UNKNOWN (WE10993)
--          at - 11:07:38 13.01.2025
--
-- using Mentor Graphics HDL Designer(TM) 2023.4 Built on 6 Oct 2023 at 01:57:26
--
ARCHITECTURE rtl OF i2cMasterController IS

  -- type definition
  type state_type is (
    ST_IDLE,
    ST_SEND_START,
    ST_SEND_START_WAIT, 
    ST_SEND_DATA,
    ST_SEND_DATA_WAIT,
    ST_SEND_DATA_WAIT_BUSY,
    ST_SEND_DATA_DONE,
    ST_READ_DATA,
    ST_READ_DATA_WAIT,
    ST_ACK_PREPARE,
    ST_ACK_SEND,
    ST_ACK_WAIT,
    ST_READ_WAIT_BUSY,
    ST_READ_DATA_DONE,
    ST_STOP,
    ST_STOP_WAIT,  
    ST_ERROR
    );

  -- local signals
  signal lvec_state : state_type;
  signal lsig_scl_delayed : std_ulogic;
  signal lsig_sending_ack : std_ulogic;
  signal lsig_ack_to_send : std_ulogic;
  signal lsig_sending_ack_end : std_ulogic;
  signal lvec_data_received : std_logic_vector(g_DATA_BIT_NB-1 downto 0);
  signal lvec_i_data_reg : std_ulogic_vector(g_DATA_BIT_NB-1 downto 0);

BEGIN

  -------------------------------------------------------------------------
  -- p_state_machine:
  -- The process implements the state machine of the I2C master controller
  -------------------------------------------------------------------------
  p_state_machine: process(reset, clock)
  begin
    if reset = '1' then
      lvec_state <= ST_IDLE;
    else
      if rising_edge(clock) then
        case lvec_state is
          -- idle state.
          when ST_IDLE =>
            if i_ncs = '0' then
              lvec_state <= ST_SEND_START;
            end if;
          
          -- send start condition
          when ST_SEND_START =>
            lvec_state <= ST_SEND_START_WAIT;
          
          -- wait for the start condition to be sent
          when ST_SEND_START_WAIT =>
            if i_busy = '0' then
                lvec_state <= ST_SEND_DATA;
            end if;
          
          -- send data
          when ST_SEND_DATA =>
            lvec_i_data_reg <= i_data;
            if i_ncs = '0' then
              if i_repeated_start = '1' then 
                lvec_state <= ST_SEND_START;
              else
                lvec_state <= ST_SEND_DATA_WAIT;
              end if; 
            else 
              lvec_state <= ST_STOP;
            end if;

          -- wait for the data to be sent
          when ST_SEND_DATA_WAIT =>
            if i_ack_bit = '1' and i_data_valid = '1' and (i_data_received = lvec_i_data_reg) then
              lvec_state <= ST_SEND_DATA_WAIT_BUSY;
            elsif ((i_ack_bit = '0' or (i_data_received/= lvec_i_data_reg)) and i_data_valid = '1') then -- data received /= data sent or NACK
              lvec_state <= ST_ERROR; --acknowledge failure 
            end if;

          -- wait for the data to be sent
          when ST_SEND_DATA_WAIT_BUSY =>
            if i_busy = '0' then
              lvec_state <= ST_SEND_DATA_DONE;
            end if;

          -- data sent
          when ST_SEND_DATA_DONE =>
            if i_we = '1' then
              -- send data
              lvec_state <= ST_SEND_DATA;
            else
              -- read data
              lvec_state <= ST_READ_DATA;
            end if;
          
          -- read data
          when ST_READ_DATA =>
            if i_ncs = '0' then
              lvec_state <= ST_READ_DATA_WAIT;
            else
              lvec_state <= ST_STOP;
            end if; 

          -- wait for the data to be read
          when ST_READ_DATA_WAIT =>
            if i_data_valid = '1' then
              lvec_data_received <= i_data_received;
              lvec_state <= ST_ACK_PREPARE; 
            end if;
        
          -- prepare to send ack
          when ST_ACK_PREPARE => 
            lvec_state <= ST_ACK_SEND; 
        
          -- send ack
          when ST_ACK_SEND =>
            lvec_state <= ST_ACK_WAIT;

          -- wait for ack to be sent
          when ST_ACK_WAIT => 
            if lsig_sending_ack_end = '1' then
              if lsig_ack_to_send = '0' then
                lvec_state <= ST_STOP;
              else
                if i_ncs = '0' then 
                  lvec_state <= ST_READ_WAIT_BUSY;
                else
                  lvec_state <= ST_STOP;
                end if;
              end if;
            end if;
          
          -- wait for the data to be read
          when ST_READ_WAIT_BUSY =>
            if i_busy = '0' and i_ncs = '0' then
              lvec_state <= ST_READ_DATA_DONE;
            elsif i_ncs = '1' then
              lvec_state <= ST_STOP;
            end if; 
          
          -- data read
          when ST_READ_DATA_DONE => 
            if i_ncs = '0' then 
              lvec_state <= ST_READ_DATA;
            else
              lvec_state <= ST_STOP;
            end if;
          
          -- stop condition
          when ST_STOP =>
            lvec_state <= ST_STOP_WAIT;
          
          -- wait for the stop condition to be sent
          when ST_STOP_WAIT => 
            if i_busy = '0' then
              lvec_state <= ST_IDLE;
            end if;

          -- error state
          when ST_ERROR =>
            lvec_state <= ST_STOP;
          
          when others =>
            lvec_state <= ST_ERROR;
        end case;
      end if;
    end if;
  end process p_state_machine;

  --------------------------------------------------------------------
  -- p_state_machine_output:
  -- The process generates the output signals of the state machine
  --------------------------------------------------------------------
  p_state_machine_output: process (lvec_state, i_data, lvec_data_received) 
  begin
    o_data_to_send <= (others => '0');
    o_data <= (others => '0');
    o_request_ack <= '0';
    o_send_data <= '0';
    o_request_new_data <= '0';
    o_is_transmitting <= '0';
    o_error <= '0';
    o_send_start <= '0';
    o_send_stop <= '0';
    case lvec_state is
      
      -- send start condition
      when ST_SEND_START =>
        o_send_start <= '1';
        o_send_data <= '1';
        -- indicates to the receiver, that we are transmitting (read ack).
        o_is_transmitting <= '1';
        
      -- send data
      when ST_SEND_DATA =>
        o_data_to_send <= i_data; -- slave must acknowledge
        o_send_data <= '1';
        -- indicates to the receiver, that we are transmitting (read ack).
        o_is_transmitting <= '1';

      -- wait for the data to be sent
      when ST_SEND_DATA_WAIT =>
        -- indicates to the receiver, that we are transmitting (read ack).
        o_is_transmitting <= '1';

      -- send data done
      when ST_SEND_DATA_DONE =>
        -- indicates to the master device that the data has been sent.
        o_request_new_data <= '1';

      -- read data. 
      when ST_READ_DATA =>
        -- Transmitter will generate the SCL and transmitt 0xFF (slave will reply)
        o_data_to_send <= x"FF";
        o_send_data <= '1';

      -- prepare to send ack
      when ST_ACK_PREPARE =>
        -- send received data to master device
        o_data <= lvec_data_received;
        -- indicates to the master device that he must acknowledge the data.
        o_request_ack <= '1';

      -- indicates to the master device that the data has been read.      
      when ST_READ_DATA_DONE =>
        o_request_new_data <= '1';

      -- send stop condition
      when ST_STOP =>
        o_send_stop <= '1'; 
        o_send_data <= '1';

      -- error occurred 
      when ST_ERROR =>
        o_error <= '1';
      
      -- error occurred
      when others => 
        NULL; 
    end case;
  end process p_state_machine_output;

  --------------------------------------------------------------------
  -- ackGeneration:
  -- The process generates the ack signal to be sent to the slave
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

