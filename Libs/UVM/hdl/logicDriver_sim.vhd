LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE RTL OF logicDriver IS

  signal commandValue : natural := 0;

BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  interpretTransaction: process(transaction)
    variable myLine : line;
    variable commandPart : line;
  begin
    write(myLine, transaction);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = command then
      commandValue <= sscanf(myLine.all);
    end if;
    deallocate(myLine);
  end process interpretTransaction;

  logicOut <= '0' when commandValue = 0
    else '1';

END ARCHITECTURE RTL;
