LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmDCMonitor IS

  signal p_startup : std_ulogic;

  signal p_clk_freq : positive := 10000000;
  signal p_clk_per : time := 1.0/10000000.0 * 1 sec;

  signal p_prescaler : natural := 1;
  signal p_speed : integer := 0;

  signal p_log_pwm : std_ulogic := '0';
  signal log_delay : std_ulogic := '0';
  signal p_high_per, p_low_per : time := 0 sec;


BEGIN

  p_startup <= '1', '0' after 1 ns;
  p_clk_per <= 1.0/real(p_clk_freq) * 1 sec;


  interpretTransaction: process(transactionIn)
    variable myLine : line;
    variable commandPart, argPart : line;
    variable argm : integer := 0;
  begin
    write(myLine, transactionIn);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "clock_frequency" then
      read_first(myLine, argPart);
      read(argPart, argm);
      p_clk_freq <= argm;
    elsif commandPart.all = "dc_prescaler" then
      -- Expected motor frequency changed
      read_first(myLine, argPart);
      read(argPart, argm);
      p_prescaler <= argm;
    elsif commandPart.all = "dc_speed" then
      -- Expected motor frequency changed
      read_first(myLine, argPart);
      read(argPart, argm);
      p_speed <= argm;
    end if;
    deallocate(myLine);
  end process interpretTransaction;


  checkSignals: process(pwm, p_speed, log_delay)
    variable per_begin : time := 0 ns;
    variable dolog : std_ulogic := '0';
    variable begin_count : std_ulogic := '0';
  begin
    p_log_pwm <= '0';

    -- Begin log acquisition
    if p_speed'event then
      log_delay <= '1' after 1.2 ms; -- time for the system to register new speed
    end if;

    if log_delay = '1' then
      dolog := '1';
      begin_count := '0';
      log_delay <= '0';
    end if;

    if dolog = '1' then
      if rising_edge(pwm) then
        -- Begin count on pwm rising
        if begin_count = '0' then
          begin_count := '1';
          per_begin := now;
        -- Stop count on new pwm rising and log
        else
          p_low_per <= now - per_begin;
          begin_count := '0';
          dolog := '0';
          p_log_pwm <= '1';
        end if;
      -- Else is counting
      elsif falling_edge(pwm) then
        p_high_per <= now - per_begin;
        per_begin := now;
      end if;
    end if;
  end process checkSignals;


  reportBusAccess: process(p_startup, p_prescaler, p_speed, p_log_pwm)
  begin
--    if p_startup = '1' then
--      dcMonitor <= pad(
--        "idle",
--        dcMonitor'length
--      );
--    els
    if p_prescaler'event then
      dcMonitor <= pad(
        "DC prescaler set to : " & sprintf("%d", p_prescaler),
        dcMonitor'length
      );
    elsif p_speed'event then
      dcMonitor <= pad(
        "DC speed set to : " & sprintf("%d", p_speed),
        dcMonitor'length
      );
    elsif rising_edge(p_log_pwm) then
      -- Called on each new speed setting
      dcMonitor <= pad(
        "Detected DC PWM frequency around " & sprintf("%d",
            natural(1 sec / (p_high_per + p_low_per))) &
        " Hz with a duty of " &
        sprintf("%f", (
          real(p_high_per / 1 ns) / (
            real(p_high_per / 1 ns) + real(p_low_per / 1 ns)
          )) * 100.0
        ) & " % ",
        dcMonitor'length
      ) when forwards = '1' else
      pad(
        "Detected DC PWM frequency around " & sprintf("%d",
            natural(1 sec / (p_high_per + p_low_per))) &
        " Hz with a duty of -" &
        sprintf("%f", (
          real(p_high_per / 1 ns) / (
            real(p_high_per / 1 ns) + real(p_low_per / 1 ns)
          )) * 100.0
        ) & " % ",
        dcMonitor'length
      );
    end if;
  end process reportBusAccess;

END ARCHITECTURE rtl;
