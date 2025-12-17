
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instructions_memory IS
	GENERIC (
		memorySize : INTEGER := 65536;
		dataLineWidth : INTEGER := 32;
		addressLineWidth : INTEGER := 16
	);
	PORT (
		reset : IN STD_LOGIC;
		PC : IN STD_LOGIC_VECTOR(dataLineWidth - 1 DOWNTO 0);
		m0 : OUT STD_LOGIC_VECTOR(dataLineWidth - 1 DOWNTO 0);
		instruction : OUT STD_LOGIC_VECTOR(dataLineWidth - 1 DOWNTO 0)
	);
END instructions_memory;

ARCHITECTURE arch OF instructions_memory IS
-- Inside ARCHITECTURE arch
TYPE ram_type IS ARRAY (0 TO memorySize-1) OF STD_LOGIC_VECTOR(addressLineWidth-1 DOWNTO 0);

SIGNAL rom : ram_type := (
    -- PC=0: NOP (or a real instruction)
    0 => x"0000",  -- upper half
    1 => x"0000",  -- lower half → full instruction = x"00000000" = NOP

    -- PC=1: ADD R1, R1, R1  (example - adjust to your opcode)
    2 => x"1101",  -- upper: opcode + registers
    3 => x"1101",  -- lower: whatever

    -- PC=2: IADD R2, R2, #10
    4 => x"2202",
    5 => x"000A",

    -- PC=3: OUT R2
    6 => x"9002",
    7 => x"0000",

    OTHERS => x"0000"
);
	----------------------------
	FUNCTION to_string (a : STD_LOGIC_VECTOR) RETURN STRING IS
		VARIABLE b : STRING (1 TO a'length) := (OTHERS => NUL);
		VARIABLE stri : INTEGER := 1;
	BEGIN
		FOR i IN a'RANGE LOOP
			b(stri) := STD_LOGIC'image(a((i)))(2);
			stri := stri + 1;
		END LOOP;
		RETURN b;
	END FUNCTION;
	---------------
BEGIN
	m0(addressLineWidth - 1 DOWNTO 0) <= rom(0);
	m0(dataLineWidth - 1 DOWNTO addressLineWidth) <= (OTHERS => '0');
	--instruction <= (OTHERS => '0') WHEN reset = '1';

	instruction(addressLineWidth-1 DOWNTO 0) <= rom(to_integer(unsigned(PC(15 DOWNTO 0))) + 1);
	instruction(dataLineWidth-1 DOWNTO addressLineWidth) <= rom(to_integer(unsigned(PC(15 DOWNTO 0))));

END arch;