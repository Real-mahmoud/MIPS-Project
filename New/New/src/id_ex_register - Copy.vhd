LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY id_ex_register IS
    PORT (
        clk, reset, stall, flush : IN STD_LOGIC;

        rdst_in        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc_in        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        offset_in      : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        inputport_in   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdst_num_in    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rsrc_num_in    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        control_in     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        rdst_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc_out       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        offset_out     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        inputport_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdst_num_out   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rsrc_num_out   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        control_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END id_ex_register;

ARCHITECTURE arch OF id_ex_register IS
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            rdst_out      <= (OTHERS => '0');
            rsrc_out      <= (OTHERS => '0');
            offset_out    <= (OTHERS => '0');
            inputport_out <= (OTHERS => '0');
            rdst_num_out  <= (OTHERS => '0');
            rsrc_num_out  <= (OTHERS => '0');
            control_out   <= (OTHERS => '0');

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                control_out <= (OTHERS => '0');  -- Bubble
            ELSIF stall = '0' THEN
                rdst_out      <= rdst_in;
                rsrc_out      <= rsrc_in;
                offset_out    <= offset_in;
                inputport_out <= inputport_in;
                rdst_num_out  <= rdst_num_in;
                rsrc_num_out  <= rsrc_num_in;
                control_out   <= control_in;
            END IF;
        END IF;
    END PROCESS;
END arch;