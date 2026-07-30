--
-- VHDL Architecture Sensors.sendDeltaManager.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:24:40 17.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF sendDeltaManager IS

  signal p_last_count : unsigned(dataSize-1 downto 0);
  signal p_send : std_ulogic;

BEGIN

  
    deltaSender:process(reset, clock)
    begin
      if reset = '1' then
        p_last_count <= (others=>'0');
        p_send <= '0';
      elsif rising_edge(clock) then
		-- not used within a generate to avoid a warning
		if requiredDelta /= 0 then
			if signed('0' & dataIn) > signed('0' & p_last_count) +
			  to_signed(requiredDelta, p_last_count'length+1)
			 or signed('0' & dataIn) < signed('0' & p_last_count) -
			  to_signed(requiredDelta, p_last_count'length+1) then
			  p_last_count <= dataIn;
			  p_send <= '1';
			else
			  p_send <= '0';
			end if;
		end if;
      end if;
    end process deltaSender;
  
  send <= p_send;

END ARCHITECTURE rtl;
