--====================================================================--
-- Design units : I2C.i2cMasterController.RTL
--
-- File name : i2cMasterController.vhd
--
-- Purpose : A single master controller for I2C bus, handling standard/fast modes.
--           System is data agnostic and works as follows:
--           1. Waits for the bus to be asserted (i_ncs = '0').
--           2. Sends start condition.
--           3. Request data/restart/stop through o_request_transaction. Master can stop by releasing i_ncs, restart by asserting i_repeat_start, or send/read data by asserting i_send_data.
--           4. If sending, the first byte must correspond to address. It sends it and detect the 10bits scheme if corresponds to "11110xx".
--           4bis. If 10bits address, request 2nd byte to send even if R/W was set to read.
--           5. Handler can now either send/read data based on the previous R/W bit by asserting i_send_data (will send 0xFF for reads instead of taking i_data). It can also stop the transaction by asserting i_send_stop. Or send a restart by asserting i_repeat_start and next byte is read as address and R/W checked to determine if following data are sent or read. For 10b mode, only the first byte must be sent again.
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
-- 1.1     AMA    02.06.2025     Transaction state support. 10B addr. support.
-- 1.0     BOY
-- 
-- 
------------------------------------------------

ARCHITECTURE RTL OF i2cMasterController IS

  type state_type is (
    ST_IDLE,

    ST_SEND_START,
    ST_SEND_START_WAIT, 

    ST_BUSOWNED_IDLE,

    ST_SEND_DATA,
    ST_SEND_DATA_WAIT_VALID,
    ST_SEND_DATA_WAIT_BUSY,
    
    ST_SEND_STOP,
    ST_SEND_STOP_WAIT,

    ST_READ_DATA_WAIT_VALID,
    ST_READ_DATA_FWD_ACK,
    ST_READ_DATA_WAIT_BUSY,

    ST_ERROR
    );
  signal lvec_state : state_type;

  -- To handle I2C transaction phase
  type transactionState_t is (
    -- ST_TRANS_IDLE, no need, not checking state when bus not asserted
    -- ST_TRANS_STARTED, no need, is started when entering ST_BUSOWNED_IDLE
    ST_TRANS_ADDR, ST_TRANS_ADDR10BL, ST_TRANS_IN_TRANSACTION
  );
  signal lvec_transaction_state : transactionState_t;
  -- If address asked for read or write mode
  signal lsig_rw_mode : std_ulogic;
  -- Indicate if we just had a start or restart signal
  signal lsig_start_restart : std_ulogic;

