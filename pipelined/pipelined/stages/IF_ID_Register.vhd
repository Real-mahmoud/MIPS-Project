LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY work;
USE work.cpu_pkg.ALL;  -- This gives you access to NOP_IR

ENTITY IF_ID_Register IS
  PORT (
    clk       : IN  STD_LOGIC;
    reset     : IN  STD_LOGIC;
    stall     : IN  STD_LOGIC;
    flush     : IN  STD_LOGIC;
    
    pc_in     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    ir_in     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    pc_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    ir_out    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END IF_ID_Register;

ARCHITECTURE arch OF IF_ID_Register IS
  -- No need to declare NOP_IR here anymore
BEGIN
  PROCESS(clk, reset)
  BEGIN
    IF reset = '1' THEN
      pc_out <= (others => '0');
      ir_out <= NOP_IR;
    ELSIF rising_edge(clk) THEN
      IF flush = '1' THEN
        pc_out <= (others => '0');  -- or keep previous PC if you prefer
        ir_out <= NOP_IR;           -- Insert bubble
      ELSIF stall = '0' THEN
        pc_out <= pc_in;
        ir_out <= ir_in;
      END IF;
    END IF;
  END PROCESS;
END arch;