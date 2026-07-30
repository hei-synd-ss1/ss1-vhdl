ARCHITECTURE RTL OF dcMotorPrescaler IS

  signal prescalerCounter: unsigned(prescaler'range);
  signal prescalerDone: std_ulogic;

BEGIN

  divideClock: process(reset, clock)
  begin
    if reset = '1' then
      prescalerCounter <= (others => '0');
    elsif rising_edge(clock) then
      if prescalerDone = '1' then
        prescalerCounter <= (others => '0');
      else
        prescalerCounter <= prescalerCounter + 1;
      end if;
    end if;
  end process divideClock;

  prescalerDone <= '1' when prescalerCounter+1 >= prescaler
    and prescaler /= (prescaler'range=>'0') else '0';
  pwmEn <= prescalerDone;

END ARCHITECTURE RTL;
