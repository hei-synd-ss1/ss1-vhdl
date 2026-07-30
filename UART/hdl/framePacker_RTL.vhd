--
-- VHDL Architecture UART.framePacker.RTL
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 20:26:35 11.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

LIBRARY Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE RTL OF framePacker IS

  -- State machine states
  type statesType is (
      idle, load_header, sending_header,
      sending_addr, sending_dta_1, sending_dta_0,
      sending_crc
    );
  signal state : statesType;

  -- Data and address
  signal p_data : dataRegisterType;
  signal p_addr : symbolSizeType;
  -- Ready to send
  signal sendable : std_ulogic;

BEGIN

  handleSend: process(reset, clock)
  begin
    if reset = '1' then
      state <= idle;
      dataOut <= (others=>'0');
      send <= '0';
      p_data <= (others=>'0');
      p_addr <= (others=>'0');
    elsif rising_edge(clock) then

      send <= '0';

    	case state is
        -- Wait to send
  		  when idle =>
      		if startSending = '1' then
            dataOut <= symbolSizeType(to_unsigned(FRAME_HEADER_BYTE, dataOut'length));
            p_data <= data;
            p_addr <= address;
            if sendBusy = '0' then
              send <= '1';
              state <= sending_header;
            else
              state <= load_header;
            end if;
          end if;

        -- Wait for Tx to be done (should not happen)
        when load_header =>
          if sendBusy = '0' then
            send <= '1';
            state <= sending_header;
          end if;

        -- Wait for header to be sent
        when sending_header =>
          if sendable = '1' then
            send <= '1';
            dataOut <= p_addr;
            state <= sending_addr;
          end if;

        when sending_addr =>
          if sendable = '1' then
            send <= '1';
            dataOut <= p_data(2*UART_BIT_NB-1 downto UART_BIT_NB);
            state <= sending_dta_1;
          end if;

        when sending_dta_1 =>
          if sendable = '1' then
            send <= '1';
            dataOut <= p_data(UART_BIT_NB-1 downto 0);
            state <= sending_dta_0;
          end if;
          
        when sending_dta_0 =>
          if sendable = '1' then
            send <= '1';
            dataOut <= CRC8;
            state <= sending_crc;
          end if;
          
        when sending_crc =>
          if sendBusy = '0' then
            state <= idle;
          end if;

        when others => state <= idle;

        end case;
	  end if;
  end process handleSend;

  busySending <= '0' when state = idle else '1';
  resetCRC <= not busySending;
  sendable <= '1' when sendBusy = '0' and crcReady = '1' else '0';

END ARCHITECTURE RTL;
