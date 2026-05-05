Library Kart;
  Use KArt.Kart.all;

ARCHITECTURE rtl OF rangerValidator IS

  signal rangerOut : unsigned(SENS_rangeBitNb-1 downto 0);
  signal inhib : std_ulogic;

BEGIN

  validateRanger:process(reset, clock)
  begin
    if reset = '1' then
      rangerOut <= (others=>'0');
      inhib <= '0';
    elsif rising_edge(clock) then
      if rangerDistance >= SENS_RANGEFNDR_MIN_DELTA
        and rangerDistance <= SENS_RANGEFNDR_MAX_DELTA then
          rangerOut <= rangerDistance;
          inhib <= '0';
      else
        rangerOut <= (others=>'0');
        inhib <= '1';
      end if;
    end if;
  end process validateRanger;

  rangerDistanceOk <= rangerOut;
  inhibit <= inhib;

END ARCHITECTURE rtl;
