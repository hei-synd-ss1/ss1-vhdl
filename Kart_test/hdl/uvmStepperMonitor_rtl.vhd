LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmStepperMonitor IS

  constant REVERT_STEPS_DIR : std_ulogic := '0';

  signal p_startup : std_ulogic;
  signal p_testmode : std_ulogic := '0';
  signal p_newTarget : std_ulogic := '0';
  -- General for coils process
  signal p_mult_coils : std_ulogic := '0';
  -- Angle target
  signal p_target_angle_steps : natural := 0;
  signal p_coils_steps_cnt : integer := 0;
  signal p_target_reached : std_ulogic := '1';
  -- Coils management targets
  signal p_clk_freq : positive := 10000000;
  signal p_clk_per : time := 1.0/10000000.0 * 1 sec;
  signal p_prescaler : natural := 0;
  signal p_coils_per : time := 0 ns;
  signal p_new_freq : std_ulogic := '0';

  signal p_coils : std_ulogic_vector(3 downto 0);
  signal p_se : std_ulogic := '0';
  signal p_c1, p_c2, p_c3, p_c4 : std_ulogic := '0';

BEGIN

  interpretTransaction: process(transactionIn)
    variable myLine : line;
    variable commandPart, argPart : line;
    variable argm : natural := 0;
  begin
    p_newTarget <= '0';
    write(myLine, transactionIn);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    if commandPart.all = "clock_frequency" then
      read_first(myLine, argPart);
      read(argPart, argm);
      p_clk_freq <= argm;
    elsif commandPart.all = "stp_prescaler" then
      -- Expected coil frequency changed
      read_first(myLine, argPart);
      read(argPart, argm);
      p_prescaler <= argm;
    elsif commandPart.all = "stp_target_angle" then
      -- Expected number of steps to do
      read_first(myLine, argPart);
      read(argPart, argm);
      p_target_angle_steps <= argm;
      p_newTarget <= '1';
    elsif commandPart.all = "stp_testmode" then
      -- If testmode
      read_first(myLine, argPart);
      read(argPart, argm);
      p_testmode <= '1' when argm /= 0 else '0';
    elsif commandPart.all = "stp_endsw" then
      -- If testmode
      read_first(myLine, argPart);
      read(argPart, argm);
      p_se <= '1' when argm /= 0 else '0';
    end if;
    deallocate(myLine);
  end process interpretTransaction;


  p_c1 <= coil1; -- after 3.3 sec * CLOCK_PERIOD;
  p_c2 <= coil2; -- after 3.3 sec * CLOCK_PERIOD;
  p_c3 <= coil3; -- after 3.3 sec * CLOCK_PERIOD;
  p_c4 <= coil4; -- after 3.3 sec * CLOCK_PERIOD;

  coilChecker: process(p_c1, p_c2, p_c3, p_c4)
    variable p_lastcoils : std_ulogic_vector(3 downto 0) := (others=>'0');
    variable p_coilfreq : time := 0 ns;
    variable p_mul_c : std_ulogic := '0';
    variable p_coils_state : std_ulogic_vector(3 downto 0) := (others=>'0');
  begin
    -- Register coils states
    p_coils_state := p_c4 & p_c3 & p_c2 & p_c1;
    p_coils <= p_coils_state;
    case p_coils_state is
      when "0000" | "0001" | "0010" | "0100" | "1000" => p_mul_c := '0';
      when others => p_mul_c := '1';
    end case;
    p_mult_coils <= p_mul_c;

    -- Does not handle microstepping --

    if p_mul_c = '0' then
      if p_coils_state /= (0 to p_coils_state'high=>'0') then
        -- For firsty, setup coils to match
        if p_lastcoils = (0 to p_coils_state'high=>'0') then
          p_lastcoils := p_coils_state;
          case p_coils_state is
            when "0001" | "0010" =>
              p_coils_steps_cnt <= p_coils_steps_cnt + 1 when 
                REVERT_STEPS_DIR = '0' else p_coils_steps_cnt - 1;
            when "0100" | "1000" =>
              p_coils_steps_cnt <= p_coils_steps_cnt - 1 when
                REVERT_STEPS_DIR = '0' else p_coils_steps_cnt + 1;
            when others => null;
          end case;
        end if;
        -- Check target
        if p_coils_state = p_lastcoils(0) & p_lastcoils(3 downto 1) then
          p_coils_steps_cnt <= p_coils_steps_cnt - 1 when REVERT_STEPS_DIR = '0'
            else p_coils_steps_cnt + 1;
        elsif p_coils_state = p_lastcoils(2 downto 0) & p_lastcoils(3) then
          p_coils_steps_cnt <= p_coils_steps_cnt + 1 when REVERT_STEPS_DIR = '0'
            else p_coils_steps_cnt - 1;
        end if;
        p_lastcoils := p_coils_state;

        -- Check frequency
        p_coils_per <= now - p_coilfreq;
        p_coilfreq := now;
        p_new_freq <= '1', '0' after 1.3*p_clk_per;
      end if;
    end if;
    -- If we reset, back to 0
    if p_se = '1' then
      p_coils_steps_cnt <= 0;
    end if;
  end process coilChecker;


  reportBusAccess: process
    (p_startup, p_mult_coils, p_target_reached, p_new_freq, p_prescaler)
    variable waitingForFreq : std_ulogic := '0';
    variable firstPulse : std_ulogic := '0';
  begin
--    if p_startup = '1' then
--      stepperMonitor <= pad(
--        "idle",
--        stepperMonitor'length
--      );
--    els
    -- if rising_edge(p_mult_coils) then
    --   stepperMonitor <= pad(
    --     "Stepper detected bad coils state (or not wave drive) " & sprintf("%b", p_coils),
    --     stepperMonitor'length
    --   );
    -- els
    if rising_edge(p_target_reached) then
      stepperMonitor <= pad(
        "Stepper target reached (" & sprintf("%d", p_coils_steps_cnt) & " steps)",
        stepperMonitor'length
      );
    elsif falling_edge(p_target_reached) then
      -- cannot get frequency from only one pulse
      if abs(p_target_angle_steps - p_coils_steps_cnt) > 1 then
        waitingForFreq := '1';
        firstPulse := '1';
        end if;
    elsif p_new_freq = '1' and waitingForFreq = '1' then
      if firstPulse = '1' then
        firstPulse := '0';
      else
        waitingForFreq := '0';
        stepperMonitor <= pad(
          "Detected stepper coils frequency around " & sprintf("%d", natural(1 sec/p_coils_per)) & " Hz",
          stepperMonitor'length
        );
      end if;
    elsif p_prescaler'event then
      stepperMonitor <= pad(
        "Stepper target set to : " & sprintf("%d", p_prescaler) & " steps",
        stepperMonitor'length
      );
    end if;
  end process reportBusAccess;

  p_startup <= '1', '0' after 1 ns;
  testMode <= p_testmode;
  --p_se <= '1' when p_coils_steps_cnt = 0 else '0';
  stepperEnd <= transport p_se after 5 sec * CLOCK_PERIOD ;
  p_clk_per <= 1.0/real(p_clk_freq) * 1 sec;
  p_target_reached <= '1' when p_coils_steps_cnt = p_target_angle_steps else '0';

END ARCHITECTURE rtl;
