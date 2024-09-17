LIBRARY std;
  USE std.textio.ALL;
LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;

ARCHITECTURE test OF i2cFifo_tester IS

  constant clockPeriod  : time          := 1.0/real(clockFrequency) * 1 sec;
  signal sClock         : std_ulogic    := '1';
  signal sReset         : std_ulogic ;

  constant i2cPeriod    : time          := 4.0/real(i2cFrequency) * 1 sec;

  signal start_stop     : std_ulogic;
  signal dataByte       : std_ulogic_vector(txData'length-2-1 downto 0);
  signal ack            : std_ulogic;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  sReset <= '1', '0' after 4*clockPeriod;
  reset <= sReset;

  sClock <= not sClock after clockPeriod/2;
  clock <= transport sClock after 0.9*clockPeriod;

  ------------------------------------------------------------------------------
                                                                     -- scl, sda

  sCl <= 'Z';
  sDa <= 'Z';

  ------------------------------------------------------------------------------
                                                                -- test sequence
  testSequence: process
  begin
    ack <= '1';
    start_stop <= '1';
    dataByte <= X"00";
    txWr <= '0';
    wait for 100 us;
    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );
                                                                 -- write a word
    write(output,
      "At time " & integer'image(now/1 us) & " us, " &
      "writing 2 bytes at address 0550h" &
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
                                                      -- send memory address H
    dataByte <= X"05";
    wait for clockPeriod;
                                                      -- send memory address L
    dataByte <= X"50";
    wait for clockPeriod;
                                                                  -- send data
    for index in 1 to 2 loop
      dataByte <= std_ulogic_vector(to_unsigned(index, dataByte'length));
      wait for clockPeriod;
    end loop;
                                                                  -- send stop
    start_stop <= '1';
    dataByte <= X"FF";
    wait for clockPeriod;
    txWr <= '0';
    wait for 6 * 8 * i2cPeriod;
                                                                  -- read a word
    write(output,
      "At time " & integer'image(now/1 us) & " us, " &
      "reading 2 bytes at address 0550h" &
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
                                                      -- send memory address H
    dataByte <= X"05";
    wait for clockPeriod;
                                                      -- send memory address L
    dataByte <= X"50";
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
    for index in 1 to 2 loop
      dataByte <= X"FF";
      wait for clockPeriod;
    end loop;
    ack <= '1';
                                                                  -- send stop
    start_stop <= '1';
    dataByte <= X"FF";
    wait for clockPeriod;
    txWr <= '0';

    wait;
  end process testSequence;

  txData <= start_stop & ack & dataByte;

  ------------------------------------------------------------------------------
                                                                    -- read FIFO
  rxRd <= not rxEmpty;

END ARCHITECTURE test;
