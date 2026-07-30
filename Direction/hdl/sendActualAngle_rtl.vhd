--
-- VHDL Architecture Stepper.sendActualAngle.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 19:42:13 15.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF sendActualAngleDeltaManager IS

  signal p_lastsent_angle : unsigned(STP_angleBitNb-1 DOWNTO 0);

BEGIN

  deltaSender:process(reset, clock)
  begin
    if reset = '1' then
      p_lastsent_angle <= (others=>'0');
      sendActualAngle <= '0';
    elsif rising_edge(clock) then
      if restarting = '1' then
        p_lastsent_angle <= (others=>'0');
        sendActualAngle <= '0';
      else
        if signed(actualAngle(actualAngle'high) & actualAngle)
            > signed(p_lastsent_angle(p_lastsent_angle'high) & p_lastsent_angle)
              + STP_ANGLE_DELTA 
          or
           signed(actualAngle(actualAngle'high) & actualAngle)
            < signed(p_lastsent_angle(p_lastsent_angle'high) & p_lastsent_angle)
              - STP_ANGLE_DELTA
          then
          p_lastsent_angle <= actualAngle;
          sendActualAngle <= '1';
        else
          sendActualAngle <= '0';
        end if;
      end if;
    end if;
  end process deltaSender;

END ARCHITECTURE rtl;
