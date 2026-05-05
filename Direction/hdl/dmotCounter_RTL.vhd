ARCHITECTURE masterVersion OF dmotCounter IS

  signal sMotorPosition: unsigned(motorPosition'range);
  signal p_stpEnd_rising : std_ulogic;

BEGIN

  count: process(reset, clock)
  begin
    if reset = '1' then
      sMotorPosition <= (others => '0');
      p_stpEnd_rising <= '0';
    elsif rising_edge(clock) then
      p_stpEnd_rising <= stepperEnd;
      if (p_stpEnd_rising = '0' and stepperEnd = '1') or restart = '1' then
        sMotorPosition <= zeroValue;
      elsif (step = '1') and (enCoils = '1') then
        if incCount = '1' then
          sMotorPosition <= sMotorPosition + 1;
        elsif incCount = '0' and sMotorPosition > 0 then
          sMotorPosition <= sMotorPosition - 1;
        end if;
      end if;
    end if;
  end process count;

  motorPosition <= sMotorPosition;

END ARCHITECTURE masterVersion;
