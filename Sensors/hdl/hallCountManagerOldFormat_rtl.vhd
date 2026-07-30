--
-- VHDL Architecture Sensors.hallCountManagerOldFormat.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 16:28:02 25.07.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  Use Kart.Kart.all;

Library Common;
  Use Common.CommonLib.all;

ARCHITECTURE rtl OF hallCountManagerOldFormat IS

  -- Register time between pulses to get approx. frequency
--  type counterSetType is array(SENS_hallSensorNb-1 downto 0) of
--    unsigned(requiredBitNb(
--      (1.0/real(SENS_HALL_OLD_SEND_TIMEOUT_MS+SENS_hallSensorNb-1)) / CLOCK_PERIOD
--    )-1 downto 0);
--  signal p_counterSet: counterSetType;
  signal p_sendhall : std_ulogic_vector(SENS_hallSensorNb-1 downto 0);
--  signal p_sendcnts : std_ulogic_vector(SENS_hallSensorNb-1 downto 0);

  constant P_CNT_TARGET : positive :=
    SENS_HALL_OLD_SEND_TIMEOUT_MS+SENS_hallSensorNb;
  signal p_counter : unsigned(requiredBitNb(P_CNT_TARGET)-1 downto 0);

  type hallRegSaverType is array(SENS_hallSensorNb-1 downto 0) of dataRegisterType;
  signal p_hallregs : hallRegSaverType;
  signal p_old_hallregs : hallRegSaverType;

BEGIN

  timeout:process(reset, clock)
  begin
    if reset = '1' then
      p_counter <= (others=>'0');
      p_old_hallregs <= (others=>(others=>'0'));
    elsif rising_edge(clock) then
        p_sendhall <= (others=>'0');
        if pulse_1ms = '1' then
          p_counter <= p_counter + 1;
          for index in 0 to SENS_hallSensorNb-1 loop
            if p_counter = P_CNT_TARGET-index-2 then
              if p_old_hallregs(index) /= p_hallregs(index) then
                p_sendhall(index) <= '1';
                p_old_hallregs(index) <= p_hallregs(index);
              end if;
            end if;
          end loop;
          if p_counter >= P_CNT_TARGET then
            p_counter <= (others=>'0');
          end if;
        end if;
    end if;
  end process;

    -- If counts 2 pulses per turn (each hallPulse edge)
  sens_2pturn_on : if SENS_HALL_COUNTS_2PULSES_P_TURN = '1' generate
    hallregs : for index in 0 to SENS_hallSensorNb-1 generate

      p_hallregs(index) <=
        dataRegisterType
        (
          unsigned'(
            hallCount
            (
              SENS_hallCountBitNb * (index+1) - 1
                downto
              SENS_hallCountBitNb * index
            )
          )
        );
    end generate hallregs;

    zeroHallCounters <= (others=>'0');
    
  end generate sens_2pturn_on;

    -- If counts 1 pulse per turn (each hallPulse rising edge)
  sens_2pturn_off : if SENS_HALL_COUNTS_2PULSES_P_TURN = '0' generate
    hallregs : for index in 0 to SENS_hallSensorNb-1 generate
      
      p_hallregs(index) <=
        dataRegisterType
        (
          unsigned'(
            hallCount
            (
              SENS_hallCountBitNb * (index+1) - 1 - 1
                downto
              SENS_hallCountBitNb * index
            )
            & '0'
          )
        );

      -- Zero counter when last bit goes to 1
      process (reset, clock)
      begin
        if reset = '1' then
          zeroHallCounters(index+1) <= '0';
        elsif rising_edge(clock) then
          zeroHallCounters(index+1) <= '0';
          if hallCount(SENS_hallCountBitNb * (index+1) - 1) = '1' then
            zeroHallCounters(index+1) <= '1';
          end if;
        end if;
      end process;

    end generate hallregs;
  end generate sens_2pturn_off;

  hallregsset : for index in 0 to SENS_hallSensorNb-1 generate
      
      hallReg(index) <= p_hallregs(index);
      sendHall(index) <= p_sendhall(index);

  end generate hallregsset;

END ARCHITECTURE rtl;

