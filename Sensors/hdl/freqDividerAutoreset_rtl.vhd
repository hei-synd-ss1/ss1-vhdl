Library Kart;
  Use Kart.Kart.all;

LIBRARY Common;
  USE Common.CommonLib.all;

ARCHITECTURE rtl OF rangerSubsignals IS

  signal oldPulse, pulse_begin : std_ulogic;

  constant TIMEOUT_NB_PULSES : positive := positive(
    real(SENS_rangeTimeoutBeforeStartMS) / (1000.0*CLOCK_PERIOD));
  signal timeoutCounter: unsigned(requiredBitNb(TIMEOUT_NB_PULSES) - 1 downto 0);
  constant TIMEOUT_CNT_TARGET : unsigned(timeoutCounter'range)
    := to_unsigned(TIMEOUT_NB_PULSES, timeoutCounter'length);
    
  signal count_begin, count_en, last_count_en : std_ulogic;

  signal divideCount: unsigned(requiredBitNb(divideValue)-1 downto 0);

BEGIN

  -- Detect edges of pulse to begin/end
  pulse_edge: process(reset, clock)
  begin
    if reset = '1' then
      oldPulse <= '0';
    elsif rising_edge(clock) then
      oldPulse <= distancePulse;
    end if;
  end process pulse_edge;

  pulse_begin <= '1' when oldPulse = '0' and distancePulse = '1' else '0';

  -- Timeout before another reading (avoid overloading BLE)
  inbtwn_read: process(reset, clock)
  begin
    if reset = '1' then
      timeoutCounter <= (others=>'0');
    elsif rising_edge(clock) then
      if timeoutCounter = 0 then
        if pulse_begin = '1' then
          timeoutCounter <= timeoutCounter + 1;
        end if;
      else
        timeoutCounter <= timeoutCounter + 1;
        if timeoutCounter >= TIMEOUT_CNT_TARGET then
          timeoutCounter <= (others=>'0');
        end if;
      end if;
    end if;
  end process inbtwn_read;

  count_begin <= '1' when timeoutCounter = 0 and pulse_begin = '1' else '0';

  -- Manages count enable
  cnt_en: process(reset, clock)
  begin
    if reset = '1' then
      last_count_en <= '0';
      count_en <= '0';
    elsif rising_edge(clock) then
      last_count_en <= count_en;
      if count_begin = '1' then
        count_en <= '1';
      elsif distancePulse = '0' or timeoutCounter = 0 then
        count_en <= '0';
      end if;
    end if;
  end process cnt_en;

  countEnable <= count_en;


  countDivider: process(reset, clock)
  begin
    if reset = '1' then
      divideCount <= (others => '0');
    elsif rising_edge(clock) then
      if divideCount = 0 or count_en = '0' then
        divideCount <= to_unsigned(divideValue-1, divideCount'length);
      else
        divideCount <= divideCount-1 ;
      end if;
    end if;
  end process countDivider;

  countPulse <= '1' when divideCount = 0 or
    (last_count_en = '0' and count_en = '1')
    else '0';

END ARCHITECTURE rtl;
