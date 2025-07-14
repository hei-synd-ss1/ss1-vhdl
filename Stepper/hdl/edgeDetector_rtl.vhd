--
-- VHDL Architecture Stepper.edgeDetector.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 19:35:33 15.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--
ARCHITECTURE rtl OF anyEdgeDetector IS

  SIGNAL pulse_delayed : std_ulogic;

BEGIN

  -- delay pulse
  reg : PROCESS (reset, clock)
  BEGIN
    IF reset = '1' THEN
      pulse_delayed <= '0';
    ELSIF rising_edge(clock) THEN
      pulse_delayed <= pulse;  
    END IF;    
  END PROCESS reg ;
  
  -- edge detection
  edge <= '1' when ((pulse = '1') and (pulse_delayed = '0'))
      or ((pulse = '0') and (pulse_delayed = '1')) else '0';

END ARCHITECTURE rtl;
