LIBRARY std;
  USE std.textio.ALL;
LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;

ARCHITECTURE test OF i2cTransceiver_tester IS

  constant clockPeriod  : time          := 1.0/real(clockFrequency) * 1 sec;
  signal sClock         : std_ulogic    := '1';
  signal sReset         : std_ulogic ;

  constant i2cPeriod    : time          := 4.0/real(i2cFrequency) * 1 sec;

  subtype dataByteType  is std_ulogic_vector(txData'length-2-1 downto 0);
  signal start_stop     : std_ulogic;
  signal dataByte       : dataByteType;
  signal ack            : std_ulogic;

  constant registerNb   : positive := 8;
  type registerBankType is array (registerNb-1 downto 0) of dataByteType;
  signal registerBank   : registerBankType := (others => (others => '0'));

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  sReset <= '1', '0' after 4*clockPeriod;
  reset <= sReset;

  sClock <= not sClock after clockPeriod/2;
  clock <= transport sClock after 0.9*clockPeriod;

  --============================================================================
                                                                -- test sequence
  testSequence: process
  begin
    ack <= '1';
    start_stop <= '1';
    dataByte <= X"00";
    txWr <= '0';
    wait for 10 * i2cPeriod;
    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );
    ----------------------------------------------------------------------------
                                                                 -- write a word
    write(output,
      "At time " & integer'image(now/1 us) & " us, " &
      "writing 4 bytes to chip with address A2h from register 03h on" &
      lf & lf
    );
    wait until rising_edge(sClock);
    txWr <= '1';
                                                                 -- send start
    start_stop <= '1';
    dataByte <= X"00";
    wait for clockPeriod;
    start_stop <= '0';
                                                          -- send chip address
    dataByte <= X"A2";
    wait for clockPeriod;
                                                      -- send register address
    dataByte <= X"03";
    wait for clockPeriod;
                                                                  -- send data
    for index in 1 to 4 loop
      dataByte <= std_ulogic_vector(to_unsigned(index, dataByte'length));
      wait for clockPeriod;
    end loop;
                                                                  -- send stop
    start_stop <= '1';
    dataByte <= X"FF";
    wait for clockPeriod;
    txWr <= '0';
    wait for 7 * 9 * i2cPeriod;
    ----------------------------------------------------------------------------
                                                                  -- read a word
    wait for 10 * i2cPeriod;
    write(output,
      "At time " & integer'image(now/1 us) & " us, " &
      "reading 4 bytes to chip with address A2h from register 03h on" &
      lf & lf
    );
    wait until rising_edge(sClock);
    txWr <= '1';
                                                                 -- send start
    start_stop <= '1';
    dataByte <= X"00";
    wait for clockPeriod;
    start_stop <= '0';
                                  -- send chip address to write memory address
    dataByte <= X"A2";
    wait for clockPeriod;
                                                      -- send register address
    dataByte <= X"03";
    wait for clockPeriod;
                                                                 -- send start
    start_stop <= '1';
    dataByte <= X"00";
    wait for clockPeriod;
    start_stop <= '0';
                                         -- send chip address with read access
    dataByte <= X"A2" or X"01";
    wait for clockPeriod;
                                                                  -- read data
    ack <= '0';
    for index in 1 to 4-1 loop
      dataByte <= X"FF";
      wait for clockPeriod;
    end loop;
    ack <= '1';
    dataByte <= X"FF";
    wait for clockPeriod;
                                                                  -- send stop
    start_stop <= '1';
    dataByte <= X"FF";
    wait for clockPeriod;
    txWr <= '0';

    wait;
  end process testSequence;

  txData <= start_stop & ack & dataByte;

  ------------------------------------------------------------------------------
                                                            -- selection control
  isSelected <= '1' when chipAddr = shift_right(X"A2", 1)
    else '0';

  --============================================================================
                                                                -- register bank
  updateRegister: process
  begin
    wait until rising_edge(dataValid);
    if  (writeData = '1') and (registerAddr <= registerBank'high) then
      registerBank(to_integer(registerAddr)) <= dataIn;
    end if;
  end process;

  dataOut <= registerBank(to_integer(registerAddr)) when writeData = '0'
    else (others => '0');

  --============================================================================
                                                                    -- read FIFO
  rxRd <= not rxEmpty;

END ARCHITECTURE test;
