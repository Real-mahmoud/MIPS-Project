LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY register_file IS
    PORT (
        clk, RESET : IN STD_LOGIC;
        IR : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RdstNewValue : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RdstWriteBacknum : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        spOperationSelector : IN STD_LOGIC_VECTOR(1 DOWNTO 0);  -- "01"=inc+2, "10"=dec-2, else hold
        rdstWB : IN STD_LOGIC;
        offset : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rdst : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rsrc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        RdstNum : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        RsrcNum : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END register_file;

ARCHITECTURE register_file_arch OF register_file IS
    SIGNAL R0, R1, R2, R3, R4, R5, R6, R7 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_reg, sp_reg                 : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Read MUX for Rdst
    rdst_mux : ENTITY work.mux_4x16
        PORT MAP (
            clk      => clk,
            selector => IR(23 DOWNTO 20),
            in0      => R0,
            in1      => R1,
            in2      => R2,
            in3      => R3,
            in4      => R4,
            in5      => R5,
            in6      => R6,
            in7      => R7,
            in8      => pc_reg,
            in9      => sp_reg,
            outData  => Rdst
        );

    -- Read MUX for Rsrc
    rsrc_mux : ENTITY work.mux_4x16
        PORT MAP (
            clk      => clk,
            selector => IR(19 DOWNTO 16),
            in0      => R0,
            in1      => R1,
            in2      => R2,
            in3      => R3,
            in4      => R4,
            in5      => R5,
            in6      => R6,
            in7      => R7,
            in8      => pc_reg,
            in9      => sp_reg,
            outData  => Rsrc
        );

    -- Clocked write process for R0–R7 and PC
    write_proc: PROCESS (clk, RESET)
    BEGIN
        IF RESET = '1' THEN
            R0 <= (OTHERS => '0');
            R1 <= (OTHERS => '0');
            R2 <= (OTHERS => '0');
            R3 <= (OTHERS => '0');
            R4 <= (OTHERS => '0');
            R5 <= (OTHERS => '0');
            R6 <= (OTHERS => '0');
            R7 <= (OTHERS => '0');
            pc_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF rdstWB = '1' THEN
                CASE RdstWriteBacknum IS
                    WHEN "0000" => R0 <= RdstNewValue;
                    WHEN "0001" => R1 <= RdstNewValue;
                    WHEN "0010" => R2 <= RdstNewValue;
                    WHEN "0011" => R3 <= RdstNewValue;
                    WHEN "0100" => R4 <= RdstNewValue;
                    WHEN "0101" => R5 <= RdstNewValue;
                    WHEN "0110" => R6 <= RdstNewValue;
                    WHEN "0111" => R7 <= RdstNewValue;
                    WHEN "1000" => pc_reg <= RdstNewValue;
                    WHEN OTHERS => NULL;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- Separate process for SP (updated on every cycle if push/pop)
    sp_proc: PROCESS (clk, RESET)
        VARIABLE new_sp : UNSIGNED(31 DOWNTO 0);
    BEGIN
        IF RESET = '1' THEN
            sp_reg <= "00000000000000001111111111111110";  -- SP starts at 0xFFFFFFFE (common choice)
        ELSIF rising_edge(clk) THEN
            new_sp := unsigned(sp_reg);
            CASE spOperationSelector IS
                WHEN "01" => new_sp := new_sp + 2;     -- POP: SP += 2
                WHEN "10" => new_sp := new_sp - 2;     -- PUSH: SP -= 2
                WHEN OTHERS => NULL;                   -- Hold
            END CASE;
            sp_reg <= STD_LOGIC_VECTOR(new_sp);
        END IF;
    END PROCESS;

    -- Other outputs
    offset   <= STD_LOGIC_VECTOR(resize(unsigned(IR(15 DOWNTO 0)), 32));
    RdstNum  <= IR(23 DOWNTO 20);
    RsrcNum  <= IR(19 DOWNTO 16);

END register_file_arch;