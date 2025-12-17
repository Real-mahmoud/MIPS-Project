LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY data_memory IS
	GENERIC (
		memorySize : INTEGER := 65536;
		dataLineWidth : INTEGER := 32;
		addressLineWidth : INTEGER := 16
	);
	PORT (
		clk, RESET, memRead, memWrite : IN STD_LOGIC;
		address : IN STD_LOGIC_VECTOR(addressLineWidth - 1 DOWNTO 0);
		data : IN STD_LOGIC_VECTOR(dataLineWidth - 1 DOWNTO 0);
		spOpSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		memOut : OUT STD_LOGIC_VECTOR(dataLineWidth - 1 DOWNTO 0)
	);
END data_memory;

ARCHITECTURE arch OF data_memory IS
	TYPE ram_type IS ARRAY(0 TO memorySize - 1) OF STD_LOGIC_VECTOR(addressLineWidth - 1 DOWNTO 0);
	SIGNAL ram : ram_type;
BEGIN
	memory_lbl : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) AND memWrite = '1' AND RESET = '0' THEN
			ram(to_integer(unsigned(address)) + 1) <= data(addressLineWidth - 1 DOWNTO 0);
			ram(to_integer(unsigned(address))) <= data(dataLineWidth - 1 DOWNTO addressLineWidth);
		END IF;
	END PROCESS; -- memory_lbl
	-- Safe indexing using lower 16 bits
memOut(addressLineWidth - 1 DOWNTO 0) <= 
    ram(to_integer(unsigned(address(15 DOWNTO 0))) + 1) WHEN (memRead = '1' AND spOpSelect /= "01") ELSE
    ram(to_integer(unsigned(address(15 DOWNTO 0))) + 3) WHEN (memRead = '1') ELSE
    (OTHERS => '0');

memOut(dataLineWidth - 1 DOWNTO addressLineWidth) <= 
    ram(to_integer(unsigned(address(15 DOWNTO 0)))) WHEN (memRead = '1' AND spOpSelect /= "01") ELSE
    ram(to_integer(unsigned(address(15 DOWNTO 0))) + 2) WHEN (memRead = '1') ELSE
    (OTHERS => '0');

END arch;