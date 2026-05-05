Library Kart;
  Use Kart.Kart.all;

Library Common;
  Use Common.CommonLib.all;

ARCHITECTURE rtl OF hallPulsesFilter IS
BEGIN

  filter_gen: for i in 1 to SENS_hallSensorNb generate

      signal counter : unsigned(requiredBitNb(requiredClockPulses)-1 downto 0);
      signal pulse_filt : std_ulogic;

    begin

      filter: process(reset, clock)
      begin
        if reset = '1' then
          counter <= (others=>'0');
          pulse_filt <= '0';
        elsif rising_edge(clock) then
          if pulse_filt /= hallPulses(i) then
            if counter + 1 >= requiredClockPulses then
              counter <= (others=>'0');
              pulse_filt <= not pulse_filt;
            else
              counter <= counter + 1;
            end if;
          else
            counter <= (others=>'0');
          end if;
        end if;
      end process filter;

      hallPulsesFiltered(i) <= pulse_filt;

  end generate filter_gen;

END ARCHITECTURE rtl;
