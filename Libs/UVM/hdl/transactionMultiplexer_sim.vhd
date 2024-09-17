LIBRARY std;
  USE std.textio.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE RTL OF transactionMultiplexer IS

BEGIN
  transferTransactions: process
  begin
    wait on transaction1, transaction2;
    if transaction1'transaction'event then
      transactionOut <= transaction1;
    else
      transactionOut <= transaction2;
    end if;
  end process transferTransactions;

END ARCHITECTURE RTL;