BEGIN

  p_state_machine: process(i_rst, i_clk)
  begin
    if i_rst = '1' then
      lvec_state <= ST_IDLE;
      o_rec_slave_write <= '0';
      o_request_transaction <= '0';
      o_tr_send_start <= '0';
      o_tr_send_stop <= '0';
      lvec_transaction_state <= ST_TRANS_ADDR;
      o_error <= '0';
      lsig_rw_mode <= '0';
      lsig_start_restart <= '0';
      o_tr_send_data <= '0';
      o_tr_data_to_send <= (others => '0');
      o_data <= (others => '0');
      o_data_rec_ack_request <= '0';
      o_tr_ack <= '0';
      o_data_received <= '0';
    elsif rising_edge(i_clk) then
      o_tr_send_start <= '0';
      o_tr_send_stop <= '0';
      o_tr_send_data <= '0';
      o_request_transaction <= '0';
      o_data_rec_ack_request <= '0';
      o_data_received <= '0';

      case lvec_state is
        -- Waiting for transaction to begin
        when ST_IDLE =>
          o_error <= '0';
          if i_ncs = '0' then
            lvec_state <= ST_SEND_START;
            -- Send start pulse
            o_tr_send_start <= '1';
          end if;

        -- Sending start
        -- Needs to lose one i_clk cycle for the transmitter to start working
        when ST_SEND_START =>
          lvec_state <= ST_SEND_START_WAIT;
          lsig_start_restart <= '1';
          lsig_rw_mode <= '0';
          lvec_transaction_state <= ST_TRANS_ADDR;
        when ST_SEND_START_WAIT =>
          if i_tr_busy = '0' then
            lvec_state <= ST_BUSOWNED_IDLE;
          end if;

        -- Started, wait for transaction to begin
        when ST_BUSOWNED_IDLE =>
          o_request_transaction <= '1';
          -- Can send a restart only if we wrote addr.
          if i_repeat_start = '1' and lvec_transaction_state = ST_TRANS_IN_TRANSACTION then
            lvec_state <= ST_SEND_START;
            o_tr_send_start <= '1';
          end if;
          -- Send addr/command/read based on transaction state
          if i_send_data = '1' then
            if lsig_rw_mode = '0' or lvec_transaction_state /= ST_TRANS_IN_TRANSACTION then
              lvec_state <= ST_SEND_DATA;
              o_tr_send_data <= '1';
              o_tr_data_to_send <= i_data;
              o_rec_slave_write <= '1';
            else
              lvec_state <= ST_READ_DATA_WAIT_VALID;
              o_tr_send_data <= '1';
              o_tr_data_to_send <= (others => '1'); -- Read data, send dummy
              o_rec_slave_write <= '0';
            end if;
          end if;
          -- Stop system, not restricted
          if i_ncs = '1' then
            lvec_state <= ST_SEND_STOP;
            o_tr_send_stop <= '1';
          end if;

        when ST_SEND_DATA =>
          lvec_state <= ST_SEND_DATA_WAIT_VALID;
        when ST_SEND_DATA_WAIT_VALID =>
          -- Check if NACKED or not
          if i_rec_data_valid = '1' then
            lvec_state <= ST_SEND_DATA_WAIT_BUSY;
            o_frame_ack <= i_rec_ack_bit; -- Forward ACK/NACK to handler
            -- Check current transaction state
            case lvec_transaction_state is
              when ST_TRANS_ADDR =>
                -- Check for 10 bit address only id we had a start or restart
                if i_rec_data_received(7 downto 4) = "1110" and lsig_start_restart = '1' then
                  lvec_transaction_state <= ST_TRANS_ADDR10BL;
                -- 7b addr or restart
                else
                  lvec_transaction_state <= ST_TRANS_IN_TRANSACTION;
                  lsig_start_restart <= '0';
                end if;
                -- Get mode
                lsig_rw_mode <= i_rec_data_received(0); -- R/W bit
              when ST_TRANS_ADDR10BL => -- Full 10B addr sent
                lvec_transaction_state <= ST_TRANS_IN_TRANSACTION;
                lsig_start_restart <= '0';
              when ST_TRANS_IN_TRANSACTION => null;
              when others =>
                lvec_state <= ST_ERROR; -- unexpected transaction state
            end case; -- lvec_transaction_state
          end if; -- i_tr_busy = '0'
        when ST_SEND_DATA_WAIT_BUSY =>
          if i_tr_busy = '0' then
            lvec_state <= ST_BUSOWNED_IDLE;
          end if;

        when ST_READ_DATA_WAIT_VALID =>
          if i_rec_data_valid = '1' then
            lvec_state <= ST_READ_DATA_FWD_ACK;
            o_data <= i_rec_data_received; -- Forward data to handler
            o_data_received <= '1'; -- Indicate data received
            o_data_rec_ack_request <= '1'; -- Request ACK from handler
          end if;
        when ST_READ_DATA_FWD_ACK =>
          lvec_state <= ST_READ_DATA_WAIT_BUSY;
        when ST_READ_DATA_WAIT_BUSY =>
          o_tr_ack <= i_ack;
          if i_tr_busy = '0' then
            lvec_state <= ST_BUSOWNED_IDLE;
          end if;

        -- Sending stop
        -- Needs to lose one i_clk cycle for the transmitter to start working
        when ST_SEND_STOP =>
          lvec_state <= ST_SEND_STOP_WAIT;
        when ST_SEND_STOP_WAIT =>
          if i_tr_busy = '0' then
            lvec_state <= ST_IDLE;
          end if;

        -- On system error
        when ST_ERROR =>
          o_error <= '1';
          if i_tr_busy = '0' then -- wait for any running operation to end
            o_tr_send_stop <= '1';
            lvec_state <= ST_SEND_STOP;
          end if;

        -- On state machine error
        when others =>
          lvec_state <= ST_ERROR; -- unexpected state

      end case;
    end if;
  end process p_state_machine;

END ARCHITECTURE RTL;
