LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE sim OF stringPacker IS

  signal rxString, txString : string(transactionOut'range) := (others => ' ');


BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  interpretTransaction: process
    variable myLine, commandPart : line;
    variable inputChar : character;
    variable receivedIndex, sentIndex : natural := 1;
    variable receivedString, sentString : string(transactionOut'range)
      := (others => ' ');
  begin
    wait until transactionIn'transaction'event;
    write(myLine, transactionIn);
    rm_side_separators(myLine);
--print(myLine.all);
    read_first(myLine, commandPart);
    if commandPart.all = "uart" then
      read_first(myLine, commandPart);
      if commandPart.all = "received" then
        if myLine.all = "0D" then
          rxString <= pad(
            receivedString(1 to receivedIndex-1),
            rxString'length);
          transactionOut <= pad(
            "received " & '"' & receivedString(3 to receivedIndex-1) & '"',
            transactionOut'length
          );
          receivedIndex := 1;
        else
          inputchar := character'val(sscanf(myLine.all));
          receivedString(receivedIndex) := inputchar;
          receivedIndex := receivedIndex + 1;
        end if;
      elsif commandPart.all = "sent" then
        if myLine.all = "0D" then
          txString <= pad(
            sentString(1 to sentIndex-1),
            transactionOut'length
          );
          transactionOut <= pad(
            "sent " & '"' & sentString(1 to sentIndex-1) & '"',
            transactionOut'length
          );
          sentIndex := 1;
        else
          inputchar := character'val(sscanf(myLine.all));
          sentString(sentIndex) := inputchar;
          sentIndex := sentIndex + 1;
        end if;
      end if;
    end if;
    deallocate(myLine);
  end process interpretTransaction;

END ARCHITECTURE sim;
