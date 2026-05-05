LIBRARY std;
  USE std.textio.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmSupervisor IS
BEGIN
  ------------------------------------------------------------------------------
                                                           -- prepare empty file
  createFile: process
    file monitorFile : text;
  begin
    if verbosity > 0 then
      print("Creating file " & monitorFileSpec);
    end if;
    file_open(monitorFile, monitorFileSpec, WRITE_MODE);
    file_close(monitorFile);
    wait;
  end process createFile;

  ------------------------------------------------------------------------------
                                                   -- write transactions to file
  writeToFile: process
    file monitorFile : text;
    variable transactionLine : line;
  begin
    wait on monitorTransaction;
    if verbosity > 0 then
      print("   At " & sprintf("%tn", now) & " : " & monitorTransaction);
    end if;
                                                             -- add line to file
    file_open(monitorFile, monitorFileSpec, APPEND_MODE);
    transactionLine := new string'(
      "at " & sprintf("%tn", now) & " " & monitorTransaction
    );
    writeline(monitorFile, transactionLine);
    file_close(monitorFile);
  end process writeToFile;

END ARCHITECTURE rtl;

