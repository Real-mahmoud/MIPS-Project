LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mem_wb_register IS
    PORT (
        clk, reset : IN STD_LOGIC;

        mem_out_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_out_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdst_num_in    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        control_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        mem_out_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_out_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdst_num_out   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        control_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END mem_wb_register;

ARCHITECTURE arch OF mem_wb_register IS
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            mem_out_out  <= (OTHERS => '0');
            alu_out_out  <= (OTHERS => '0');
            rdst_num_out <= (OTHERS => '0');
            control_out  <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            mem_out_out  <= mem_out_in;
            alu_out_out  <= alu_out_in;
            rdst_num_out <= rdst_num_in;
            control_out  <= control_in;
        END IF;
    END PROCESS;
END arch;