LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.cpu_pkg.ALL;  -- للـ NOP_IR

ENTITY fetch IS
    PORT (
        clk, reset, loadUse : IN STD_LOGIC;
        IRin : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        pcIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- مش مستخدم فعليًا، بس خليه لو عايز
        branch_taken : IN STD_LOGIC;
        branch_target : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        pcOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        IR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END fetch;

ARCHITECTURE fetch_arch OF fetch IS

    SIGNAL pc_reg       : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');  -- PC register
    SIGNAL pc_next      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_plus_4    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL instruction  : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- PC Register (synchronous reset to 0)
    pc_reg_proc : PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            pc_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF loadUse = '0' THEN  -- stall only stops fetch
                pc_reg <= pc_next;
            END IF;
        END IF;
    END PROCESS;

    pcOut <= pc_reg;  -- Current PC to IF/ID and debug

    -- PC + 4 (normal increment)
    pc_plus_4 <= STD_LOGIC_VECTOR(unsigned(pc_reg) + 4);

    -- Instruction Memory
    instr_mem : ENTITY work.instructions_memory
        GENERIC MAP (memorySize => 65536, dataLineWidth => 32, addressLineWidth => 16)
        PORT MAP (
            reset       => reset,
            PC          => pc_reg,
            instruction => instruction
        );

    -- PC Next mux (branch first, then stall)
    pc_next <= branch_target when branch_taken = '1' else
               pc_plus_4;  -- normal +4

    -- IR output with stall and flush handling
    IR <= NOP_IR when (loadUse = '1' or branch_taken = '1' or reset = '1') else  -- bubble on stall or branch flush
          instruction;

END fetch_arch;