--
-- VHDL Architecture Stepper_test.stepperMotorRegisters_tester.test
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 09:04:47 16.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

Library Kart;
  USE Kart.Kart.all;

LIBRARY Common_test;
  USE Common_test.testutils.all;

LIBRARY std;
  USE std.textio.ALL;

library ieee;
  USE ieee.std_logic_textio.ALL;
  use ieee.math_real.all;

ARCHITECTURE test OF directionMotorRegisters_tester IS

  constant clockPeriod  : time := 1.0/CLOCK_FREQUENCY * 1 sec;
  signal sClock         : std_uLogic := '1';
  signal sReset         : std_uLogic ;
  signal testInfo       : string(1 to 40) := (others => ' ');

BEGIN

  sReset <= '1', '0' after 4*clockPeriod;
  reset <= sReset;

  sClock <= not sClock after clockPeriod/2;
  clock <= transport sClock after 0.9*clockPeriod;

  process
  begin
    testInfo <= pad("directionMotor Test Bench", testInfo'length);
    addressIn <= symbolSizeType(to_unsigned(0, addressIn'length));
    dataIn <= dataRegisterType(to_unsigned(0, dataIn'length));
    regWr <= '0';
    dmotSendAuth <= '0';

    wait for 5 us;
    write(output,
      lf & lf & lf &
      "----------------------------------------------------------------" & lf &
      "-- Starting testbench" & lf &
      "--" &
      lf & lf
    );
    wait until rising_edge(clock);


    -- Load the registers
    for indx in 0 to DMOT_REG_COUNT-1 loop
      testInfo <= pad("Loading register " & to_string(indx), testInfo'length);
      wait for clockPeriod;
      addressIn <= symbolSizeType'(
        std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
        & FRAME_WBIT_VALUE &
        std_ulogic_vector(to_unsigned(indx, REG_ADDR_MAXNBREG_BITS))
      );
      dataIn <= dataRegisterType(to_unsigned(indx+1, dataIn'length));
      regWr <= '1', '0' after clockPeriod;
      wait for 50*clockPeriod;
    end loop;

    assert unsigned(customReg1) = to_unsigned(2, customReg1'length)
      report "customReg1 is not loaded correctly"
      severity failure;
    assert unsigned(customReg2) = to_unsigned(3, customReg2'length)
      report "customReg2 is not loaded correctly"
      severity failure;
    assert unsigned(customReg3) = to_unsigned(4, customReg3'length)
      report "customReg3 is not loaded correctly"
      severity failure;

    -- Send a data with wrong address asking for a send
    testInfo <= pad("Ask data but wrong address", testInfo'length);
    addressIn <= symbolSizeType'(
        std_ulogic_vector(to_unsigned(REG_DMOT_ADDR+1, REG_ADDR_MSB_NB_BITS))
        & not FRAME_WBIT_VALUE &
        std_ulogic_vector(to_unsigned(0, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(0, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;
    assert dmotSendRequest = '0'
      report "System should not answer to the wrong address"
      severity failure;
    wait for 50*clockPeriod;

    -- Ask to send a register
    testInfo <= pad("Ask for target", testInfo'length);
    addressIn <= symbolSizeType'(
        std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
        & not FRAME_WBIT_VALUE &
        std_ulogic_vector(to_unsigned(DMOT_CUSTOM2_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= (others=> '1');
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;
    assert dmotSendRequest = '1' and 
      dmotDataToSend = dataRegisterType(to_unsigned(DMOT_CUSTOM2_REG_POS+1, dataIn'length)) and
      dmotAddressToSend = addressIn
      report "System should answer to the address"
      severity failure;
    wait for 100*clockPeriod;
    dmotSendAuth <= '1', '0' after 1.05*clockPeriod;
    wait for 2*clockPeriod;
    assert dmotSendRequest = '0'
      report "System should stop sending"
      severity failure;
    wait for 50*clockPeriod;

    -- Test a few values for servomotor commands
    testInfo <= pad("Servomotor command 0", testInfo'length);
    wait for clockPeriod;
    addressIn <= symbolSizeType'(
      std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
      & FRAME_WBIT_VALUE &
      std_ulogic_vector(to_unsigned(DMOT_TARGETANGLE_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(0, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;

    testInfo <= pad("Servomotor command 60", testInfo'length);
    wait for clockPeriod;
    addressIn <= symbolSizeType'(
      std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
      & FRAME_WBIT_VALUE &
      std_ulogic_vector(to_unsigned(DMOT_TARGETANGLE_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(60, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;
    
    testInfo <= pad("Servomotor command 157", testInfo'length);
    wait for clockPeriod;
    addressIn <= symbolSizeType'(
      std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
      & FRAME_WBIT_VALUE &
      std_ulogic_vector(to_unsigned(DMOT_TARGETANGLE_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(157, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;
    
    testInfo <= pad("Servomotor command 223", testInfo'length);
    wait for clockPeriod;
    addressIn <= symbolSizeType'(
      std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
      & FRAME_WBIT_VALUE &
      std_ulogic_vector(to_unsigned(DMOT_TARGETANGLE_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(223, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;
    
    testInfo <= pad("Servomotor command 254", testInfo'length);
    wait for clockPeriod;
    addressIn <= symbolSizeType'(
      std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
      & FRAME_WBIT_VALUE &
      std_ulogic_vector(to_unsigned(DMOT_TARGETANGLE_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(254, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;
    
    testInfo <= pad("Servomotor command 255", testInfo'length);
    wait for clockPeriod;
    addressIn <= symbolSizeType'(
      std_ulogic_vector(to_unsigned(REG_DMOT_ADDR, REG_ADDR_MSB_NB_BITS))
      & FRAME_WBIT_VALUE &
      std_ulogic_vector(to_unsigned(DMOT_TARGETANGLE_REG_POS, REG_ADDR_MAXNBREG_BITS))
    );
    dataIn <= dataRegisterType(to_unsigned(255, dataIn'length));
    regWr <= '1', '0' after clockPeriod;
    wait for 2*clockPeriod;

    -- End
    wait for 50*clockPeriod;
    assert false
      report "End of simulation"
      severity failure;
    wait;
  end process;

END ARCHITECTURE test;
