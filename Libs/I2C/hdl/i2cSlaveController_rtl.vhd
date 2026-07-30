--====================================================================--
-- Design units : I2C.i2cSlaveController.RTL
--
-- File name : i2cSlaveController_RTL.vhd
--
-- Purpose : Manages I2C transmitter and receiver in a slave mode.
--
-- Library : I2C
--
-- Dependencies : None
--
-- Author : Axam
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
-- 1.1     AMA    26.05.2025     Transaction state support. 10B addr. support.
-- 1.0     BOY
-- 
-- 
------------------------------------------------

ARCHITECTURE RTL OF i2cSlaveController IS

  type slave_state_t is (
    ST_IDLE, ST_7B_ADDR, ST_10B_ADDR_HIGH, ST_10B_ADDR_LOW, ST_GET, ST_PUT
  );
  signal lvec_state : slave_state_t;

  signal lsig_data_received_old : std_ulogic;

  signal lvec_sent_data : std_ulogic_vector(7 downto 0);
  signal lsig_request_ack_old : std_ulogic;
  signal lvec_addr : std_ulogic_vector(9 downto 0);
  signal lsig_addr_10b_ok : std_ulogic;
  signal lsig_send_data : std_ulogic;

BEGIN

  proc_state_machine: process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      lvec_state <= ST_IDLE;
      o_transfer_done <= '0';
      o_repeated_start <= '0';
      o_ack_request <= '0';
      lsig_request_ack_old <= '0';
      o_tr_wait <= '0';
      o_tr_send_ack <= '0';
      o_err_sent_corrupted <= '0';
      lvec_sent_data <= (others => '0');
      o_tr_send <= '0';
      o_tr_ack <= '0';
      lsig_addr_10b_ok <= '0';
      lvec_addr <= (others => '0');
      lsig_data_received_old <= '0';
      o_data_received <= '0';
      o_data_request <= '0';
      o_rec_slave_write <= '0';
      lsig_send_data <= '0';
    elsif rising_edge(i_clk) then
      o_transfer_done <= '0';
      o_repeated_start <= '0';
      o_ack_request <= '0';
      lsig_request_ack_old <= o_ack_request;
      o_tr_wait <= '0';
      o_tr_send_ack <= '0';
      o_err_sent_corrupted <= '0';
      o_tr_send <= '0';
      lsig_data_received_old <= i_rec_data_received;
      o_data_received <= '0';
      o_data_request <= '0';

      case lvec_state is

        when ST_IDLE =>
          if i_rec_start_restart = '1' or o_repeated_start = '1' then
            lvec_state <= ST_GET;
            lvec_addr <= std_ulogic_vector(i_address);
            -- Slave receive configuration
            o_rec_slave_write <= '0';
            o_tr_ack <= '1';
            lsig_send_data <= '0';
            if i_address_is10b = '1' then
              lvec_state <= ST_10B_ADDR_HIGH;
              lsig_addr_10b_ok <= '0';
            else
              lvec_state <= ST_7B_ADDR;
            end if;
          end if;


        when ST_7B_ADDR =>
          -- Stop condition
          if i_rec_stop = '1' then
            lvec_state <= ST_IDLE;
          end if;

          -- Check addr
          if lsig_data_received_old = '1' then
            if i_rec_data(7 downto 1) = lvec_addr(6 downto 0) then
              -- Read mode, no ack
              if i_rec_data(0) = '1' then
                lvec_state <= ST_PUT;
                -- Slave transmit configuration
                o_rec_slave_write <= '1';
                o_data_request <= '1';
                lsig_send_data <= '1';
              -- Next data are write until restart
              else
                lvec_state <= ST_GET;
              end if;
              o_tr_send_ack <= '1'; -- ACK the slave address
            else
              -- Address does not match, go back to idle state
              lvec_state <= ST_IDLE;
            end if;
          end if;


        when ST_10B_ADDR_HIGH =>
          -- Stop condition
          if i_rec_stop = '1' then
            lvec_state <= ST_IDLE;
          end if;

          if lsig_data_received_old = '1' then
            -- First half of 10-bit address received
            if i_rec_data(7 downto 1) = ("11110" & lvec_addr(9 downto 8)) then
              if lsig_addr_10b_ok = '1' then
                -- Read mode, no ack
                if i_rec_data(0) = '1' then
                  lvec_state <= ST_PUT;
                  -- Slave transmit configuration
                  o_rec_slave_write <= '1';
                  o_data_request <= '1';
                  lsig_send_data <= '1';
                -- Next data are write until restart
                else
                  lvec_state <= ST_GET;
                end if;
                o_tr_send_ack <= '1'; -- ACK the slave address
              elsif i_rec_data(0) = '0' then
                lvec_state <= ST_10B_ADDR_LOW;
                o_tr_send_ack <= '1';
              else
                -- Address does not match, go back to idle state
                lvec_state <= ST_IDLE;
              end if;
            else
              -- Address does not match, go back to idle state
              lvec_state <= ST_IDLE;
            end if; -- Check if we have a 10-bit address
          end if; -- lsig_data_received_old = '1'


        when ST_10B_ADDR_LOW =>
          -- Stop condition
          if i_rec_stop = '1' then
            lvec_state <= ST_IDLE;
          end if;

          if lsig_data_received_old = '1' then
            -- Second half of 10-bit address received
            if i_rec_data = lvec_addr(7 downto 0) then
              -- We have a 10-bit address, go to mode check
              lvec_state <= ST_10B_ADDR_HIGH;
              o_tr_send_ack <= '1';
              lsig_addr_10b_ok <= '1';
            else
              -- Address does not match, go back to idle state
              lvec_state <= ST_IDLE;
            end if; -- Check if we have a 10-bit address
          end if; -- lsig_data_received_old = '1'


        when ST_GET =>
          -- Stop condition
          if i_rec_stop = '1' then
            lvec_state <= ST_IDLE;
            o_transfer_done <= '1';
          end if;

          -- Forward restart condition
          if i_rec_start_restart = '1' then
            o_repeated_start <= '1';
            lvec_state <= ST_IDLE;
          end if;

          -- Request ack
          if i_rec_data_received = '1' then
            o_ack_request <= '1';
            o_data_received <= '1';
          end if;

          -- When ACK asked, send it
          if lsig_request_ack_old = '1' then
            o_tr_ack <= i_ack;
            o_tr_send_ack <= '1';
          end if;

          -- Forward wait request
          o_tr_wait <= i_wait;

        when ST_PUT =>
          -- Stop condition
          if i_rec_stop = '1' then
            lvec_state <= ST_IDLE;
            o_transfer_done <= '1';
          end if;

          -- Data received w. ACK
          if i_rec_data_received = '1' then
            -- Check for last transmission error, except if we have not sent data yet
            if i_rec_data /= lvec_sent_data then
              o_err_sent_corrupted <= '1';
            end if;
            -- Ask new data if needed
            if i_rec_ack = '0' then
              o_data_request <= '1';
              lsig_send_data <= '1';
            end if;
          end if;

          -- Forward data to send
          if lsig_send_data = '1' and i_rec_busy_receiving = '0' and i_tr_busy = '0' then
            o_tr_send <= '1';
            lsig_send_data <= '0';
            lvec_sent_data <= i_rec_data;
          end if;

          -- Forward wait request
          o_tr_wait <= i_wait;


        when others => lvec_state <= ST_IDLE;

      end case;
    end if;
  end process proc_state_machine;

  o_data <= i_rec_data;
  o_tr_data_to_send <= i_data;
  o_frame_ack <= i_rec_ack;

END ARCHITECTURE RTL;
