LIBRARY std;
  USE std.textio.all;
  use std.env.stop;

LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE RTL OF driverControl IS

  signal info : string(driverTransaction'range)
    := pad("", driverTransaction'length);
  signal target : string(driverTransaction'range)
    := pad("", driverTransaction'length);

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
    variable skipcommands : std_ulogic := '0';

  begin
    if verbosity > 2 then
      driverTransaction <= pad("idle", driverTransaction'length);
      print("Opening driver sequence file " & driverFileSpec);
    end if;

    file_open(driverFile, driverFileSpec, READ_MODE);
    while not endfile(driverFile) loop
      readline (driverFile, driverLine);
      read_first(driverLine, "#", preComment);
      driverLine := preComment;
      trim_line(driverLine);
      if driverLine.all'length > 0 then
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
            print(command.all & ":" & driverLine.all);
          end if;
          if command.all = "info" then
            if verbosity > 0 then
              print("================================" & cr & cr & "================================");
              print("Step: " & driverLine.all);
              print("Began at: " & sprintf("%tn", now));
              info <= pad(driverLine.all, driverTransaction'length);
            end if;
          
          elsif command.all = "target" then
            target <= pad(driverLine.all, driverTransaction'length);
          
          elsif command.all = "at" then
            if verbosity > 1 then
              print(cr & "Advancing simulation to time " & driverLine.all);
            end if;
            delay := sscanf(driverLine.all);
            wait for delay - now;
          
          elsif command.all = "wait" then
            if verbosity > 1 then
              print(cr &"Advancing simulation of step " & driverLine.all);
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
              severity note;
            stop; 
            wait;
           
          else
            driverTransaction <= pad(" ", driverTransaction'length);
            wait for 0 ns;
            driverTransaction <= pad(
              command.all & " " & driverLine.all,
              driverTransaction'length
            );
            if verbosity > 0 then
              print(command.all & " " & driverLine.all);
            end if;
          end if;
        end if;
      end if;
      -- Execute one delta simulation step (no time change, but line is executed)
      wait for 0 ns;
    end loop;
    file_close(driverFile);

    wait;
  end process parseFile;

END ARCHITECTURE RTL;
