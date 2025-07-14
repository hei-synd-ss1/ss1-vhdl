LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;
LIBRARY Kart;
  USE Kart.Kart.all;
library ieee;
  use ieee.math_real.all;

ARCHITECTURE rtl OF uvmSensorsMonitor IS

  signal p_startup : std_ulogic;

  signal p_clk_freq : positive := 10000000;
  signal p_clk_per : time := 1.0/10000000.0 * 1 sec;

  signal p_endsw : std_ulogic_vector(SENS_endSwitchNb-1 downto 0) := (others=>'0');

  signal p_pulse : std_ulogic := '0';
  signal p_pulse_conn: std_ulogic := '1';

  signal p_hall_pulse, p_sendpulse : std_ulogic := '0';

  signal p_batteryDataOut : unsigned(I2C_BIT_NB-3 downto 0) := (others=>'0');

BEGIN

  p_startup <= '1', '0' after 1 ns;
  p_clk_per <= 1.0/real(p_clk_freq) * 1 sec;
  endSwitches <= p_endsw;
  distancePulse <= p_pulse and p_pulse_conn;
  hallPulses <= (others=>p_hall_pulse);

  interpretTransaction: process(transactionIn)
    variable myLine : line;
    variable commandPart, argPart : line;
    variable argm, argm2 : integer := 0;
  begin
    write(myLine, transactionIn);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "clock_frequency" then
      read_first(myLine, argPart);
      read(argPart, argm);
      p_clk_freq <= argm;
    elsif commandPart.all = "sens_refresh_proxi" then
      -- Will get I2C movements, not implemented yet
    elsif commandPart.all = "sens_led" then
      -- Not used
    elsif commandPart.all = "sens_end_switch" then
      read_first(myLine, argPart);
      read(argPart, argm);
      if argm > 0 then
        read_first(myLine, argPart);
        read(argPart, argm2);
        p_endsw(argm-1) <= '1' when argm2 /= 0 else '0';
      end if;
    elsif commandPart.all = "sens_ranger_conn" then
      read_first(myLine, argPart);
      read(argPart, argm);
      p_pulse_conn <= '1' when argm /= 0 else '0';
    end if;
    deallocate(myLine);
  end process interpretTransaction;


  -- Emulate pulse sensor with random distances

  pulseStarter: process
  begin
    p_sendpulse <= '0';
    wait for (real(SENS_rangeTimeoutBeforeStartMS) / 10.0) * ms;
    p_sendpulse <= '1';
    wait for p_clk_per;
  end process;

  doPulse: process(p_sendpulse)
    variable r, r_scaled : real;
    variable seed1 : integer := 91;
    variable seed2 : integer := 514;
    constant min_real : real := 0.88;
    constant max_real : real := 37.5;
    constant test_min_real : real := 0.00088;
    constant test_max_real : real := 0.375;
    constant unit : time := ms;
  begin
    if p_sendpulse = '1' then
      if p_pulse_conn = '1' then
        uniform(seed1, seed2, r);
        if testMode = '1' then
          r_scaled := r * (test_max_real - test_min_real) + test_min_real;
        else
          r_scaled := r * (max_real - min_real) + min_real;
        end if;
        p_pulse <= '1', '0' after r_scaled * unit;
        
      else
        p_pulse <= '0';
      end if;
    end if;
  end process doPulse;

  -- Emulate hall sensors
  hallSens: process(pwm)
    variable cnt : integer := 0;
    variable schmitt_trg : std_ulogic := '0';
  begin
    if rising_edge(pwm) then
      -- Count
      if fwd = '1' then
        cnt := cnt + 1;
      else
        cnt := cnt - 1;
      end if;
      -- Modulo
      if cnt > 9 then
        cnt := 0;
      elsif cnt < 0 then
        cnt := 9;
      end if;
      -- Act as schmitt (cnt = 4 sets to high, cnt = 9 sets to low)
      if cnt = 4 then
        -- if schmitt change, do pulse
        if schmitt_trg /= '0' then
          p_hall_pulse <= not p_hall_pulse;
        end if;
        schmitt_trg := '0';
      elsif cnt = 9 then
        if schmitt_trg /= '1' then
          p_hall_pulse <= not p_hall_pulse;
        end if;
        schmitt_trg := '1';
      end if;
    end if;
  end process hallSens;

  -- Emulate I2C battery reader
  batteryChipIsSel <= '1' when batteryChipAddrIn = "1101000" else '0';
  batteryDataOut <= std_ulogic_vector(p_batteryDataOut);

  batt_reader : process(batteryDataValid)
    variable conf_reg : std_ulogic_vector(I2C_BIT_NB-3 downto 0) := "10010000";
    variable r, r_scaled : real;
    variable seed1 : integer := 98;
    variable seed2 : integer := 561;
    constant test_min_real : real := 0.0;
    constant test_max_real : real := 255.0;
    variable last1, last2 : natural := 0;
    variable notReadySens : std_ulogic := '0';
  begin
    if rising_edge(batteryDataValid) then
      if batteryWriteIn = '1' then
        if batteryRegister = to_unsigned(1, batteryRegister'length) then
          conf_reg := std_ulogic_vector(batteryDataIn);
        end if;
      else
        case to_integer(batteryRegister) is
          -- high byte
          when 0 =>
            notReadySens := not notReadySens; -- creates a "not ready yet" state
            if conf_reg(6 downto 5) = "00" or conf_reg(6 downto 5) = "10" then
              p_batteryDataOut <= to_unsigned(1, p_batteryDataOut'length);
            else
              p_batteryDataOut <= to_unsigned(2, p_batteryDataOut'length);
            end if;
          -- low byte
          when 1 =>
            uniform(seed1, seed2, r);
            r_scaled := r * (test_max_real - test_min_real) + test_min_real;

            if conf_reg(6 downto 5) = "00" or conf_reg(6 downto 5) = "10" then
              if conf_reg(4) = '1' then
                last1 := natural(r_scaled);
              elsif conf_reg(7) = '1' then
                last1 := natural(r_scaled);
                conf_reg(7) := notReadySens;
              end if;
              p_batteryDataOut <= to_unsigned(last1, p_batteryDataOut'length);
            else
              if conf_reg(4) = '1' then
                last2 := natural(r_scaled);
              elsif conf_reg(7) = '1' then
                last2 := natural(r_scaled);
                conf_reg(7) := notReadySens;
              end if;
              p_batteryDataOut <= to_unsigned(last2, p_batteryDataOut'length);
            end if;
          -- conf byte
          when others => p_batteryDataOut <= unsigned(conf_reg);
        end case;
      end if;
    end if;
  end process batt_reader;


  reportBusAccess: process(p_startup, leds)
  begin
--    if p_startup = '1' then
--      sensorsMonitor <= pad(
--        "idle",
--        sensorsMonitor'length
--      );
--    els
    if leds'event then
      sensorsMonitor <= pad(
        "Leds state changed to : " & sprintf("%b", leds),
        sensorsMonitor'length
      );
    end if;
  end process reportBusAccess;

END ARCHITECTURE rtl;
