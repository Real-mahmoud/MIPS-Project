LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY control_unit IS
    PORT (
        IR            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        flags         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        RESET         : IN  STD_LOGIC;
        loadFlagEXMEM : IN  STD_LOGIC;
        RdestNumEXMEM : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        memRead       : OUT STD_LOGIC;
        memWrite      : OUT STD_LOGIC;
        flagWrite     : OUT STD_LOGIC;
        spOperationSelector : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        spWrite       : OUT STD_LOGIC;
        rdstWBSeclector : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        memAddressSelector : OUT STD_LOGIC;
        outputPort    : OUT STD_LOGIC;
        inputPort     : OUT STD_LOGIC;
        aluSelect     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        clrCFlag      : OUT STD_LOGIC;
        setCFlag      : OUT STD_LOGIC;
        immFlag       : OUT STD_LOGIC;
        loadFlag      : OUT STD_LOGIC;
        rdstWB        : OUT STD_LOGIC;
        branch_taken  : OUT STD_LOGIC;
        loadUse       : OUT STD_LOGIC
    );
END control_unit;

ARCHITECTURE controle_unit_default OF control_unit IS

    -- Opcodes (????? ?? ??? opcode ?? IR(31 downto 26) ? 6 bits)
    CONSTANT NOP       : INTEGER := 0;
    CONSTANT SETC      : INTEGER := 1;
    CONSTANT CLRC      : INTEGER := 2;
    CONSTANT CLR       : INTEGER := 16#10#;
    CONSTANT NOT_OP    : INTEGER := 16#11#;
    CONSTANT INC       : INTEGER := 16#12#;
    CONSTANT NEG       : INTEGER := 16#13#;
    CONSTANT DEC       : INTEGER := 16#14#;
    CONSTANT OUT_OP    : INTEGER := 16#15#;
    CONSTANT IN_OP     : INTEGER := 16#16#;
    CONSTANT RLC       : INTEGER := 16#17#;
    CONSTANT RRC       : INTEGER := 16#18#;
    CONSTANT MOV       : INTEGER := 16#40#;
    CONSTANT ADD       : INTEGER := 16#41#;
    CONSTANT SUB       : INTEGER := 16#42#;
    CONSTANT AND_OP    : INTEGER := 16#43#;
    CONSTANT OR_OP     : INTEGER := 16#44#;
    CONSTANT IADD      : INTEGER := 16#65#;
    CONSTANT SHL       : INTEGER := 16#66#;
    CONSTANT SHR       : INTEGER := 16#67#;
    CONSTANT LDM       : INTEGER := 16#68#;
    CONSTANT PUSH      : INTEGER := 16#80#;
    CONSTANT POP       : INTEGER := 16#81#;
    CONSTANT LDD       : INTEGER := 16#b0#;
    CONSTANT STD_OP    : INTEGER := 16#b1#;
    CONSTANT RET       : INTEGER := 16#c0#;
    CONSTANT RTI       : INTEGER := 16#c1#;
    CONSTANT JZ        : INTEGER := 16#d0#;
    CONSTANT JN        : INTEGER := 16#d1#;
    CONSTANT JC        : INTEGER := 16#d2#;
    CONSTANT JMP       : INTEGER := 16#d3#;
    CONSTANT CALL      : INTEGER := 16#d4#;

    SIGNAL opCode : INTEGER;

BEGIN

    -- Load-use detection
    load_use_detection_lbl : ENTITY work.load_use_detection 
        PORT MAP (IR => IR, loadFlagEXMEM => loadFlagEXMEM, RdestNumEXMEM => RdestNumEXMEM, loadUse => loadUse);

    immFlag <= IR(29);

    -- ????? ???: opcode 6 bits (31 downto 26)
    opCode <= to_integer(unsigned(IR(31 DOWNTO 26)));

    -- ?? signal ?? default ?? ??????? ???? ?? ????? 'U'
    memRead <= '0' when RESET = '1' else
               '1' when opCode = POP or opCode = LDD else
               '0';

    memWrite <= '0' when RESET = '1' else
                '1' when opCode = PUSH or opCode = STD_OP else
                '0';

    flagWrite <= '0' when RESET = '1' else
                 '1' when opCode = SETC or opCode = CLRC or opCode = CLR or opCode = NOT_OP or
                          opCode = INC or opCode = NEG or opCode = DEC or opCode = RLC or opCode = RRC or
                          opCode = ADD or opCode = SUB or opCode = AND_OP or opCode = OR_OP or
                          opCode = IADD or opCode = SHL or opCode = SHR else
                 '0';

    spOperationSelector <= "00" when RESET = '1' else
                           "10" when opCode = PUSH else  -- dec
                           "01" when opCode = POP else    -- inc
                           "00";

    spWrite <= '0' when RESET = '1' else
               '1' when opCode = PUSH or opCode = POP else
               '0';

    rdstWBSeclector <= "00" when RESET = '1' else
                       "01" when opCode = CLR or opCode = NOT_OP or opCode = INC or opCode = NEG or
                                 opCode = DEC or opCode = IN_OP or opCode = RLC or opCode = RRC or
                                 opCode = MOV or opCode = ADD or opCode = SUB or opCode = AND_OP or
                                 opCode = OR_OP or opCode = IADD or opCode = SHL or opCode = SHR or
                                 opCode = LDM else
                       "10" when opCode = POP or opCode = LDD else
                       "00";

    memAddressSelector <= '0' when RESET = '1' else
                          '1' when opCode = PUSH or opCode = POP else
                          '0';

    outputPort <= '0' when RESET = '1' else
                  '1' when opCode = OUT_OP else
                  '0';

    inputPort <= '0' when RESET = '1' else
                 '1' when opCode = IN_OP else
                 '0';

    aluSelect <= x"0" when RESET = '1' else
                 x"1" when opCode = CLR else
                 x"2" when opCode = NOT_OP else
                 x"3" when opCode = INC else
                 x"4" when opCode = NEG else
                 x"5" when opCode = DEC else
                 x"6" when opCode = RLC else
                 x"7" when opCode = RRC else
                 x"8" when opCode = MOV or opCode = IN_OP else
                 x"9" when opCode = ADD or opCode = IADD or opCode = LDD or opCode = STD_OP else
                 x"A" when opCode = SUB else
                 x"B" when opCode = AND_OP else
                 x"C" when opCode = OR_OP else
                 x"D" when opCode = SHL else
                 x"E" when opCode = SHR else
                 x"F" when opCode = LDM else
                 x"0";

    clrCFlag <= '1' when RESET = '1' or opCode = CLRC else '0';

    setCFlag <= '1' when opCode = SETC else '0';

    loadFlag <= '0' when RESET = '1' else
                '1' when opCode = LDD else
                '0';

    rdstWB <= '0' when RESET = '1' else
              '1' when opCode = CLR or opCode = NOT_OP or opCode = INC or opCode = NEG or
                       opCode = DEC or opCode = IN_OP or opCode = RLC or opCode = RRC or
                       opCode = MOV or opCode = ADD or opCode = SUB or opCode = AND_OP or
                       opCode = OR_OP or opCode = IADD or opCode = SHL or opCode = SHR or  -- أضف IADD هنا
                       opCode = LDM or opCode = POP or opCode = LDD else
              '0';

    branch_taken <= '0' when RESET = '1' else
                    '1' when opCode = JMP or opCode = CALL or opCode = RET or opCode = RTI or
                             (opCode = JZ and flags(0) = '1') or
                             (opCode = JN and flags(1) = '1') or
                             (opCode = JC and flags(2) = '1') else
                    '0';

END controle_unit_default;