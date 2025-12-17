LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY DataHazardUnit IS
    PORT (
        immFlag                : IN STD_LOGIC;
        rsrc                   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rdstMEMWB              : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rdstEXMEM              : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rdstWBSeclectorMEMWB   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);  -- e.g., "01"=from ALU, "10"=from MEM
        rdstWBSeclectorEXMEM   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        in1Mux                 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- for Rsrc (or A input)
        in2Mux                 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)  -- for Rdst (or B input)
    );
END DataHazardUnit;

ARCHITECTURE DataHazardUnitDefault OF DataHazardUnit IS
BEGIN
    -- Forwarding for input 1 (usually Rsrc)
    in1Mux <= "01" WHEN (rdstEXMEM = rsrc AND rdstWBSeclectorEXMEM /= "00") ELSE
              "10" WHEN (rdstMEMWB = rsrc AND rdstWBSeclectorMEMWB /= "00") ELSE
              "00";

    -- Forwarding for input 2 (usually Rdst or immediate path)
    in2Mux <= "00" WHEN immFlag = '1' ELSE  -- Immediate: take from offset
              "01" WHEN (rdstEXMEM = rsrc AND rdstWBSeclectorEXMEM /= "00") ELSE
              "10" WHEN (rdstMEMWB = rsrc AND rdstWBSeclectorMEMWB /= "00") ELSE
              "00";

END DataHazardUnitDefault;