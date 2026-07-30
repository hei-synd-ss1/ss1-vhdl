LIBRARY Common;
  USE Common.CommonLib.all;
Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE rtl OF freqDividerWForceOnStart IS

  constant target : positive := CLOCK_1S_DIVIDER * 2;
  constant once_target : positive := CLOCK_1MS_DIVIDER * 200;

  signal count: unsigned(requiredBitNb(target)-1 downto 0);
  signal once : std_ulogic;

BEGIN

  countEndlessly: process(reset, clock)
  begin
    if reset = '1' then
      count <= to_unsigned(target-1, count'length);
      once <= '0';
    elsif rising_edge(clock) then
      if count = 0 then
        count <= to_unsigned(target-1, count'length);
      else
        count <= count-1;
        if count = to_unsigned(target - once_target, count'length) then
          once <= '1';
        end if;
      end if;
    end if;
  end process countEndlessly;

  enable <= '1' when count = 0 or rising_edge(once) else '0';

END ARCHITECTURE rtl;

