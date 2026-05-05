LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmCRMonitor IS

  signal p_startup : std_ulogic;
  signal p_state : std_ulogic_vector(5 downto 0) := (others=>'0');

BEGIN

  p_startup <= '1', '0' after 1 ns;


  interpretTransaction: process(transactionIn)
    variable myLine : line;
    variable commandPart, argPart : line;
    variable argm : integer := 0;
    variable regv : std_ulogic_vector(5 downto 0);
  begin
    write(myLine, transactionIn);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "cr_hw_control" then
      -- Reg. data
      regv := (others=>'0');
      for index in 5 downto 0 loop
        read_first(myLine, argPart);
        read(argPart, argm);
        regv(index) := '1' when argm /= 0 else '0';
      end loop;
      p_state <= regv;
    end if;
    deallocate(myLine);
  end process interpretTransaction;

  reportBusAccess: process(p_startup, p_state)
    variable waitingForFreq : std_ulogic := '0';
  begin
--    if p_startup = '1' then
--      cregMonitor <= pad(
--        "idle",
--        cregMonitor'length
--      );
--    els
    if p_state'event then
      cregMonitor <= pad(
        "Setting HWOrientation" &
        cr & "    - BT Conn. : " & sprintf("%b", p_state(0)) &
        cr & "    - Restart : " & sprintf("%b", p_state(1)) &
        cr & "    - EndSW : " & sprintf("%b", p_state(2)) &
        cr & "    - Angles : " & sprintf("%b", p_state(3)) &
        cr & "    - CW : " & sprintf("%b", p_state(4)) &
        cr & "    - Fwd : " & sprintf("%b", p_state(5)),
        cregMonitor'length
      );
    end if;
  end process reportBusAccess;

END ARCHITECTURE rtl;
