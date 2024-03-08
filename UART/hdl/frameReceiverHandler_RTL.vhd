--
-- VHDL Architecture UART.frameReceiverHandler.RTL
--
-- Created:
--          by - axel.amand.UNKNOWN (WE7860)
--          at - 15:07:04 11.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--

LIBRARY Kart;
  USE Kart.Kart.ALL;

ARCHITECTURE RTL OF frameReceiverHandler IS

  -- Counter in case of problem
  	-- Gen.. : baud = UART_BAUD_RATE, UART_TXRX_BIT_NB bits / char, frame of FRAME_BYTES_NB bytes
  	-- E.G. : baud = 115200, 10 bits / char, frame is 5 chars -> time of 435 us
  	--
  	-- Plus a big (little) security, let's assume * 5
  constant watchdogTarget : positive := positive(((5 * 10.0 * FRAME_BYTES_NB) /
  		real(UART_BAUD_RATE)) / CLOCK_PERIOD);

  signal watchdogRunning : std_ulogic;
  signal watchdogCnt : unsigned(requiredBitNb(watchdogTarget)-1 downto 0);
  signal watchdog_Error : std_ulogic;

  -- State machine states
  type statesType is (
      wait_header, read_addr,
      read_dta_1, read_dta_2, get_crc, read_crc, check_crc,
      crcs_ok, flush
    );
  signal state : statesType;
  
  -- To register calculated CRC
  signal calc_CRC : std_ulogic_vector(7 downto 0);

BEGIN

  handleFrame: process(reset, clock)
  begin
    if reset = '1' then
      state <= wait_header;
      calc_CRC <= (others=>'0');
      watchdogRunning <= '0';
      badCRC <= '0';
    elsif rising_edge(clock) then
    	badCRC <= '0';
    	if watchdog_Error = '1' then
    		state <= flush;
    	else
	    	case state is
	    		-- Waiting for a frame to process, just passing state 
	    			-- until checking crc
	          	when wait_header =>
	          		if byteReceived = '1' then
	            		state <= read_addr;
	            		watchdogRunning <= '1';
	          		end if;
	      		when read_addr =>
	          		if byteReceived = '1' then
	            		state <= read_dta_1;
	          		end if;
	      		when read_dta_1 =>
	          		if byteReceived = '1' then
	            		state <= read_dta_2;
	          		end if;
	      		when read_dta_2 =>
	          		if byteReceived = '1' then
	            		state <= get_crc;
	          		end if;
	  			when get_crc =>
	          		if byteReceived = '1' then
	            		state <= flush; -- something bad happened
	            	elsif crcDone = '1' then
	            		calc_CRC <= calcCRC;
	            		state <= read_crc;
	          		end if;
	        	when read_crc =>
	          		if byteReceived = '1' then
	            		state <= check_crc;
	          		end if;
	          	-- CRC is calc and read, process
	          	when check_crc =>
	          		state <= flush;
	          		badCRC <= '1';
	          		if frameValid = '1' then
	          			if calc_CRC = frame(0) then
	          				state <= crcs_ok;
	          				badCRC <= '0';
	          			end if;
	          		end if;

	  			---------------------------------
	  			-- frame ok
	  			---------------------------------
	  			when crcs_ok =>
	  				-- registerFrame will go to 1, then we are done and can 
	  					-- clear data
	  				state <= flush;

	  			---------------------------------
	  			-- bad frame or end of processing
	  			---------------------------------
	  			when flush =>
	  				-- flush will be done by external signals
	  				-- also reset error counter
	  				state <= wait_header;
	  				watchdogRunning <= '0';


				when others => state <= wait_header;
	      	end case;
	     end if;
    end if;
  end process handleFrame;

  -- Watchdog
  watchdog: process(reset, clock)
  begin
  	if reset = '1' then
  		watchdogCnt <= (others=>'0');
  		watchdog_Error <= '0';
  	elsif rising_edge(clock) then
  		watchdogCnt <= (others=>'0');
  		watchdog_Error <= '0';
  		if watchdogRunning = '1' then
  			if watchdogCnt >= watchdogTarget then
  				watchdog_Error <= '1';
  			else
  				watchdogCnt <= watchdogCnt + 1;
  			end if;
  		end if;
  	end if;
  end process watchdog;

  -- To empty the current received frame (when processed)
  flushFrame <= '1' when state = flush else '0';
  -- To reset CRC counter
  resetCRC <= '1' when state = flush else '0';
  -- To indicate the frame can be loaded
  registerFrame <= '1' when state = crcs_ok else '0';
  -- Watchdog error
  watchdogError <= watchdog_Error;


END ARCHITECTURE RTL;

