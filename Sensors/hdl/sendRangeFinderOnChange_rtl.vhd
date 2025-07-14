--
-- VHDL Architecture Sensors.sendRangeFinderOnChange.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:41:06 17.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF sendRangeFinderOnChange IS

  signal p_last_range : unsigned(SENS_rangeBitNb-1 downto 0);

BEGIN

  deltaSender:process(reset, clock)
  begin
    if reset = '1' then
      p_last_range <= (others=>'0');
      sendRangeFinder <= '0';
    elsif rising_edge(clock) then
      if signed('0' & rangerDistance) > signed(('0' & p_last_range) + SENS_RANGEFNDR_DELTA) or
        signed('0' & rangerDistance) < signed(('0' & p_last_range) - SENS_RANGEFNDR_DELTA) then
        p_last_range <= rangerDistance;
        sendRangeFinder <= '1';
      else
        sendRangeFinder <= '0';
      end if;
    end if;
  end process deltaSender;

END ARCHITECTURE rtl;
