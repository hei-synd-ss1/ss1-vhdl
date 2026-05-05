ARCHITECTURE rtl OF edgeDetectorDflt IS

  SIGNAL pulse_delayed : std_ulogic;

BEGIN

  -- delay pulse
  reg : PROCESS (reset, clock)
  BEGIN
    IF reset = '1' THEN
      pulse_delayed <= dfltPulse;
    ELSIF rising_edge(clock) THEN
      pulse_delayed <= pulse;  
    END IF;    
  END PROCESS reg ;
  
  -- edge detection
  rising <= '1' when (pulse = '1') and (pulse_delayed = '0')
    else '0'; 
  falling <= '1' when (pulse = '0') and (pulse_delayed = '1')
    else '0'; 
  
END ARCHITECTURE rtl;
