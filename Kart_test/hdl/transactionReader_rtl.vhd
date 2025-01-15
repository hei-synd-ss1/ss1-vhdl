LIBRARY std;
  USE std.textio.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;
Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE rtl OF transactionReader IS

  signal info : string(transactionIn'range)
    := pad("", transactionIn'length);
  signal target : string(transactionIn'range)
    := pad("", transactionIn'length);

BEGIN
  ------------------------------------------------------------------------------
                                                         -- interpret frame file
  parseFile: process
    file driverFile : text;
    variable driverLine : line;
    variable preComment : line;
    variable command : line;
    variable delay : time;
    variable address : line;
    variable ind1, ind2 : integer range 0 to 255;
    variable hexv : std_logic_vector(7 downto 0) := (others=>'0');
    variable skipcommands : std_ulogic := '0';
  begin
    if verbosity > 2 then
      transactionIn <= pad("idle", transactionIn'length);
      print("Opening driver sequence file " & driverFileSpec);
    end if;

    file_open(driverFile, driverFileSpec, READ_MODE);
    while not endfile(driverFile) loop
      readline (driverFile, driverLine);
      read_first(driverLine, "#", preComment);
      driverLine := preComment;
      trim_line(driverLine);
      if driverLine.all'length > 0 then
        --lc(driverLine);
        if verbosity > 2 then
          print(driverLine.all);
        end if;
        read_first(driverLine, command);

        if command.all = "skip" then
          skipcommands := '1';
        elsif command.all = "endskip" then
          skipcommands := '0';
        elsif skipcommands = '0' then
          if verbosity > 2 then
            print(command.all & ":" & driverLine.all & "(" & sprintf("%tn", now) & ")");
          end if;

          if command.all = "info" then
            if verbosity > 0 then
              print("================================" & cr & cr & "================================");
              print("Step: " & driverLine.all);
              print("Began at: " & sprintf("%tn", now));
              info <= pad(driverLine.all, transactionIn'length);
            end if;

          elsif command.all = "target" then
            target <= pad(driverLine.all, transactionIn'length);

          elsif command.all = "at" then
            if verbosity > 1 then
              print(" * Advancing simulation to time " & driverLine.all);
            end if;
            delay := sscanf(driverLine.all);
            wait for delay - now;

          elsif command.all = "wait" then
            if verbosity > 1 then
              print(" * Advancing simulation of step " & driverLine.all);
            end if;
            delay := sscanf(driverLine.all);
            wait for delay;

          elsif command.all = "end_sim" then
            if verbosity > 0 then
              print(cr & cr & "================================");
              print("================================");
              print("Simulation end");
              print("================================");
              print("================================");
            end if;
            assert false
              report "Simulation end"
              severity failure;
            wait;

          elsif command.all = "read_reg_range" then
            if verbosity > 0 then
              print(" * Reading all regs.");
            end if;

            read_first(driverLine, command);
            hread(command, hexv);
            ind1 := to_integer(unsigned(hexv));
            read_first(driverLine, command);
            hread(command, hexv);
            ind2 := to_integer(unsigned(hexv));
            delay := sscanf(driverLine.all);

            for index in ind1 to ind2 loop
              -- Security to not write accidentally if bad range
              if to_unsigned(index, UART_BIT_NB)
                (REG_ADDR_GET_BIT_POSITION) = '0' then

                transactionIn <= pad(" ", transactionIn'length);
                wait for 0 ns;
                transactionIn <= pad(
                  "read_reg " & to_hstring(to_signed(index, UART_BIT_NB)),
                  transactionIn'length
                );
                wait for delay;

              end if;
            end loop;

          else
            transactionIn <= pad(" ", transactionIn'length);
            wait for 0 ns;
            transactionIn <= pad(
              command.all & " " & driverLine.all,
              transactionIn'length
            );
            if verbosity > 2 then
              print(command.all & " " & driverLine.all);
            end if;
          end if;
        end if;
        -- Advance time by one delta simulation step
        wait for 0 ns;

      end if;
    end loop;
    file_close(driverFile);

    wait;
  end process parseFile;

END ARCHITECTURE rtl;
