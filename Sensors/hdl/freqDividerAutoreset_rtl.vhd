Library Kart;
  Use Kart.Kart.all;

LIBRARY Common;
  USE Common.CommonLib.all;

ARCHITECTURE rtl OF rangerSubsignals IS

  signal lsig_old_pulse, lsig_pulse_begin : std_ulogic;

  constant TIMEOUT_NB_PULSES : positive := positive(
    real(SENS_rangeTimeoutBeforeStartMS) / (1000.0*CLOCK_PERIOD));
  signal lvec_timeoutCounter: unsigned(requiredBitNb(TIMEOUT_NB_PULSES) - 1 downto 0);
  constant TIMEOUT_CNT_TARGET : unsigned(lvec_timeoutCounter'range)
    := to_unsigned(TIMEOUT_NB_PULSES, lvec_timeoutCounter'length);
  constant TIMEOUT_TEST_CNT_TARGET : unsigned(lvec_timeoutCounter'range)
    := to_unsigned(100, lvec_timeoutCounter'length);

BEGIN

  -- Detect edges of pulse to begin/end
  process(reset, clock)
  begin
    if reset = '1' then
      lsig_old_pulse <= '0';
    elsif rising_edge(clock) then
      lsig_old_pulse <= distancePulse;
    end if;
  end process;

  lsig_pulse_begin <= '1' when lsig_old_pulse = '0' and distancePulse = '1' else '0';

  -- Timeout before another reading (avoid overloading BLE)
  process(reset, clock)
  begin
    if reset = '1' then
      lvec_timeoutCounter <= (others=>'0');
    elsif rising_edge(clock) then
      if lvec_timeoutCounter = 0 then
        if lsig_pulse_begin = '1' then
          lvec_timeoutCounter <= lvec_timeoutCounter + 1;
        end if;
      else
        lvec_timeoutCounter <= lvec_timeoutCounter + 1;
        if testMode = '1' then
          if lvec_timeoutCounter >= TIMEOUT_TEST_CNT_TARGET then
            lvec_timeoutCounter <= (others=>'0');
          end if;
        else
          if lvec_timeoutCounter >= TIMEOUT_CNT_TARGET then
            lvec_timeoutCounter <= (others=>'0');
          end if;
        end if;
      end if;
    end if;
  end process;

  startNextCount <= '1' when lvec_timeoutCounter = 0 and lsig_pulse_begin = '1' else '0';

END ARCHITECTURE rtl;
