LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.cpu_pkg.ALL;  -- For NOP_IR if needed elsewhere

ENTITY CPU IS
    PORT (
        clk, RESET : IN STD_LOGIC;
        inPort     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        outPort    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Debug ports
        debug_pc       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_ir       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_mem_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END CPU;

ARCHITECTURE CPU_arch OF CPU IS

    -- Fetch signals
    SIGNAL PCFetch      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL IRFetch      : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- IF/ID pipeline register outputs
    SIGNAL PCDecode     : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL IRDecode     : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Hazard & branch signals
    SIGNAL loadUse      : STD_LOGIC;
    SIGNAL branch_taken : STD_LOGIC;
    SIGNAL branch_target: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL flush_if_id  : STD_LOGIC;

    -- Other inter-stage signals (keep your existing ones)
    SIGNAL flags                : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL RdstNewValue         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstNumOutMEMWBOut   : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL loadFlagEXMEM        : STD_LOGIC;
    SIGNAL loadFlagMEMWB        : STD_LOGIC;
    SIGNAL RdestNumEXMEM        : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL RdestNumMEMWB        : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rdstOut              : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rsrcOut              : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL offsetOut            : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL inputportOut         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstNumOut           : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rsrcNumOut           : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- ID/EX registers
    SIGNAL PCIDEXOut            : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstOutIDEXOut       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rsrcOutIDEXOut       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL offsetOutIDEXOut     : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL inputportOutIDEXOut  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstNumOutIDEXOut    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rsrcNumOutIDEXOut    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL controlSignalsOutIDEXOut : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- EX/MEM signals
    SIGNAL RdestOutEXBuffOut    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL aluOutEXBuffOut      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL RdestNumBuffOut      : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL flagOutBuffOut       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL controlOutBuffOut    : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- MEM/WB signals
    SIGNAL memOutMEMWBOut       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL aluOutMEMWBOut       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL controlSignalsOutMEMWBOut : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL spOutMEMWBOut        : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Debug outputs
    debug_pc       <= PCFetch;
    debug_ir       <= IRDecode;         -- Current instruction in decode stage
    debug_mem_out  <= memOutMEMWBOut;

    -- Branch logic
    flush_if_id    <= branch_taken;
    branch_target <= STD_LOGIC_VECTOR(
    unsigned(PCDecode) + unsigned(resize(signed(IRDecode(15 DOWNTO 0)), 32))
);
    -- Fetch Stage
    fetch_lbl : ENTITY work.fetch PORT MAP (
        clk           => clk,
        reset         => RESET,
        loadUse       => loadUse,
        IRin          => NOP_IR,         -- Bubble on stall/flush
        pcIn          => PCDecode,       -- Not used if branch_taken, but safe
        branch_taken  => branch_taken,
        branch_target => branch_target,
        pcOut         => PCFetch,
        IR            => IRFetch
    );

    -- IF/ID Pipeline Register (with stall & flush)
    IF_ID_lbl : ENTITY work.IF_ID_Register PORT MAP (
        clk    => clk,
        reset  => RESET,
        stall  => loadUse,
        flush  => flush_if_id,
        pc_in  => PCFetch,
        ir_in  => IRFetch,
        pc_out => PCDecode,
        ir_out => IRDecode
    );

    -- Decode Stage
    decode_stage_lbl : ENTITY work.decoding_stage GENERIC MAP (32) PORT MAP (
        clk                => clk,
        pc                 => PCDecode,
        IR                 => IRDecode,
        RdstNewValue       => RdstNewValue,
        RdstWriteBackNum   => rdstNumOutMEMWBOut,
        inPort             => inPort,
        flags              => flags,
        RESET              => RESET,
        -- Add other inputs as needed from your decoding_stage ports
        pcOut              => PCIDEXOut,
        rdstOut            => rdstOutIDEXOut,
        rsrcOut            => rsrcOutIDEXOut,
        offsetOut          => offsetOutIDEXOut,
        inputportOut       => inputportOutIDEXOut,
        rdstNumOut         => rdstNumOutIDEXOut,
        rsrcNumOut         => rsrcNumOutIDEXOut,
        controlSignalsOut  => controlSignalsOutIDEXOut
        -- Connect branch_taken if control_unit outputs it
    );

    -- ID/EX Pipeline Registers (keep your existing ones)
    -- ... (your decode_stage_reg_lbl_1 to _8)

    -- Execute Stage
    exec_stage_lbl : ENTITY work.execute_stage GENERIC MAP(32, 32) PORT MAP (
        clk           => clk,
        RESET         => RESET,
        Rdest         => rdstOutIDEXOut,
        Rsrc          => rsrcOutIDEXOut,
        -- ... connect all your ports
        control       => controlSignalsOutIDEXOut,
        flagIn        => flagOutBuffOut,
        flagOut       => flagOutBuffOut,  -- update flags
        RdestOutEX    => RdestOutEXBuffOut,
        aluOutEx      => aluOutEXBuffOut,
        outPort       => outPort,
        RdestNum      => RdestNumBuffOut,
        controlOut    => controlOutBuffOut
    );

    -- EX/MEM and MEM/WB registers (keep your existing)
    -- ...

    -- Memory Stage
    memory_stage_lbl : ENTITY work.memory PORT MAP (
        clk                  => clk,
        RESET                => RESET,
        memRead              => controlOutBuffOut(0),
        memWrite             => controlOutBuffOut(1),
        memAddressSelector   => controlOutBuffOut(9),
        Rdest                => RdestOutEXBuffOut,
        ALUout               => aluOutEXBuffOut,
        spIn                 => spOutMEMWBOut,
        controlSignalsIn     => controlOutBuffOut,
        rdstNum              => RdestNumBuffOut,
        memOut               => memOutMEMWBOut,
        aluOutMem            => aluOutMEMWBOut,
        controlSignalsOut    => controlSignalsOutMEMWBOut,
        rdestNumOut          => rdstNumOutMEMWBOut,
        spOut                => spOutMEMWBOut
    );

    -- Write Back
    write_back_lbl : ENTITY work.write_back PORT MAP (
        RESET         => RESET,
        rdstNum       => rdstNumOutMEMWBOut,
        aluOut        => aluOutMEMWBOut,
        memOut        => memOutMEMWBOut,
        controlSignals=> controlSignalsOutMEMWBOut,
        rdstNewValue  => RdstNewValue
    );

    -- Connect branch_taken from control_unit (you need to add it there!)
    -- Example:
    -- control_unit_inst : ENTITY work.control_unit PORT MAP (
    --     IR => IRDecode,
    --     flags => flags,
    --     ...
    --     branch_taken => branch_taken
    -- );

END CPU_arch;