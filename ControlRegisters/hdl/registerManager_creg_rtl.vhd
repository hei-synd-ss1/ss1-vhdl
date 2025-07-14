Library Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE rtl OF registerManager_creg IS

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
        -- Cannot rely on address (as could be frozen from an older command)
        -- Plus must be an elsif, else may overload config register if written
        --  at the same time before.
      elsif p_registers(CR_HARDWARE_CONTROL_REG_POS)(HW_CTRL_RESTART_BIT) = '1'
        and stepperEnd = '1' then
        p_registers(CR_HARDWARE_CONTROL_REG_POS)(HW_CTRL_RESTART_BIT) <= '0';
      end if;
    end if;
  end process register_input;

END ARCHITECTURE rtl;
