--
-- VHDL Architecture Kart.txRouter.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 15:02:37 17.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE rtl OF txRouter IS

  -- Send state machine states
  type statesType is (
      idle, waitFull, send
    );
  signal p_state : statesType;
  signal p_addr : symbolSizeType;
  signal p_data : dataRegisterType;
  signal p_stepperAuth, p_dcAuth, p_sensorsAuth, p_cregAuth, p_load : std_ulogic;

BEGIN

  sendproc:process(reset, clock)

    procedure testAndSend(signal addr : in symbolSizeType;
                        signal data : in dataRegisterType;
                        signal request : in std_ulogic;
                        signal auth : out std_ulogic;
						signal padr : out symbolSizeType;
						signal pdt : out dataRegisterType;
						signal pst : out statesType;
						signal isFull : in std_ulogic;
                        variable sent : out std_ulogic) is
    begin
      if request = '1' then
        auth <= '1';
        padr <= addr;
        pdt <= data;
        pst <= waitFull when isFull = '1' else send;
        sent := '1';
      else
        auth <= '0';
        sent := '0';
      end if;
    end procedure;

    variable sent : std_ulogic;

  begin
    if reset = '1' then
      sent := '0';
      p_state <= idle;
      p_addr <= (others=>'0');
      p_data <= (others=>'0');
      p_load <= '0';
      p_stepperAuth <= '0';
      p_dcAuth <= '0';
      p_sensorsAuth <= '0';
      p_cregAuth <= '0';
    elsif rising_edge(clock) then
      case p_state is
        when idle =>
          p_load <= '0';
          -- Sorted by priority
          testAndSend(stepperAddressToSend, stepperDataToSend,
            stepperSendRequest, p_stepperAuth, p_addr, p_data, p_state, full, sent);
          if sent = '0' then
            testAndSend(dcMotorAddressToSend, dcMotorDataToSend,
              dcMotorSendRequest, p_dcAuth, p_addr, p_data, p_state, full, sent);
          end if;
          if sent = '0' then
            testAndSend(sensorsAddressToSend, sensorsDataToSend,
              sensorsSendRequest, p_sensorsAuth, p_addr, p_data, p_state, full, sent);
          end if;
          if sent = '0' then
            testAndSend(cregAddressToSend, cregDataToSend,
              cregSendRequest, p_cregAuth, p_addr, p_data, p_state, full, sent);
          end if;
          sent := '0';
          
        when waitFull =>
          if full = '0' then
            p_state <= send;
          end if;

        when send =>
          p_load <= '1';
          p_state <= idle;

        when others => p_state <= idle;
      end case;
    end if;
  end process sendproc;

  address <= p_addr;
  data <= p_data;
  load <= p_load;
  stepperSendAuth <= p_stepperAuth;
  dcMotorSendAuth <= p_dcAuth;
  sensorsSendAuth <= p_sensorsAuth;
  cregSendAuth <= p_cregAuth;

END ARCHITECTURE rtl;
