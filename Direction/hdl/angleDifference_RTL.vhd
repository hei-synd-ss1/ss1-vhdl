ARCHITECTURE masterVersion OF angleDifference IS

  signal difference: signed(targetPosition'high+1 downto 0);
  signal reached_int: std_ulogic;

  type turningStateType is (
    uninitialized,
    restarting, idle, turning
  );
  signal turningState : turningStateType;

BEGIN
  ------------------------------------------------------------------------------
                           -- calculate angle difference and reached information
  difference <= signed(resize(actualPosition, difference'length)) - signed(resize(targetPosition, difference'length));
  chooseDirection: process(reset, clock)
  begin
    if reset = '1' then
      incAngle <= '0';
    elsif rising_edge(clock) then
      if difference <= 0 then
        incAngle <= '1';
      else
        incAngle <= '0';
      end if;
    end if;
  end process chooseDirection;
    
  reached_int <= '1' when difference = 0 else '0';
  reached <= reached_int;

  ------------------------------------------------------------------------------
                                                        -- turning state machine
  turningFsm: process(reset, clock)
  begin
    if reset = '1' then
      turningState <= uninitialized;
      enCoils <= '0';
    elsif rising_edge(clock) then
      enCoils <= '0';

      case turningState is

        when uninitialized =>
          if restart = '1' then
            turningState <= restarting;
          end if;

        when restarting =>
          enCoils <= '1';
          if stepperEnd = '1' then
            turningState <= idle;
          end if;

        when idle =>
          if restart = '1' then
            turningState <= restarting;
          elsif reached_int = '0' then
            turningState <= turning;
          end if;

        when turning =>
          enCoils <= '1';
          if restart = '1' then
            turningState <= restarting;
          elsif reached_int = '1' then
            turningState <= idle;
          end if;

        when others =>
          turningState <= uninitialized;

      end case;
    end if;
  end process turningFsm;

  isRestarting <= '1' when turningState = restarting else '0';


END ARCHITECTURE masterVersion;
