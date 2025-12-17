LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY branch_unit IS
    PORT (
        pc            : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        ir            : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        branch_taken  : IN STD_LOGIC;
        branch_target : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END branch_unit;

ARCHITECTURE arch OF branch_unit IS
BEGIN
    branch_target <= STD_LOGIC_VECTOR(
unsigned(pc) + unsigned(resize(signed(ir(15 DOWNTO 0)), 32))) WHEN branch_taken = '1' ELSE
 STD_LOGIC_VECTOR(unsigned(pc) + 4);  -- next instruction
END arch;