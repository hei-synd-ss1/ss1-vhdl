LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmUARTMonitor IS

  constant uartDataBitNb: positive := 8;
  signal baudPeriod: time;
  signal rxWord, txWord: natural;
  signal startup, rxReceived, txReceived: std_ulogic;

BEGIN
  ------------------------------------------------------------------------------
  baudPeriod <= 1.0/baudRate * 1 sec;

  ------------------------------------------------------------------------------
                                                                  -- receive RxD
  receiveRxD: process
    variable rxData: unsigned(uartDataBitNb-1 downto 0);
  begin
    rxReceived <= '0';
                                                                    -- start bit
    wait until falling_edge(RxD);
    wait for 1.5 * baudPeriod;
                                                                    -- data bits
    for index in rxData'reverse_range loop
      rxData(index) := RxD;
      wait for baudPeriod;
    end loop;
                                                            -- store information
    rxWord <= to_integer(rxData);
    rxReceived <= '1';
    wait for 0 ns;
  end process receiveRxD;

  ------------------------------------------------------------------------------
                                                                  -- receive RxD
  receiveTxD: process
    variable txData: unsigned(uartDataBitNb-1 downto 0);
  begin
    txReceived <= '0';
                                                                    -- start bit
    wait until falling_edge(TxD);
    wait for 1.5 * baudPeriod;
                                                                    -- data bits
    for index in txData'reverse_range loop
      txData(index) := TxD;
      wait for baudPeriod;
    end loop;
                                                            -- store information
    txWord <= to_integer(txData);
    txReceived <= '1';
    wait for 0 ns;
  end process receiveTxD;

  --============================================================================
                                                              -- monitor acesses
  startup <= '1', '0' after 1 ns;

  reportBusAccess: process(startup, rxReceived, txReceived, badCRC, watchdogError)
  begin
--    if startup = '1' then
--      uartMonitor <= pad(
--        "idle",
--        uartMonitor'length
--      );
--    els
    if rising_edge(rxReceived) then
      uartMonitor <= pad(
        "UART sent " & sprintf("%02X", rxWord),
        uartMonitor'length
      );
    elsif rising_edge(txReceived) then
      uartMonitor <= pad(
        "UART received " & sprintf("%02X", txWord),
        uartMonitor'length
      );
    elsif rising_edge(badCRC) then
      uartMonitor <= pad(
        "UART CRCs do not match",
        uartMonitor'length
      );
    elsif rising_edge(watchdogError) then
      uartMonitor <= pad(
        "UART timed out while waiting for frame",
        uartMonitor'length
      );
    end if;
  end process reportBusAccess;

END ARCHITECTURE rtl;
