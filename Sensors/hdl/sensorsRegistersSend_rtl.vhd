--
-- VHDL Architecture Sensors.sensorsRegistersSend.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:50:27 17.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF sensorsRegistersSend IS

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
    variable hasSent : std_ulogic;
  begin
    if reset = '1' then
      p_request <= '0';
      p_addr_out <= (others=>'0');
      p_data_out <= (others=>'0');
      p_state <= idle;
      hasSent := '0';
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
              elsif p_int_reg_addr = SENS_BATTERY_EXT_REG_POS then
                p_data_out <= --(battery250uv'length to p_data_out'high => '0') & 
                  std_ulogic_vector(battery250uv);
              elsif p_int_reg_addr = SENS_CURRENT_EXT_REG_POS then
                p_data_out <= --(current250uA'length to p_data_out'high => '0') & 
                  std_ulogic_vector(current250uA);
              elsif p_int_reg_addr = SENS_RANGEFNDR_EXT_REG_POS then
                p_data_out <= --(rangerDistance'length to p_data_out'high => '0') & 
                  std_ulogic_vector(rangerDistance);
              elsif p_int_reg_addr = SENS_ENDSWITCHES_EXT_REG_POS then
                p_data_out <= --(endSwitches'length to p_data_out'high => '0') & 
                  std_ulogic_vector(endSwitches);

              elsif p_int_reg_addr >= SENS_HALLCNT_EXT_REG_POS and
                  p_int_reg_addr < SENS_HALLCNT_EXT_REG_POS + SENS_hallSensorNb then
                p_data_out <= hallReg(
                    to_integer(unsigned(addressIn(REG_ADDR_REG_RANGE)))
                    - SENS_HALLCNT_EXT_REG_POS
                  );
              else
                p_state <= idle;
              end if;
            end if;
          -- Request from internal
          elsif sendBattery = '1' then
            p_addr_out <= regExtAddrBegin & std_ulogic_vector(
              to_unsigned(SENS_BATTERY_EXT_REG_POS, REG_ADDR_MAXNBREG_BITS));
            p_request <= '1';
            p_state <= request;
            p_data_out <= --(battery250uv'length to p_data_out'high => '0') & 
                  std_ulogic_vector(battery250uv);
          elsif sendCurrent = '1' then
            p_addr_out <= regExtAddrBegin & std_ulogic_vector(
              to_unsigned(SENS_CURRENT_EXT_REG_POS, REG_ADDR_MAXNBREG_BITS));
            p_request <= '1';
            p_state <= request;
            p_data_out <= --(current250uA'length to p_data_out'high => '0') & 
                  std_ulogic_vector(current250uA);
          elsif sendRangeFinder ='1' then
            p_addr_out <= regExtAddrBegin & std_ulogic_vector(
              to_unsigned(SENS_RANGEFNDR_EXT_REG_POS, REG_ADDR_MAXNBREG_BITS));
            p_request <= '1';
            p_state <= request;
            p_data_out <= --(rangerDistance'length to p_data_out'high => '0') & 
              std_ulogic_vector(rangerDistance);
          elsif sendEndSwitches ='1' then
            p_addr_out <= regExtAddrBegin & std_ulogic_vector(
              to_unsigned(SENS_ENDSWITCHES_EXT_REG_POS, REG_ADDR_MAXNBREG_BITS));
            p_request <= '1';
            p_state <= request;
            p_data_out <= --(endSwitches'length to p_data_out'high => '0') & 
              std_ulogic_vector(endSwitches);
          else
            hasSent := '0';

            for index in 0 to SENS_hallSensorNb-1 loop
              if sendHall(index) = '1' and hasSent = '0' then
                hasSent := '1';
                p_addr_out <= regExtAddrBegin & std_ulogic_vector(
                to_unsigned(SENS_HALLCNT_EXT_REG_POS + index,
                  REG_ADDR_MAXNBREG_BITS));
                p_request <= '1';
                p_state <= request;
                p_data_out <= hallReg(index);
              end if;
            end loop;
            
          end if;

        when request =>
          if sensorsSendAuth = '1' then
            p_request <= '0';
            p_state <= idle;
          end if;

        when others => p_state <= idle;

      end case;
    end if;
  end process register_send;

  sensorsSendRequest <= p_request;
  sensorsAddressToSend <= p_addr_out;
  sensorsDataToSend <= p_data_out;

END ARCHITECTURE rtl;
