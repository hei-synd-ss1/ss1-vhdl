--====================================================================--
-- Design units : I2C.I2CTransmitterMaster.RTL
--
-- File name : I2CTransmitterMaster_RTL.vhd
--
-- Purpose : A rewrote of the original i2cTransmitter.vhd by Corthay François + Borgeat Rémy into a state-machine like fashion and splitted in two blocks. Also fixes clock related issues.
--           Handles I2C data retransmission as a master by generating the clock signal and checks for clock stretching.
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
-- 1.0            22.05.2025
-- 
-- 
------------------------------------------------

library Common;
  use Common.CommonLib.all;

ARCHITECTURE RTL OF I2CTransmitterMaster IS

  type state_t is (ST_IDLE, ST_START_RESTART, ST_DATA, ST_STOP);
  signal lvec_state : state_t;

  signal lsig_bus_owned : std_ulogic;

  signal lsig_scl_en, lsig_scl_toggle : std_ulogic;
  signal lvec_scl_cnt : unsigned(g_SCL_DIVIDER_BY_4_BIT_NB - 1 downto 0);
  signal lsig_o_sda, lsig_o_scl, lsig_o_scl_old : std_ulogic;
  signal lvec_scl_phase : unsigned(1 downto 0);

  signal lsig_stretching_detected : std_ulogic;
  signal lvec_data_cnt : unsigned(requiredBitNb(8 + 1) - 1 downto 0);
  signal lvec_data : std_ulogic_vector(8 - 1 downto 0);
  constant c_DATA_CNTER_MAX : unsigned(requiredBitNb(8 + 1) - 1 downto 0) := to_unsigned(8 + 1, requiredBitNb(8 + 1));

BEGIN

  -- Generates clock on request
  proc_scl_gen: process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      lvec_scl_cnt <= (others => '0');
      lvec_scl_phase <= (others => '0');
      lsig_scl_toggle <= '0';
    elsif rising_edge(i_clk) then
      lsig_scl_toggle <= '0';

      if lsig_scl_en = '0' then
        lvec_scl_cnt <= i_scl_divider_by_4;
        lvec_scl_phase <= (others => '0');
      else
        if lvec_scl_cnt = 0 then
          if i_pause_transmission = '0' and lsig_stretching_detected = '0' then
            lvec_scl_cnt <= i_scl_divider_by_4;
            lsig_scl_toggle <= '1';
          end if;
        else -- Let count go even if clock stretched, so minimal clock transition period is respected
          lvec_scl_cnt <= lvec_scl_cnt - 1;
        end if; -- lvec_scl_cnt = 0

        -- Clock toggling need to happen 1 clock after the flag is risen, else further synchronization with commands fails
        if lsig_scl_toggle = '1' then
          lvec_scl_phase <= lvec_scl_phase + 1;
        end if; -- lsig_scl_toggle = '1'

      end if; -- lsig_scl_en = '0'
    end if;
  end process proc_scl_gen;

  -- Detect clock stretching
  proc_stretching_detect: process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      lsig_stretching_detected <= '0';
      lsig_o_scl_old <= '1';
    elsif rising_edge(i_clk) then
      lsig_o_scl_old <= lsig_o_scl;

      -- Check with one cycle delta scl to avoid false detection on each edge, the time for the output to be registered and the physical line re-read as input
      if i_scl = lsig_o_scl then
        lsig_stretching_detected <= '0';
      elsif i_scl /= lsig_o_scl_old then
        lsig_stretching_detected <= '1';
      end if;
    end if;
  end process proc_stretching_detect;

  -- State machine
  proc_state_machine: process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      lvec_state <= ST_IDLE;
      lsig_bus_owned <= '0';
      lsig_scl_en <= '0';
      lsig_o_scl <= '1';
      lsig_o_sda <= '1';
      lvec_data_cnt <= (others => '0');
      lvec_data <= (others => '0');
    elsif rising_edge(i_clk) then
      case lvec_state is

        when ST_IDLE =>
          if i_send_start_restart = '1' then
            lvec_state <= ST_START_RESTART;
            lsig_scl_en <= '1';
          elsif i_send_stop = '1' and lsig_bus_owned = '1' then
            lvec_state <= ST_STOP;
            lsig_scl_en <= '1';
          elsif i_send_data = '1' and lsig_bus_owned = '1' then
            lvec_state <= ST_DATA;
            lsig_scl_en <= '1';
            lvec_data_cnt <= c_DATA_CNTER_MAX;
            lvec_data <= i_data_to_send;
          end if;
            
        when ST_START_RESTART =>
          case lvec_scl_phase is
            when "00" =>
              lsig_o_scl <= '0'; -- ensure SCL high
            when "01" =>
              lsig_o_sda <= '1'; -- ensure SDA high
            when "10" =>
              lsig_o_scl <= '1'; -- deassert SCL line
            when "11" =>
              lsig_o_sda <= '0'; -- assert SDA line
              if lsig_scl_toggle = '1' then
                lvec_state <= ST_IDLE;
                lsig_bus_owned <= '1';
                lsig_scl_en <= '0';
              end if;
            when others => null;
          end case;

        when ST_STOP =>
          case lvec_scl_phase is
            -- Entering here, clock is asserted low
            when "00" =>
              lsig_o_sda <= '0'; -- ensure SDA low
            when "01" =>
              lsig_o_scl <= '1'; -- ensure SCL high
            when "10" =>
              lsig_o_sda <= '1'; -- release SDA line
            when "11" =>
              if lsig_scl_toggle = '1' then
                lvec_state <= ST_IDLE;
                lsig_bus_owned <= '0';
                lsig_scl_en <= '0';
              end if;
            when others => null;
          end case; -- lvec_scl_phase

        when ST_DATA =>
          case lvec_scl_phase is
            when "00" =>
              lsig_o_scl <= '0'; -- ensure clock low to avoid false start/stop conditions
            when "01" =>
              -- ACK
              if lvec_data_cnt = 1 then
                lsig_o_sda <= not i_ack;
              -- Data
              else
                lsig_o_sda <= lvec_data(lvec_data'high);
              end if; -- lvec_data_cnt = 0
            when "10" =>
              -- End condition
              -- Needs to be here to ensure a stop following data respects clock timings
              if lvec_data_cnt = 0 then
                lvec_state <= ST_IDLE;
                lsig_scl_en <= '0';
              else
                lsig_o_scl <= '1';
              end if; -- lvec_data_cnt = 0
            when "11" =>
              if lsig_scl_toggle = '1' then
                lvec_data_cnt <= lvec_data_cnt - 1;
                lvec_data <= lvec_data(6 downto 0) & '0'; -- shift data
              end if; -- lvec_scl_toggling
            when others => null;
          end case;

        when others =>
          null;

      end case; -- case lvec_state
    end if; -- clk
  end process proc_state_machine;

  o_busy <= lsig_scl_en;
  o_scl <= lsig_o_scl;
  o_sda <= lsig_o_sda;
  o_bus_owned <= lsig_bus_owned;

END ARCHITECTURE RTL;
