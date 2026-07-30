
Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF cregRegisterSender IS

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
          if cregSendAuth = '1' then
            p_request <= '0';
            p_state <= idle;
          end if;

        when others => p_state <= idle;

      end case;
    end if;
  end process register_send;

  cregSendRequest <= p_request;
  cregAddressToSend <= p_addr_out;
  cregDataToSend <= p_data_out;

END ARCHITECTURE rtl;
