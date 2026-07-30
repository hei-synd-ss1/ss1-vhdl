LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE RTL OF parallelInMonitor IS

BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  buildTransaction: process(parallelIn)
  begin
    transaction <= pad(
      reportStart & " " & sprintf("%X", parallelIn),
      transaction'length
    );
  end process buildTransaction;

END ARCHITECTURE RTL;
