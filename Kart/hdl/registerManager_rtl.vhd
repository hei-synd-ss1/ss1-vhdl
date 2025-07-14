--
-- VHDL Architecture Kart.registerManager.rtl
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 13:15:36 12.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF registerManager IS

  -- Registers
    -- Actual registers bank
  signal p_registers : registersHolderType(registersNb-1 downto 0);
  signal p_int_reg_addr : REG_COUNT_RANGE;
BEGIN

  p_int_reg_addr <= to_integer(unsigned(addressIn(REG_ADDR_REG_RANGE)));

  -- Registers read
  bankData <= p_registers;

  --------------------------------------------------------------

  -- Registers input
  register_input: process(reset,clock)
  begin
    if reset = '1' then
      p_registers <= (others=>(others=>'0'));
    elsif rising_edge(clock) then
      -- On load + ensure register exists
      if loadNew = '1' and p_int_reg_addr < registersNb then
        p_registers(p_int_reg_addr) <= dataIn;
      end if;
    end if;
  end process register_input;

END ARCHITECTURE rtl;
