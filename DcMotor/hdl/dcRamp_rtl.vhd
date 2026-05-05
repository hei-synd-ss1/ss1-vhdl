LIBRARY Common;
  USE Common.CommonLib.all;
LIBRARY Kart;
  USE Kart.Kart.ALL;

-- Ramp the motor acceleration to avoid current spikes
ARCHITECTURE rtl OF dcRamp IS
  signal lvec_speed : signed(DC_speedBitNb-1 DOWNTO 0);
  constant TIMEOUT_NB_PULSES : positive := DC_accelerationTickRateMS;
  signal lvec_counter: unsigned(requiredBitNb(TIMEOUT_NB_PULSES) - 1 downto 0);
  constant TIMEOUT_CNT_TARGET : unsigned(lvec_counter'range)
    := to_unsigned(TIMEOUT_NB_PULSES, lvec_counter'length);
  signal lsig_smaller, lsig_bigger, lsig_diff: std_ulogic;
BEGIN
  
  lsig_smaller  <= '1' when lvec_speed < signed(target) else '0';
  lsig_bigger   <= '1' when lvec_speed > signed(target) else '0';
  lsig_diff     <= lsig_smaller or lsig_bigger;

  ramp: process(reset, clock)
  begin
    if reset = '1' then
      lvec_speed <= (others => '0');
      lvec_counter <= (others => '0');
    elsif rising_edge(clock) then
      -- Test mode => direct speed value
      if testMode = '1' then
        lvec_speed <= signed(target);
      -- Normal mode => creates a ramp
      else
        -- Target not reached
        if lsig_diff = '1' then
          lvec_counter <= lvec_counter + 1;
          if lvec_counter >= TIMEOUT_CNT_TARGET then
            if lsig_smaller = '1' then
              lvec_speed <= lvec_speed + 1;
            elsif lsig_bigger = '1' then
              lvec_speed <= lvec_speed - 1;
            end if;
            lvec_counter <= (others => '0');
          end if;
        else
          lvec_counter <= (others => '0');
        end if;
      end if;
    end if;
  end process ramp;

  speed <= lvec_speed;

END ARCHITECTURE rtl;
