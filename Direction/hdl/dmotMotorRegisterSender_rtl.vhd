--
-- VHDL Architecture Stepper.stepperMotorRegisterSender.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 16:55:03 13.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF dmotMotorRegisterSender IS

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

  constant regExtAddrBegin : std_ulogic_vector(REG_ADDR_MSB_NB_BITS downto 0)
    := std_ulogic_vector(to_unsigned(moduleAddr, REG_ADDR_MSB_NB_BITS)) & FRAME_WBIT_VALUE;

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
          if readRegister = '1' then
            -- Ensure the requested register exists
            if p_int_reg_addr < registersNb then
              p_addr_out <= addressIn;
              p_request <= '1';
              p_state <= request;
              -- Check if is a standard or "external" register
              if p_int_reg_addr < inRegistersNb then
                p_data_out <= bankData(p_int_reg_addr);
              else
                p_state <= idle;
              end if;
            end if;
          end if;

        when request =>
          if dmotSendAuth = '1' then
            p_request <= '0';
            p_state <= idle;
          end if;

        when others => p_state <= idle;

      end case;
    end if;
  end process register_send;

  dmotSendRequest <= p_request;
  dmotAddressToSend <= p_addr_out;
  dmotDataToSend <= p_data_out;

END ARCHITECTURE rtl;
