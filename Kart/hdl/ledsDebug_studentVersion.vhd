LIBRARY Common;
  USE Common.CommonLib.all;
LIBRARY Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE studentVersion OF ledsDebug IS
BEGIN

  LEDs(0) <= LED_GREEN;
  LEDs(1) <= LED_YELLOW;
  LEDs(2) <= LED_RED;

END ARCHITECTURE studentVersion;

