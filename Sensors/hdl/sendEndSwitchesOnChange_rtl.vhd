--
-- VHDL Architecture Sensors.sendEndSwitchesOnChange.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:11:58 17.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF sendEndSwitchesOnChange IS
BEGIN

  doSendEndSW : if INHIBIT_ENDSW_SEND = '0' generate
    -- Send when any edge is detected
    sendEndSwitches <= '1' when 
      unsigned(ends_edges) > (1 to SENS_endSwitchNb => '0') else '0';
  end generate doSendEndSW;

  noSendEndSW : if INHIBIT_ENDSW_SEND = '1' generate
    sendEndSwitches <= '0';
  end generate noSendEndSW;

END ARCHITECTURE rtl;
