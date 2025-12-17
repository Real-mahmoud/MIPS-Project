LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.cpu_pkg.ALL;

ENTITY CPU IS
    PORT (
        clk, RESET : IN STD_LOGIC;
        inPort     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        outPort    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_pc       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_ir       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug_mem_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END CPU;

ARCHITECTURE CPU_arch OF CPU IS

    -- Fetch
    SIGNAL PCFetch, IRFetch     : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- IF/ID
    SIGNAL PCDecode, IRDecode   : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Hazards & Branch
    SIGNAL loadUse              : STD_LOGIC;
    SIGNAL branch_taken         : STD_LOGIC;
    SIGNAL branch_target        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL flush_if_id          : STD_LOGIC;

    -- Flags
    SIGNAL flags                : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Writeback
    SIGNAL RdstNewValue         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstNumMEMWB         : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Hazard signals
    SIGNAL loadFlagEXMEM        : STD_LOGIC;
    SIGNAL RdestNumEXMEM        : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- ===== ID/EX Inputs (from Decode) =====
    SIGNAL rdst_IDEX_in         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rsrc_IDEX_in         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL offset_IDEX_in       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL inputport_IDEX_in    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstNum_IDEX_in      : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rsrcNum_IDEX_in      : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL control_IDEX_in      : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- ===== ID/EX Outputs (to Execute) =====
    SIGNAL rdst_IDEX_out        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rsrc_IDEX_out        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL offset_IDEX_out      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL inputport_IDEX_out   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdstNum_IDEX_out     : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rsrcNum_IDEX_out     : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL control_IDEX_out     : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- ===== EX/MEM Inputs (from Execute) =====
    SIGNAL alu_EXMEM_in         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdest_EXMEM_in       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdest_num_EXMEM_in   : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL control_EXMEM_in     : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- ===== EX/MEM Outputs (to Memory) =====
    SIGNAL alu_EXMEM_out        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdest_EXMEM_out      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdest_num_EXMEM_out  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL control_EXMEM_out    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL sp_EXMEM_out         : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- ===== MEM/WB =====
    SIGNAL memOut_MEMWB         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL aluOut_MEMWB         : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL control_MEMWB        : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL sp_MEMWB             : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Debug
    debug_pc      <= PCFetch;
    debug_ir      <= IRDecode;
    debug_mem_out <= memOut_MEMWB;

    -- Branch target
    branch_target <= STD_LOGIC_VECTOR(
        unsigned(PCDecode) + unsigned(resize(signed(IRDecode(15 DOWNTO 0)), 32))
    ) WHEN branch_taken = '1' ELSE
        STD_LOGIC_VECTOR(unsigned(PCDecode) + 4);

    flush_if_id <= branch_taken;

    -- Fetch Stage
    fetch_stage : ENTITY work.fetch
        PORT MAP (
            clk           => clk,
            reset         => RESET,
            loadUse       => loadUse,
            IRin          => NOP_IR,
            pcIn          => PCDecode,
            branch_taken  => branch_taken,
            branch_target => branch_target,
            pcOut         => PCFetch,
            IR            => IRFetch
        );

    -- IF/ID Register
    if_id_reg : ENTITY work.IF_ID_Register
        PORT MAP (
            clk    => clk,
            reset  => RESET,
            stall  => loadUse,
            flush  => flush_if_id,
            pc_in  => PCFetch,
            ir_in  => IRFetch,
            pc_out => PCDecode,
            ir_out => IRDecode
        );

    decode_stage : ENTITY work.decoding_stage
        GENERIC MAP (controlSignalsSize => 32)
        PORT MAP (
            clk               => clk,
            pc                => PCDecode,
            IR                => IRDecode,
            RdstNewValue      => RdstNewValue,
            RdstWriteBackNum  => rdstNumMEMWB,
            inputPort         => inPort,
            flags             => flags,
            RESET             => RESET,
            loadFlagEXMEM     => loadFlagEXMEM,
            RdestNumEXMEM     => RdestNumEXMEM,
            rdstNumMEMWB      => rdstNumMEMWB,  -- <-- السطر الجديد ده
            pcOut             => open,
            rdstOut           => rdst_IDEX_in,
            rsrcOut           => rsrc_IDEX_in,
            offsetOut         => offset_IDEX_in,
            inputportOut      => inputport_IDEX_in,
            rdstNumOut        => rdstNum_IDEX_in,
            rsrcNumOut        => rsrcNum_IDEX_in,
            controlSignalsOut => control_IDEX_in
        );

    -- ID/EX Register
    id_ex_reg : ENTITY work.id_ex_register
        PORT MAP (
            clk           => clk,
            reset         => RESET,
            stall         => loadUse,
            flush         => branch_taken,
            rdst_in       => rdst_IDEX_in,
            rsrc_in       => rsrc_IDEX_in,
            offset_in     => offset_IDEX_in,
            inputport_in  => inputport_IDEX_in,
            rdst_num_in   => rdstNum_IDEX_in,
            rsrc_num_in   => rsrcNum_IDEX_in,
            control_in    => control_IDEX_in,
            rdst_out      => rdst_IDEX_out,
            rsrc_out      => rsrc_IDEX_out,
            offset_out    => offset_IDEX_out,
            inputport_out => inputport_IDEX_out,
            rdst_num_out  => rdstNum_IDEX_out,
            rsrc_num_out  => rsrcNum_IDEX_out,
            control_out   => control_IDEX_out
        );

    -- Execute Stage
    execute_stage : ENTITY work.execute_stage
        GENERIC MAP (n => 32, controlSignalSize => 32)
        PORT MAP (
            clk         => clk,
            RESET       => RESET,
            Rdest       => rdst_IDEX_out,
            Rsrc        => rsrc_IDEX_out,
            memOut      => memOut_MEMWB,
            aluOut      => aluOut_MEMWB,
            inPort      => inputport_IDEX_out,
            offset      => offset_IDEX_out,
            RdestNumID  => rdstNum_IDEX_out,
            RsrcNumID   => rsrcNum_IDEX_out,
            RdestNumMem => rdstNumMEMWB,
            RdestNumEX  => RdestNumEXMEM,
            wbEX        => control_EXMEM_out(2),
            wbMem       => control_MEMWB(2),
            control     => control_IDEX_out,
            flagIn      => flags,
            flagOut     => flags,
            RdestOutEX  => rdest_EXMEM_in,
            aluOutEX    => alu_EXMEM_in,
            outPort     => outPort,
            RdestNum    => rdest_num_EXMEM_in,
            controlOut  => control_EXMEM_in
        );

    -- EX/MEM Register
    ex_mem_reg : ENTITY work.ex_mem_register
        PORT MAP (
            clk           => clk,
            reset         => RESET,
            alu_out_in    => alu_EXMEM_in,
            rdest_out_in  => rdest_EXMEM_in,
            rdest_num_in  => rdest_num_EXMEM_in,
            control_in    => control_EXMEM_in,
            sp_in         => sp_MEMWB,
            alu_out_out   => alu_EXMEM_out,
            rdest_out_out => rdest_EXMEM_out,
            rdest_num_out => rdest_num_EXMEM_out,
            control_out   => control_EXMEM_out,
            sp_out        => sp_EXMEM_out
        );

    RdestNumEXMEM <= rdest_num_EXMEM_out;

    -- Memory Stage
    memory_stage : ENTITY work.memory
        PORT MAP (
            clk                 => clk,
            RESET               => RESET,
            memRead             => control_EXMEM_out(0),
            memWrite            => control_EXMEM_out(1),
            memAddressSelector  => control_EXMEM_out(9),
            Rdest               => rdest_EXMEM_out,
            ALUout              => alu_EXMEM_out,
            spIn                => sp_EXMEM_out,
            controlSignalsIn    => control_EXMEM_out,
            rdstNum             => RdestNumEXMEM,
            memOut              => memOut_MEMWB,
            aluOutMem           => aluOut_MEMWB,
            controlSignalsOut   => control_MEMWB,
            rdestNumOut         => rdstNumMEMWB,
            spOut               => sp_MEMWB
        );

    -- MEM/WB Register
    mem_wb_reg : ENTITY work.mem_wb_register
        PORT MAP (
            clk         => clk,
            reset       => RESET,
            mem_out_in  => memOut_MEMWB,
            alu_out_in  => aluOut_MEMWB,
            rdst_num_in => rdstNumMEMWB,
            control_in  => control_MEMWB,
            mem_out_out => memOut_MEMWB,
            alu_out_out => aluOut_MEMWB,
            rdst_num_out=> rdstNumMEMWB,
            control_out => control_MEMWB
        );

    -- Write Back Stage
    write_back_stage : ENTITY work.write_back
        PORT MAP (
            RESET         => RESET,
            rdstNum       => rdstNumMEMWB,
            aluOut        => aluOut_MEMWB,
            memOut        => memOut_MEMWB,
            controlSignals=> control_MEMWB,
            rdstNewValue  => RdstNewValue
        );

    -- Hazard Detection
    loadFlagEXMEM <= control_EXMEM_out(0);

    hazard_unit : ENTITY work.load_use_detection
        PORT MAP (
            IR            => IRDecode,
            loadFlagEXMEM => loadFlagEXMEM,
            RdestNumEXMEM => RdestNumEXMEM,
            loadUse       => loadUse
        );

END CPU_arch;