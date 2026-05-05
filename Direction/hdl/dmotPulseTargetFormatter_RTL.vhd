-- Format input command to a corresponding clock pulse count value
-- Axam

LIBRARY Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE RTL OF dmotPulseTargetFormatter IS

  signal lvec_command : unsigned( VALUE_BIT_NB-1 DOWNTO 0 );
  signal lvec_target : unsigned( VALUE_BIT_NB-1 DOWNTO 0 );

BEGIN

  lvec_command <= unsigned(targetCommand) when unsigned(targetCommand(targetCommand'high downto DMOT_TARGETCMD_BIT_NB)) = 0 else (DMOT_TARGETCMD_BIT_NB to targetCommand'high => '0') & (0 to DMOT_TARGETCMD_BIT_NB-1 => '1');

  process(reset, clock)
  begin
    if reset = '1' then
      lvec_target <= (others => '0');
    elsif rising_edge(clock) then
      lvec_target <= DMOT_MINCMD_CLOCKS + resize((DMOT_CMD_CLOCKS_STEP * lvec_command), lvec_target'length);
    end if;
  end process;


  target <= lvec_target;

END ARCHITECTURE RTL;
