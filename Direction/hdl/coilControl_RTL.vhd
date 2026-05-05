ARCHITECTURE masterVersion OF coilControl IS

  signal phaseCounter: unsigned(1 downto 0);

  signal stepdelayed : std_ulogic;

BEGIN

  countPhases: process(reset, clock)
  begin
    if reset = '1' then
      phaseCounter <= (others => '0');
    elsif rising_edge(clock) then
      if (enCoils = '1') and (step = '1') then
        if dir1to4 = '1' then
          phaseCounter <= phaseCounter + 1;
        else
          phaseCounter <= phaseCounter - 1;
        end if;
      end if;
    end if;
  end process countPhases;

  driveCoils: process(reset,clock)
  begin
    if reset = '1' then
      coil1 <= '0';
      coil2 <= '0';
      coil3 <= '0';
      coil4 <= '0';
      magnetizing_power <= "0000";
    elsif rising_edge(clock) then
      if step = '1' then
        if enCoils = '1' then
          magnetizing_power <= "1111";
          coil1 <= '0';
          coil2 <= '0';
          coil3 <= '0';
          coil4 <= '0';
          case to_integer(phaseCounter) is
            when 0 => coil1 <= '1';
            when 1 => coil2 <= '1';
            when 2 => coil3 <= '1';
            when 3 => coil4 <= '1';
            when others => null;
          end case;
        else
          magnetizing_power <= "0001";
        end if;
      end if;
    end if;
  end process driveCoils;

END ARCHITECTURE masterVersion;
