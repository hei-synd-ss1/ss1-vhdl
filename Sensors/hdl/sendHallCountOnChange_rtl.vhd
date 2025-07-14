--
-- VHDL Architecture Sensors.sendHallCountOnChange.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:37:27 17.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF sendHallCountOnChange IS
BEGIN

  -- Send when any edge is detected
  sendHallCount <= '1' when 
    unsigned(sendHallCounts) > (0 to SENS_hallSensorNb-1 => '0') else '0';

END ARCHITECTURE rtl;
