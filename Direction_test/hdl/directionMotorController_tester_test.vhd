LIBRARY std;
  USE std.textio.ALL;

LIBRARY ieee;
  USE ieee.std_logic_textio.ALL;

LIBRARY Common_test;
  USE Common_test.testutils.all;

Library Kart;
  Use Kart.Kart.all;

ARCHITECTURE test OF directionMotorController_tester IS

  constant clockPeriod  : time := 1.0/CLOCK_FREQUENCY * 1 sec;
  signal sClock         : std_uLogic := '1';
  signal sReset         : std_uLogic ;

  constant testInterval : time := 200 us;
  signal testInfo       : string(1 to 40) := (others => ' ');

  -- Registers definitions
  constant dcmotBaseReadAddr : natural := REG_DMOT_ADDR * 2**6;
  constant dcmotBaseWriteAddr : natural := dcmotBaseReadAddr + 1 * 2**5;

BEGIN
  ------------------------------------------------------------------------------
                                                              -- reset and clock
  sReset <= '1', '0' after 4*clockPeriod;
  reset <= sReset;

  sClock <= not sClock after clockPeriod/2;
  clock <= transport sClock after 0.9*clockPeriod;

  ------------------------------------------------------------------------------
                                                                -- test sequence
  process

      procedure setReg(constant address : in natural;
                       constant data    : in natural) is
      begin
        assert(
          to_unsigned(address, addressIn'length)(REG_ADDR_GET_BIT_POSITION)
          = '1') report "Address is not writable" severity failure;
        addressIn <= symbolSizeType(to_unsigned(address, addressIn'length));
        dataIn <= dataRegisterType(to_unsigned(data, dataIn'length));
        regWr <= '1', '0' after clockPeriod * 1.1;
      end procedure;


      procedure readReg(constant address : in natural) is
      begin
        assert(
          to_unsigned(address, addressIn'length)(REG_ADDR_GET_BIT_POSITION)
          = '0') report "Address is not readable" severity failure;
        addressIn <= symbolSizeType(to_unsigned(address, addressIn'length));
        dataIn <= dataRegisterType(to_unsigned(0, dataIn'length));
        regWr <= '1', '0' after clockPeriod * 1.1;
      end procedure;

      variable time1, time2 : time := 0 ns;

  begin
    -- Init signals
    dataIn <= (others=>'0');
    addressIn <= (others=>'0');
    regWr <= '0';
    dmotSendAuth <= '1';

    wait for 1 ns;
    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );

    -- Set servo to 0
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending servo command 0 at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(dcmotBaseWriteAddr + DMOT_TARGETANGLE_REG_POS, 0);
    wait for 50 ms;

    -- Set servo to 50
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending servo command 0 at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(dcmotBaseWriteAddr + DMOT_TARGETANGLE_REG_POS, 50);
    wait for 50 ms;

    -- Set servo to half
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending servo command half at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(dcmotBaseWriteAddr + DMOT_TARGETANGLE_REG_POS, natural(2**DMOT_TARGETCMD_BIT_NB / 2));
    wait for 50 ms;

    -- Set servo to full
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending servo command full at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(dcmotBaseWriteAddr + DMOT_TARGETANGLE_REG_POS, natural(2**DMOT_TARGETCMD_BIT_NB - 1));
    wait for 50 ms;

    -- Set servo over full
    testInfo <= pad("Init", testInfo'length);
    wait for testInterval;
    write(output,
      "Sending servo command too big at time " & integer'image(now/1 us) & " us" &
      lf & lf
    );
    setReg(dcmotBaseWriteAddr + DMOT_TARGETANGLE_REG_POS, natural(2**(DMOT_TARGETCMD_BIT_NB+1)));
    wait for 50 ms;




    -- end of simulation
    write(output, "" & lf & lf & lf & lf & lf & lf);
    testInfo <= pad("End of simulation", testInfo'length);
    wait for 10*testInterval;
    assert false
      report "End of simulation"
      severity failure;
    wait;
  end process;

END ARCHITECTURE test;
