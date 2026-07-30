Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE rtl OF endSwitchesSelector IS
BEGIN

  endsw_latch : for ind in 1 to STD_ENDSW_NUMBER generate
    process(rst, clk)
    begin
      if rst = '1' then
        endswOut(SENS_endSwitchNb + 1 - ind) <= '0';
      elsif rising_edge(clk) then
        endswOut(SENS_endSwitchNb + 1 - ind) <= endswIn(ind);
      end if;
    end process;
  end generate endsw_latch;

  endsw_inhibit : for ind in STD_ENDSW_NUMBER+1 to SENS_endSwitchNb generate
    endswOut(SENS_endSwitchNb + 1 - ind) <= '0';
  end generate endsw_inhibit;

END ARCHITECTURE rtl;

