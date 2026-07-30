--===========================================================================--
--  Note : This model can be synthesized by Xilinx ISE.
--
--  Errors: : None known
--
--  Library : Common
--
--  Dependencies : None
--
--  Author : tristan.renon - adapted for Kart by axel.amand
--  School of Engineering (HEI/HES-SO)
--  Institute of Systems Engineering (ISI)
--  Rue de l'industrie 23
--  1950 Sion
--  Switzerland (CH)
--
--  Simulator : Mentor ModelSim V10.7c
--===========================================================================--
LIBRARY ieee;
  USE ieee.std_logic_1164.all;
  USE ieee.numeric_std.all;
 
library Common;
  use Common.CommonLib.all;

LIBRARY Kart;
  USE Kart.Kart.ALL;
  
ARCHITECTURE rtl OF crc8itu IS

  -- Calculated CRC
  signal CRC_in  : std_uLogic_vector(7 downto 0);
  -- CRC 0 bit value
  signal inv : std_ulogic;

  signal launched : std_ulogic;
  signal counter : unsigned(requiredBitNb(CRC_in'length)-1 downto 0);
  signal byte_in : std_ulogic_vector(7 downto 0);

BEGIN

  doCRC: process(reset, clock)
  begin
    if reset = '1' then
      CRC_in <= (others=>'0');
      counter <= (others=>'0');
      launched <= '0';
      byte_in <= (others=>'0');
    elsif rising_edge(clock) then
      if resetCRC = '1' then
          CRC_in <= (others=>'0');
          launched <= '0';
          counter <= (others=>'0');
      -- Begin the calculus
      elsif appendByte = '1' then
        launched <= '1';
        byte_in <= byteIn;
      -- Do the calculus for each bit
      elsif launched = '1' then
        -- Not all bits done
        if counter(counter'high) = '0' then
          counter <= counter + 1;
          CRC_in <= CRC_in(6 downto 2) & (CRC_in(1) xor inv) & (CRC_in(0) xor inv) & inv;
          byte_in <= byte_in sll 1;
        -- Done
        else
          counter <= (others=>'0');
          launched <= '0';
        end if;
      end if;
    end if;
  end process doCRC;
 
  inv <= byte_in(7) xor CRC_in(7);
  CRC <= CRC_in xor CRC_FINAL_XOR;
  crc_done <= not launched and not appendByte;
 
END ARCHITECTURE rtl;

