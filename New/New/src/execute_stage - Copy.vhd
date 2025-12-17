LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY execute_stage IS
  GENERIC (n : INTEGER := 32; controlSignalSize : INTEGER := 32);
  PORT (
    clk, RESET : IN STD_LOGIC;
    Rdest, Rsrc : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    memOut, aluOut : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    inPort, offset : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    RdestNumID, RsrcNumID, RdestNumMem, RdestNumEX : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
    wbEX, wbMem : IN STD_LOGIC;
    control : IN STD_LOGIC_VECTOR (controlSignalSize-1 DOWNTO 0);
    flagIn: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
    flagOut: OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
    RdestOutEX, aluOutEX, outPort : OUT STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    RdestNum : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
    controlOut : OUT STD_LOGIC_VECTOR (controlSignalSize-1 DOWNTO 0)
  );
END execute_stage;

ARCHITECTURE executeArch OF execute_stage IS
  COMPONENT alu IS
    GENERIC (n : INTEGER := 32);
    PORT (A, B : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
          selector : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
          cin : IN STD_LOGIC;
          F : OUT STD_LOGIC_VECTOR (n-1 DOWNTO 0);
          cout : OUT STD_LOGIC);
  END COMPONENT;

  COMPONENT forwarding IS
    PORT (srcNumID, destNumEX, destNumMem : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
          wbEX, wbMem: IN STD_LOGIC;
          selector: OUT STD_LOGIC_VECTOR (1 DOWNTO 0));
  END COMPONENT;

  COMPONENT flag IS
    PORT (clk,reset, cin, changeEnable,setCarry,clrCarry: IN STD_LOGIC;
          inFlag: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
          F: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
          aluSelect: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
          outFlag: OUT STD_LOGIC_VECTOR (2 DOWNTO 0));
  END COMPONENT;

  SIGNAL aluSelect     : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL writeFlags    : STD_LOGIC;
  SIGNAL writeOut      : STD_LOGIC;
  SIGNAL readInputPort : STD_LOGIC;
  SIGNAL clrCarry, setCarry, immediate : STD_LOGIC;
  SIGNAL srcIn, aluIn1, aluIn2, aluTemp : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
  SIGNAL aluCout       : STD_LOGIC;
  SIGNAL inSel1, inSel2 : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

  aluSelect     <= control(15 DOWNTO 12);
  writeFlags    <= control(3);
  writeOut      <= control(10);
  readInputPort <= control(11);
  clrCarry      <= control(16);
  setCarry      <= control(17);
  immediate     <= control(18);

  srcIn <= inPort WHEN readInputPort = '1' ELSE Rsrc;

  -- Forwarding units
  fwd1: forwarding PORT MAP(RsrcNumID, RdestNumEX, RdestNumMem, wbEX, wbMem, inSel1);
  fwd2: forwarding PORT MAP(RdestNumID, RdestNumEX, RdestNumMem, wbEX, wbMem, inSel2);

  aluIn1 <= aluOut WHEN inSel1 = "10" ELSE
            memOut WHEN inSel1 = "01" ELSE
            srcIn;

  aluIn2 <= offset WHEN immediate = '1' ELSE
            aluOut WHEN inSel2 = "10" ELSE
            memOut WHEN inSel2 = "01" ELSE
            Rdest;

  alu_inst: alu GENERIC MAP(32) PORT MAP(aluIn1, aluIn2, aluSelect, flagIn(2), aluTemp, aluCout);

  flag_inst: flag PORT MAP(clk, RESET, aluCout, writeFlags, setCarry, clrCarry, flagIn, aluTemp, aluSelect, flagOut);

  aluOutEX   <= aluTemp;
  outPort    <= Rdest WHEN writeOut = '1' ELSE (OTHERS => '0');
  RdestOutEX <= aluIn2;  -- Forwarded Rdest (after possible forwarding)
  controlOut <= control;
  RdestNum   <= RdestNumID;

END executeArch;