--
-- VHDL Architecture Kart.reg_addr_decoder.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 10:49:17 12.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.all;

ARCHITECTURE rtl OF reg_addr_decoder IS

signal p_module_selected : std_ulogic;

BEGIN

  p_module_selected <= '1' when address(address'high downto address'high - 
      REG_ADDR_MSB_NB_BITS + 1) = std_ulogic_vector(to_unsigned(moduleAddr, REG_ADDR_MSB_NB_BITS)) and wr = '1' else '0';

  loadRegister <= '1' when p_module_selected = '1' and address(REG_ADDR_GET_BIT_POSITION) = FRAME_WBIT_VALUE else '0';
  readRegister <= '1' when p_module_selected = '1' and address(REG_ADDR_GET_BIT_POSITION) = not FRAME_WBIT_VALUE else '0';

END ARCHITECTURE rtl;
