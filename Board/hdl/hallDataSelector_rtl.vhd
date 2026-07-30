Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE rtl OF hallDataSelector IS
BEGIN

  hall_latch : for ind in 1 to STD_HALL_NUMBER generate
    process(rst, clk)
    begin
      if rst = '1' then
        hallsOut(ind) <= '0';
      elsif rising_edge(clk) then
        hallsOut(ind) <= hallsIn(ind);
      end if;
    end process;
  end generate hall_latch;

  hall_inhibit : for ind in STD_HALL_NUMBER+1 to SENS_hallSensorNb generate
    hallsOut(ind) <= '0';
  end generate hall_inhibit;

END ARCHITECTURE rtl;
