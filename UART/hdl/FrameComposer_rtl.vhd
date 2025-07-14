--
-- VHDL Architecture UART.FrameComposer.rtl
--
-- Created:
--          by - axel.amand (WE7860)
--          at - 16:56:15 10.05.2022
--
-- using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
--


Library Kart;
  USE Kart.Kart.all;

-- Frame holder
ARCHITECTURE rtl OF FrameComposer IS

-- Holds the current frame
signal frameHolder : frameSizeType;
-- Count the number of shifts
signal shiftCnt : unsigned(requiredBitNb(NB_SYMBOL_P_FRAME)-1 downto 0);

BEGIN

shiftInput : process(reset, clock)
begin
	if reset = '1' then
		frameHolder <= (others=>(others=>'0'));
		shiftCnt <= (others=>'0');
	elsif rising_edge(clock) then
		-- If can discard the frame
		if flush = '1' then
			frameHolder <= (others=>(others=>'0'));
			shiftCnt <= (others=>'0');
		-- If should compose the frame
		elsif shiftCnt /= NB_SYMBOL_P_FRAME then
			-- Not yet complete
			if doShift = '1' then
				frameHolder <= frameHolder(NB_SYMBOL_P_FRAME-2 downto 0) & dataIn;
				shiftCnt <= shiftCnt + 1;
			end if;
		-- Complete
		else
			shiftCnt <= (others=>'0');
		end if;
	end if;
end process shiftInput;

frame <= frameHolder;
frameValid <= '1' when shiftCnt = NB_SYMBOL_P_FRAME else '0';

END ARCHITECTURE rtl;
