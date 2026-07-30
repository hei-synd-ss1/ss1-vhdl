--
-- VHDL Architecture Sensors.led_blinker.rtl
--
-- Created:
--          by - axela.UNKNOWN (I12)
--          at - 11:43:21 24.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
	Use Kart.Kart.all;

Library Common;
	Use Common.CommonLib.all;

ARCHITECTURE rtl OF led_blinker IS

	signal p_led : std_ulogic;
	signal p_cnt : unsigned(ledReg'high-1 downto 0);

BEGIN

	blink:process(reset, clock)
	begin
		if reset = '1' then
			p_led <= '0';
			p_cnt <= (others=>'0');
		elsif rising_edge(clock) then
			if ledReg(ledReg'high) = '0' then
				p_led <= '0';
				p_cnt <= (others=>'0');
			elsif ledReg(ledReg'high - 1 downto 0) = (0 to ledReg'high - 1=>'0') then
				p_led <= '1';
			elsif p_cnt >= unsigned(ledReg(ledReg'high - 1 downto 0)) then
				p_led <= not p_led;
				p_cnt <= (others=>'0');
			elsif pulse1ms = '1' then
				p_cnt <= p_cnt + 1;
			end if;
		end if;
	end process blink;

	led <= p_led;

END ARCHITECTURE rtl;
