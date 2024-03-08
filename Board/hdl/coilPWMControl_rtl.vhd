--
-- VHDL Architecture Board.coilPWMControl.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 10:14:11 08.07.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  Use Kart.Kart.all;

LIBRARY Common;
  USE Common.CommonLib.ALL;

ARCHITECTURE rtl OF coilPWMControl IS

  signal i_coil1, i_coil2, i_coil3, i_coil4 : std_ulogic;
  signal i_c1_cnt, i_c2_cnt, i_c3_cnt, i_c4_cnt : unsigned(requiredBitNb(
    STP_PWM_CNT_TARGET)-1 downto 0);

BEGIN

  coil_ctrl: process(resetSynch, clock)
  begin
    if resetSynch = '1' then
      i_coil1 <= '1';
      i_coil2 <= '1';
      i_coil3 <= '1';
      i_coil4 <= '1';
      i_c1_cnt <= (others=>'0');
      i_c2_cnt <= (others=>'0');
      i_c3_cnt <= (others=>'0');
      i_c4_cnt <= (others=>'0');
    elsif rising_edge(clock) then
      if coil1_n = '0' then
        i_coil1 <= '1';
        i_c1_cnt <= (others=>'0');
      else
        i_c1_cnt <= i_c1_cnt + 1;
        if i_c1_cnt + 1 = STP_PWM_CNT_TARGET then
          i_c1_cnt <= (others=>'0');
          i_coil1 <= '1'; -- just ensure in case of weird targets
        elsif i_c1_cnt + 1 = STP_PWM_CNT_ON then
          i_coil1 <= '1';
        elsif i_c1_cnt = 0 then
          i_coil1 <= '0';
        end if;
      end if;

      if coil2_n = '0' then
        i_coil2 <= '1';
        i_c2_cnt <= (others=>'0');
      else
        i_c2_cnt <= i_c2_cnt + 1;
        if i_c2_cnt + 1 = STP_PWM_CNT_TARGET then
          i_c2_cnt <= (others=>'0');
          i_coil2 <= '1'; -- just ensure in case of weird targets
        elsif i_c2_cnt + 1 = STP_PWM_CNT_ON then
          i_coil2 <= '1';
        elsif i_c2_cnt = 0 then
          i_coil2 <= '0';
        end if;
      end if;
      
      if coil3_n = '0' then
        i_coil3 <= '1';
        i_c3_cnt <= (others=>'0');
      else
        i_c3_cnt <= i_c3_cnt + 1;
        if i_c3_cnt + 1 = STP_PWM_CNT_TARGET then
          i_c3_cnt <= (others=>'0');
          i_coil3 <= '1'; -- just ensure in case of weird targets
        elsif i_c3_cnt + 1 = STP_PWM_CNT_ON then
          i_coil3 <= '1';
        elsif i_c3_cnt = 0 then
          i_coil3 <= '0';
        end if;
      end if;
      
      if coil4_n = '0' then
        i_coil4 <= '1';
        i_c4_cnt <= (others=>'0');
      else
        i_c4_cnt <= i_c4_cnt + 1;
        if i_c4_cnt + 1 = STP_PWM_CNT_TARGET then
          i_c4_cnt <= (others=>'0');
          i_coil4 <= '1'; -- just ensure in case of weird targets
        elsif i_c4_cnt + 1 = STP_PWM_CNT_ON then
          i_coil4 <= '1';
        elsif i_c4_cnt = 0 then
          i_coil4 <= '0';
        end if;
      end if;
     
    end if;
  end process coil_ctrl;

  coil1 <= not i_coil1;
  coil2 <= not i_coil2;
  coil3 <= not i_coil3;
  coil4 <= not i_coil4;

END ARCHITECTURE rtl;
