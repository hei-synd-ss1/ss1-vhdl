Library Common;
  Use Common.CommonLib.all;

Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE RTL OF stepperMotorDivider IS
  
  constant p_100khz_cnt_target : positive :=
    positive(CLOCK_FREQUENCY / STP_MAX_FREQ);

  signal p_100kCounter : unsigned(requiredBitNb(p_100khz_cnt_target)-1 downto 0);
  signal p_100kDone : std_ulogic;

  signal prescalerCounter: unsigned(divider'range);
  signal prescalerDone, divo, bigger: std_ulogic;

BEGIN

  ------------------------------------------------------------------------------
                                                  -- 100KHz counter
  cnt_100k: process(reset, clock)
  begin
    if reset = '1' then
      p_100kCounter <= (others => '0');
    elsif rising_edge(clock) then
      if (p_100kCounter + 1 >= to_unsigned(p_100khz_cnt_target, p_100kCounter'length) and testMode = '0')
        or (p_100kCounter + 1 >= to_unsigned(p_100khz_cnt_target / 10, p_100kCounter'length) and testMode = '1') then
        p_100kCounter <= (others => '0');
      else
        p_100kCounter <= p_100kCounter + 1;
      end if;
    end if;
  end process cnt_100k;

  p_100kDone <= '1' when p_100kCounter = 0 else '0';

  ------------------------------------------------------------------------------
                                                            -- prescaler counter
  prescalerDivide: process(reset, clock)
  begin
    if reset = '1' then
      prescalerCounter <= (others => '0');
      prescalerDone <= '0';
    elsif rising_edge(clock) then
      if p_100kDone = '1' then
        if bigger = '1' then
          prescalerCounter <= (others => '0');
        else
          prescalerCounter <= prescalerCounter + 1;
        end if;
      end if;
      prescalerDone <= p_100kDone when bigger = '1' and divo = '0' else '0';
    end if;
  end process prescalerDivide;

  divo <= '0' when divider /= 0 else '1';
  bigger <= '1' when prescalerCounter + 1 >= divider else '0';

  ------------------------------------------------------------------------------

  pwmEn <= prescalerDone;

END ARCHITECTURE RTL;
