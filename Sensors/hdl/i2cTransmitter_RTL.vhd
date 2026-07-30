library Common;
  use Common.CommonLib.all;

architecture RTL of i2cTransmitter is

  signal sendStart: std_ulogic;
  signal sendStop: std_ulogic;
  signal dividerCounter: unsigned(requiredBitNb(baudRateDivide)-1 downto 0);
  signal dividerCounterReset: std_uLogic;
  signal send1: std_uLogic;
  signal send2: std_uLogic;
  signal sendSynch: std_uLogic;
  signal txCountEnable: std_uLogic;
  signal txShiftEnable: std_uLogic;
  signal phaseCounter: unsigned(1 downto 0);
  signal txShiftReg: std_ulogic_vector(dataIn'high downto 0);
  signal txSending: std_uLogic;
  signal txSendingDelayed: std_uLogic;
  signal txSendingEnd: std_uLogic;
  signal busyInt: std_uLogic;

begin
  ------------------------------------------------------------------------------
        -- check the MSB in order to differentiate start/stop from normal access
  checkMode: process(reset, clock)
  begin
    if reset = '1' then
      sendStart <= '0';
      sendStop <= '0';
    elsif rising_edge(clock) then
      if send = '1' then
        sendStart <= '0';
        sendStop <= '0';
        if dataIn(dataIn'high) = '1' then
          if dataIn(1) = '0' then
            sendStart <= '1';
          else
            sendStop <= '1';
          end if;
        end if;
      end if;
    end if;
  end process checkMode;

  ------------------------------------------------------------------------------
                                                           -- build I2c bit rate
  divide: process(reset, clock)
  begin
    if reset = '1' then
      dividerCounter <= (others => '0');
    elsif rising_edge(clock) then
      if dividerCounterReset = '1' then
        dividerCounter <= to_unsigned(1, dividerCounter'length);
      else
        dividerCounter <= dividerCounter + 1;
      end if;
    end if;
  end process divide;

  endOfCount: process(dividerCounter, send1)
  begin
    if dividerCounter = baudRateDivide then
      dividerCounterReset <= '1';
    else
      dividerCounterReset <= '0';
    end if;
  end process endOfCount;

  txCountEnable <= dividerCounterReset;

  shiftSend: process(reset, clock)
  begin
    if reset = '1' then
      send1 <= '0';
      send2 <= '0';
    elsif rising_edge(clock) then
      if send = '1' then
        send1 <= '1';
      elsif txCountEnable = '1' then
        send1 <= '0';
      end if;
      send2 <= send1;
    end if;
  end process shiftSend;

  sendSynch <= '1' when (send2 = '1') and (send1 = '0') else '0';

  buildPhases: process(reset, clock)
  begin
    if reset = '1' then
      phaseCounter <= (others => '0');
    elsif rising_edge(clock) then
      if sendSynch = '1' then
        phaseCounter <= (others => '0');
      elsif txCountEnable = '1' then
        phaseCounter <= phaseCounter + 1;
      end if;
    end if;
  end process buildPhases;

  txShiftEnable <= txCountEnable when (phaseCounter = 0) and (txSending = '1') else '0';

  ------------------------------------------------------------------------------
                                                              -- data serializer
  shiftReg: process(reset, clock)
  begin
    if reset = '1' then
      txShiftReg <= (others => '1');
    elsif rising_edge(clock) then
      if send = '1' then
        -- move ack bit from MSB to LSB
        txShiftReg <= dataIn(dataIn'high-2 downto 0) & dataIn(dataIn'high-1) & '0';
      elsif txShiftEnable = '1' then
        txShiftReg(txShiftReg'high downto 1) <= txShiftReg(txShiftReg'high-1 downto 0);
        -- fill shift register with 1's to determine when all has been sent
        txShiftReg(0) <= '1';
      end if;
    end if;
  end process shiftReg;

  ------------------------------------------------------------------------------
                                                                 -- serial clock
  buildClock: process(reset, clock)
  begin
    if reset = '1' then
      sCl <= '1';
    elsif rising_edge(clock) then
      if txSending = '1' then
        if phaseCounter = 1  then
          sCl <= '1';
        elsif phaseCounter = 3  then
          sCl <= '0';
        end if;
      end if;
    end if;
  end process buildClock;

  ------------------------------------------------------------------------------
                                                                  -- serial data
  buildData: process(reset, clock)
  begin
    if reset = '1' then
      sDa <= '1';
    elsif rising_edge(clock) then
      if txSending = '1' then
        if sendStart = '1' then
          if phaseCounter = 0 then
            sDa <= '1';
          elsif phaseCounter = 2 then
            sDa <= '0';
          end if;
        elsif sendStop = '1' then
          if phaseCounter = 0 then
            sDa <= '0';
          elsif phaseCounter = 2 then
            sDa <= '1';
          end if;
        elsif phaseCounter = 0 then
          sDa <= txShiftReg(txShiftReg'high);
        end if;
      end if;
    end if;
  end process buildData;

  ------------------------------------------------------------------------------
                                                                   -- byte frame
  frameEnvelope: process(reset, clock)
  begin
    if reset = '1' then
      txSending <= '0';
    elsif rising_edge(clock) then
      if sendSynch = '1' then
        txSending <= '1';
      elsif sendStart = '1' then
        if phaseCounter = 3 then
          txSending <= '0';
        end if;
      elsif sendStop = '1' then
        if phaseCounter = 2 then
          txSending <= '0';
        end if;
      elsif txShiftReg(txShiftReg'high-1 downto 0) = (txShiftReg'high-1 downto 0 => '1') then
        if phaseCounter = 3 then
          txSending <= '0';
        end if;
      end if;
    end if;
  end process frameEnvelope;

  delayEnvelope: process(reset, clock)
  begin
    if reset = '1' then
      txSendingDelayed <= '0';
    elsif rising_edge(clock) then
      txSendingDelayed <= txSending;
    end if;
  end process delayEnvelope;

  txSendingEnd <= '1' when (txSendingDelayed = '1') and (txSending = '0') else '0';

  buildBusy: process(reset, clock)
  begin
    if reset = '1' then
      busyInt <= '0';
    elsif rising_edge(clock) then
      if send = '1' then
        busyInt <= '1';
      elsif txSendingEnd = '1' then
        busyInt <= '0';
      end if;
    end if;
  end process buildBusy;

  busy <= busyInt;

end RTL;
