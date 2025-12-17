-- cpu_pkg.vhd
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE cpu_pkg IS
    -- Define your NOP instruction here
    -- Change this if your design uses a different encoding for NOP
    -- Common safe choices:
    -- x"00000000"                  -- all zero (very common)
    -- or something like MOV R0, R0 if that does nothing in your ISA
    CONSTANT NOP_IR : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";

    -- Optional: add other shared constants later
    -- CONSTANT INITIAL_SP : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"0003FFFE";
    -- CONSTANT RESET_PC   : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";

END PACKAGE cpu_pkg;