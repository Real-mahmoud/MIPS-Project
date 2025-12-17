LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY ex_mem_register IS
    PORT (
        clk, reset : IN STD_LOGIC;

        alu_out_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdest_out_in   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdest_num_in   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        control_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        sp_in          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        alu_out_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdest_out_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdest_num_out  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        control_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        sp_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ex_mem_register;

ARCHITECTURE arch OF ex_mem_register IS
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            alu_out_out    <= (OTHERS => '0');
            rdest_out_out  <= (OTHERS => '0');
            rdest_num_out  <= (OTHERS => '0');
            control_out    <= (OTHERS => '0');
            sp_out         <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            alu_out_out    <= alu_out_in;
            rdest_out_out  <= rdest_out_in;
            rdest_num_out  <= rdest_num_in;
            control_out    <= control_in;
            sp_out         <= sp_in;
        END IF;
    END PROCESS;
END arch;