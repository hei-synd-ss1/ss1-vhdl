--====================================================================--
-- Design units : I2C.I2CTransmitterSlave.RTL
--
-- File name : I2CTransmitterSlave_RTL.vhd
--
-- Purpose : A rewrote of the original i2cTransmitter.vhd by Corthay François + Borgeat Rémy into a state-machine like fashion and splitted in two blocks. Also fixes clock related issues.
--           Handles I2C data retransmission as a slave by using master clock and stretching clock on need.
--           Does not handle the I2C bus arbitration (multi-master) - no listen-while-talking scheme implemented.
--
-- Library : I2C
--
-- Dependencies : Common.CommonLib.requiredBitNb
--
-- Author : Axam
-- HES-SO Valais/Wallis
-- Route de l'Industrie 23
-- 1950 Sion
-- Switzerland
--
-- Design tool : HDL Designer 2019.2 (Build 5)
-- Simulator : ModelSim 20.1.1
------------------------------------------------
-- Revision list
-- Version Author Date           Changes
-- 1.0            26.05.2025
-- 
-- 
------------------------------------------------

library Common;
  use Common.CommonLib.all;

ARCHITECTURE RTL OF I2CTransmitterSlave IS

  type state_t is (ST_IDLE, ST_WAIT_FIRST_BIT_SCL, ST_DATA);
  signal lvec_state : state_t;

  signal lsig_o_sda, lsig_o_scl, lsig_i_scl_old : std_ulogic;
  signal lvec_data : std_ulogic_vector(8 - 1 downto 0);
  signal lvec_data_cnt : unsigned(requiredBitNb(8 + 1 - 1) - 1 downto 0);
  signal lsig_is_datasend : std_ulogic;
  constant c_DATA_CNTER_MAX : unsigned(requiredBitNb(8 + 1 - 1) - 1 downto 0) := to_unsigned(8 + 1 - 1, requiredBitNb(8 + 1 - 1));

BEGIN

  -- State machine
  proc_state_machine: process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      lvec_state <= ST_IDLE;
      lsig_o_sda <= '1';
      lsig_o_scl <= '1';
      lvec_data <= (others => '1');
      lvec_data_cnt <= (others => '0');
      lsig_i_scl_old <= '1';
      lsig_is_datasend <= '0';
    elsif rising_edge(i_clk) then
      lsig_i_scl_old <= i_scl;
      lsig_o_scl <= '1';

      case lvec_state is

        when ST_IDLE =>
          lsig_o_sda <= '1'; -- Ensure not to perturb the bus when idle
          if i_send_data = '1' then
            lsig_is_datasend <= '1';
            if i_scl = '1' then
              lvec_state <= ST_WAIT_FIRST_BIT_SCL; -- Wait for SCL to be low before sending data
            else
              lvec_state <= ST_DATA; -- If SCL is already low, go directly to data state
            end if;
            lvec_data <= i_data_to_send; -- Load data to be sent
            lvec_data_cnt <= c_DATA_CNTER_MAX;
          elsif i_send_ack = '1' then
            lsig_is_datasend <= '0'; -- Not sending data, just sending ACK
            if i_scl = '1' then
              lvec_state <= ST_WAIT_FIRST_BIT_SCL; -- Wait for SCL to be low before sending data
            else
              lvec_state <= ST_DATA; -- If SCL is already low, go directly to data state
            end if;
            lvec_data_cnt <= (others => '0');
          end if;

        when ST_WAIT_FIRST_BIT_SCL =>
          if i_scl = '0' then
            lvec_state <= ST_DATA; -- If SCL is low, go to data state
          end if;

        when ST_DATA =>
          -- Detect falling edges to send data
          if i_scl = '0' and lsig_i_scl_old = '1' then
            if lvec_data_cnt = 0 then
              if i_pause_transmission = '0' then
                lvec_state <= ST_IDLE;
                lsig_o_sda <= '1'; -- Release SDA when done
              end if;
            else
              lvec_data_cnt <= lvec_data_cnt - 1;
              lvec_data <= lvec_data(6 downto 0) & '1';
            end if;
          end if;

          if i_scl = '0' then
            if lvec_data_cnt = 0 then
              lsig_o_scl <= not i_pause_transmission; -- Stretch SCL if pause is requested, only at ack and if SCL already low
              if lsig_is_datasend = '1' then
                lsig_o_sda <= '1'; -- Do not perturb master acknowledge
              else
                lsig_o_sda <=  not i_ack; -- Send ACK if not sending data
              end if;
            else
              lsig_o_sda <= lvec_data(7);
            end if;
          end if;

        when others =>
          null;

      end case; -- case lvec_state
    end if; -- clk
  end process proc_state_machine;

  o_busy <= '1' when lvec_state /= ST_IDLE else '0';
  o_sda <= lsig_o_sda;
  o_scl <= lsig_o_scl;

END ARCHITECTURE RTL;
