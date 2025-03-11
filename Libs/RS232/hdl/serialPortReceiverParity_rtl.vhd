/*
  Proposition of FSM style block
*/

library Common;
  use Common.CommonLib.all;

ARCHITECTURE rtl OF serialPortReceiverParity IS

  -- FSM
  type state_t is (ST_IDLE, ST_SYNCHRONIZE_START, ST_RECEIVING_BYTE, ST_WAIT_STOP);
  signal lvec_state: state_t;
  -- Clock divider
  signal lvec_divider_counter: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDE)-1 downto 0);
  constant c_DIVIDER_HALF_TARGET: unsigned(requiredBitNb(g_BAUD_RATE_DIVIDE)-1 downto 0) := to_unsigned( g_BAUD_RATE_DIVIDE / 2, requiredBitNb(g_BAUD_RATE_DIVIDE));
  signal lsig_divider_counter_reset: std_uLogic;
    -- When overflows
  signal lsig_divider_of: std_uLogic;
  -- Data to receive
  constant c_DATA_CNT_TARGET: unsigned(requiredBitNb(g_DATA_BIT_NB)-1 downto 0) := to_unsigned(g_DATA_BIT_NB, requiredBitNb(g_DATA_BIT_NB));
  signal lvec_rx_counter: unsigned(requiredBitNb(g_DATA_BIT_NB)-1 downto 0);
  signal lvec_rx_shift_reg: std_ulogic_vector(g_DATA_BIT_NB-1 downto 0);
  -- Sys
  signal lsig_o_byte_received: std_uLogic;
  signal lsig_o_parity_error, lsig_parity_error_int: std_uLogic;
  signal lsig_o_frame_error : std_uLogic;
  signal lvec_o_byte : std_ulogic_vector(g_DATA_BIT_NB-1 downto 0);

BEGIN

  -- Check generics
  assert g_BAUD_RATE_DIVIDE >= 4 report "g_BAUD_RATE_DIVIDE must be at least 4" severity failure;

  -- FSM
  fsm_proc : process(reset, clock)
  begin
    if reset = '1' then
      lvec_state <= ST_IDLE;
      lsig_divider_counter_reset <= '0';
      lvec_rx_shift_reg <= (others => '0');
      lvec_rx_counter <= (others => '0');
      lsig_o_byte_received <= '0';
      lsig_o_parity_error <= '0';
      lsig_parity_error_int <= '0';
      lsig_o_frame_error <= '0';
      lvec_o_byte <= (others => '0');
    elsif rising_edge(clock) then
      lsig_divider_counter_reset <= '0';
      lsig_o_byte_received <= '0';
      lsig_o_frame_error <= '0';
      lsig_o_parity_error <= '0';

      case lvec_state is

        when ST_IDLE =>
          lvec_rx_counter <= (others => '0');
          lsig_parity_error_int <= '0';

          -- Start detected
          if i_rxd_en = '1' and i_rxd = '0' then
            lvec_state <= ST_SYNCHRONIZE_START;
          end if;

        when ST_SYNCHRONIZE_START =>
          -- We wait to be on half of the bit period
            -- -1 because we lost a clock cycle entering this state
            -- -1 because we want to detect a bit before the end of the period to be synchronous in receiving
            --    => limits c_DIVIDER_HALF_TARGET to be at least 2 => g_BAUD_RATE_DIVIDE >= 4
          if lvec_divider_counter = c_DIVIDER_HALF_TARGET - 1 - 1 then
            lvec_state <= ST_RECEIVING_BYTE;
            lsig_divider_counter_reset <= '1';
          end if;

        when ST_RECEIVING_BYTE =>
          -- Bit ready
          if lsig_divider_of = '1' then
            if lvec_rx_counter < c_DATA_CNT_TARGET then
              lvec_rx_shift_reg(lvec_rx_shift_reg'high-1 downto 0) <= lvec_rx_shift_reg(lvec_rx_shift_reg'high downto 1);
              lvec_rx_shift_reg(lvec_rx_shift_reg'high) <= i_rxd;
              lvec_rx_counter <= lvec_rx_counter + 1;
            else -- is parity bit
              lvec_state <= ST_WAIT_STOP;
              if g_LSB_FIRST = '1' then
                lvec_o_byte <= lvec_rx_shift_reg;
              else
                for i in 0 to g_DATA_BIT_NB-1 loop
                  lvec_o_byte(i) <= lvec_rx_shift_reg(g_DATA_BIT_NB - i - 1);
                end loop;
              end if;
              -- Check parity
              if i_rxd /= xor lvec_rx_shift_reg then
                lsig_parity_error_int <= '1';
              end if;
            end if;
          end if;      
          
        when ST_WAIT_STOP =>
          -- Stop detected
          if lsig_divider_of = '1' then
            lvec_state <= ST_IDLE;
            lsig_o_byte_received <= '1';
            lsig_o_frame_error <= not i_rxd;
            lsig_o_parity_error <= lsig_parity_error_int;
          end if;

        when others =>
          lvec_state <= ST_IDLE;
        
      end case;
    end if;
  end process fsm_proc;

  -- Clock divider
  clk_divider_proc : process(reset, clock)
  begin
    if reset = '1' then
      lvec_divider_counter <= (others => '0');
      lsig_divider_of <= '0';
    elsif rising_edge(clock) then
      lsig_divider_of <= '0';

      if lsig_divider_counter_reset = '1' or lvec_state = ST_IDLE or lvec_divider_counter = g_BAUD_RATE_DIVIDE - 1 then
        lvec_divider_counter <= (others => '0');
        lsig_divider_of <= not lsig_divider_counter_reset;
      else
        lvec_divider_counter <= lvec_divider_counter + 1;
      end if;
    end if;
  end process clk_divider_proc;

  -- Outputs
  o_byte <= lvec_o_byte;
  o_byte_received <= lsig_o_byte_received;
  o_parity_error <= lsig_o_parity_error;
  o_frame_error <= lsig_o_frame_error;
  o_receiving <= '0' when lvec_state = ST_IDLE else '1';

END ARCHITECTURE rtl;
