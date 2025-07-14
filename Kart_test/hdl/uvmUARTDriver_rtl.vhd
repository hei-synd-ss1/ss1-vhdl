LIBRARY std;
  USE std.TEXTIO.all;
LIBRARY Common_test;
  USE Common_test.testUtils.all;

ARCHITECTURE rtl OF uvmKartDriver IS
                                                                   -- parameters
  constant uartDataBitNb: positive := 8;
  constant commandLength: positive := 5;
  constant commandStart: natural := 16#AA#;
  constant crcLength: natural := 8;
  constant crcPolynomial: natural := 16#07#;

  signal cmdstr : string(uartTransaction'range)
    := pad("", uartTransaction'length);
                                                                   -- Rx signals
  type transactionUnsignedType is array(1 to commandLength) of
    unsigned(uartDataBitNb-1 downto 0);
                                                                   -- debug info
  signal commandAddress : natural;
  signal commandData : integer;
  signal commandCRC : natural;
                                                                          -- CRC
  function calcCrc(address, data : natural) return natural is
    variable message : unsigned((commandLength-1)*uartDataBitNb-1 downto 0);
    variable crc : unsigned(crcLength-1 downto 0);
  begin
    message := resize(to_unsigned(commandStart, uartDataBitNb), message'length);
    message := shift_left(message, uartDataBitNb);
    message := message + to_unsigned(address, uartDataBitNb);
    message := shift_left(message, 2*uartDataBitNb);
    message := message + to_unsigned(data, 2*uartDataBitNb);
--    print(sprintf("%X", message));
    crc := (others => '0');
    for byteIndex in commandLength-1-1 downto 0 loop
      crc := resize(shift_right(message, byteIndex*uartDataBitNb), crc'length)
        XOR crc;
--      print(sprintf("%X", crc));
      for bitIndex in uartDataBitNb-1 downto 0 loop
        if crc(crc'high) = '0' then
          crc := shift_left(crc, 1);
        else
          crc := shift_left(crc, 1) XOR to_unsigned(crcPolynomial, crcLength);
        end if;
--        print("  " & sprintf("%X", crc));
      end loop;
    end loop;
    return to_integer(crc XOR x"55");
  end function;

BEGIN
  ------------------------------------------------------------------------------
                                                        -- interpret transaction
  interpretTransaction: process(transactionIn)
    variable myLine : line;
    variable commandPart, tempLine, registerValue : line;
    variable registerAddress: natural;
    variable registerAddressUnsigned : unsigned(uartDataBitNb-1 downto 0);
    variable tempData : integer;
    variable registerData : integer;
    variable registerDataUnsigned : unsigned(2*uartDataBitNb-1 downto 0);
    variable crc: natural;
    variable uartTransactionUnsigned : transactionUnsignedType;
    variable command_supported : std_ulogic;
    variable hexv : std_logic_vector(7 downto 0) := (others=>'0');
    variable isSignedVar : std_ulogic := '0';

    -- For simple registers, read next artifact as register data
    procedure readSimpleData is
    begin
      -- find  register data
      read_first(myLine, registerValue);
      read(registerValue, registerData);
    end procedure;


  begin
    write(myLine, transactionIn);
    rm_side_separators(myLine);
    read_first(myLine, commandPart);
    cmdstr <= pad(commandPart.all, uartTransaction'length);
    command_supported := '0';
    isSignedVar := '0';
    if commandPart.all = "idle" then
      uartTransaction <= transactionIn;
    elsif commandPart.all = "uart_baud" then
      uartTransaction <= transactionIn;
    else
      command_supported := '1';
      -- Find  register address
      registerData := 0;
      if commandPart.all = "dc_prescaler" then
        registerAddress := 16#20#;
        readSimpleData;
      elsif commandPart.all = "dc_speed" then
        registerAddress := 16#21#;
        readSimpleData;
        isSignedVar := '1';
      elsif commandPart.all = "stp_prescaler" then
        registerAddress := 16#60#;
        readSimpleData;
      elsif commandPart.all = "stp_target_angle" then
        registerAddress := 16#61#;
        readSimpleData;
      elsif commandPart.all = "sens_refresh_proxi" then
        registerAddress := 16#A0#;
        registerDataUnsigned := (others=>'0');
      elsif commandPart.all = "sens_led" then
        -- Reg. addr
        read_first(myLine, tempLine);
        read(tempLine, tempData);
        if tempData > 0 then
          registerAddress := 16#A0# + natural(tempData);
          -- Reg. data
            -- Read on bit
          read_first(myLine, tempLine);
          read(tempLine, tempData);
          registerData := natural(tempData) * (2**15);
            -- Read half-period
          read_first(myLine, tempLine);
          read(tempLine, tempData);
          registerData := registerData + natural(tempData);
        end if;
      elsif commandPart.all = "cr_hw_control" then
        registerAddress := 16#E0#;
        -- Reg. data
        registerData := 0;
        for index in 0 to 5 loop
          read_first(myLine, tempLine);
          read(tempLine, tempData);
          registerData := registerData + (2**index) * natural(tempData);
        end loop;
      elsif commandPart.all = "bt_status" then
        registerAddress := 16#E1#;
        readSimpleData;
      elsif commandPart.all = "read_reg" then
        registerData := 0;
        read_first(myLine, registerValue);
        hread(registerValue, hexv);
        registerAddress := to_integer(unsigned(hexv));
        if to_unsigned(registerAddress, registerAddressUnsigned'length)
          (REG_ADDR_GET_BIT_POSITION) = '1' then
          command_supported := '0';
          uartTransaction <= pad("BAD REGISTER READ", uartTransaction'length);
        end if;
      else
        command_supported := '0';
      end if;


      -- Debug info
      commandAddress <= registerAddress;
      commandData <= registerData;
      commandCRC <= crc;

      -- Check we handle this command
      if command_supported = '1' then
        -- Register address
        registerAddressUnsigned := to_unsigned(
          registerAddress, registerAddressUnsigned'length
        );
        -- Register data
        if isSignedVar = '1' then
          registerDataUnsigned := unsigned(to_signed(
            registerData, registerDataUnsigned'length
          ));
        else
          registerDataUnsigned := to_unsigned(
            natural(registerData), registerDataUnsigned'length
          );
        end if;
        -- Calculate CRC
        crc := calcCrc(registerAddress, to_integer(registerDataUnsigned));
        
        -- Build binary command
        uartTransactionUnsigned := (
          1 => to_unsigned(commandStart, uartDataBitNb),
          2 => registerAddressUnsigned,
          3 => resize(
            shift_right(registerDataUnsigned, uartDataBitNb),
            uartDataBitNb
          ),
          4 => resize(registerDataUnsigned, uartDataBitNb),
          5 => to_unsigned(crc, uartDataBitNb)
        );
        -- Send binary command
        for index in uartTransaction'range loop
          uartTransaction(index) <= ' ';
        end loop;
        uartTransaction(1 to 10) <= "uart_send ";
        for index in uartTransactionUnsigned'range loop
          uartTransaction(10+index) <= character'val(
            to_integer(uartTransactionUnsigned(index)
          ));
        end loop;
      end if;
    end if;
    deallocate(myLine);
  end process interpretTransaction;

END ARCHITECTURE rtl;

