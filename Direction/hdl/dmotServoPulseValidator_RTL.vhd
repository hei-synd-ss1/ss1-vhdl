-- Validate servomotor pulse duration to avoid burning the motor
-- Axam

Library Kart;
  USE Kart.Kart.ALL;

Library Common;
  USE Common.CommonLib.ALL;

ARCHITECTURE RTL OF servoPulseValidator IS

  signal lvec_pulse_cnt : unsigned( requiredBitNb(MAX_CMD_CLOCKS) - 1 DOWNTO 0 );
  signal lsig_servo : std_ulogic;

BEGIN

  process(i_reset, i_clock)
  begin
    if i_reset = '1' then
      lvec_pulse_cnt <= (OTHERS => '0');
      lsig_servo <= '0';
    elsif rising_edge(i_clock) then
      -- Start the count
      if lvec_pulse_cnt = 0 then
        lsig_servo <= '0';
        -- Start pulse
        if i_servo = '1' then
          lvec_pulse_cnt <= lvec_pulse_cnt + 1;
          lsig_servo <= '1';
        end if;
      -- Stop if the pulse exceeds the maximum allowed duration
      elsif lvec_pulse_cnt >= MAX_CMD_CLOCKS then
        lsig_servo <= '0';
        if i_servo = '0' then
          lvec_pulse_cnt <= (others => '0');
        end if;
      -- Allows stopping if the minimal time has been reached
      elsif lvec_pulse_cnt >= MIN_CMD_CLOCKS then
          lvec_pulse_cnt <= lvec_pulse_cnt + 1;
          if i_servo = '0' then
            lvec_pulse_cnt <= (others => '0');
            lsig_servo <= '0';
          end if;
      -- Counting the minimal pulse
      else
        lvec_pulse_cnt <= lvec_pulse_cnt + 1;
      end if;
    end if;
  end process;

  o_servo <= lsig_servo;

END ARCHITECTURE RTL;
