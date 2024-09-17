--
-- VHDL Architecture DcMotor.dcMotorRegisterSender.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 14:32:53 13.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF dcMotorRegisterSender IS

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
          if sendRxRegister = '1' then
            -- Ensure the requested register exists
            if p_int_reg_addr < registersNb then
              p_addr_out <= addressIn;
              p_request <= '1';
              p_state <= request;
              -- Check if is a standard or "external" register
              p_data_out <= bankData(p_int_reg_addr);
            end if;
          end if;

        when request =>
          if dcMotorSendAuth = '1' then
            p_request <= '0';
            p_state <= idle;
          end if;

        when others => p_state <= idle;

      end case;
    end if;
  end process register_send;

  dcMotorSendRequest <= p_request;
  dcMotorAddressToSend <= p_addr_out;
  dcMotorDataToSend <= p_data_out;

END ARCHITECTURE rtl;
