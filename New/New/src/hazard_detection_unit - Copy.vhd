LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY hazard_detection_unit IS
    PORT (
        loadFlagEXMEM     : IN STD_LOGIC;
        rdestNumEXMEM     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rsrcNumID         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rdestNumID        : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        branch_taken      : IN STD_LOGIC;

        loadUse           : OUT STD_LOGIC;
        flush_if_id       : OUT STD_LOGIC
    );
END hazard_detection_unit;

ARCHITECTURE arch OF hazard_detection_unit IS
BEGIN
    loadUse     <= '1' WHEN loadFlagEXMEM = '1' AND 
                            (rdestNumEXMEM = rsrcNumID OR rdestNumEXMEM = rdestNumID)
                   ELSE '0';

    flush_if_id <= branch_taken;
END arch;