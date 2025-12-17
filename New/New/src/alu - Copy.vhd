LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY alu IS
  GENERIC (n : INTEGER := 32);
  PORT (
    A, B : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    selector : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
    cin : IN STD_LOGIC;
    F : OUT STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    cout : OUT STD_LOGIC
  );
END alu;

ARCHITECTURE a_alu OF alu IS

  COMPONENT addernbit IS
    GENERIC (n : INTEGER := 32);
    PORT (
      x, y : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
      cin : IN STD_LOGIC;
      s : OUT STD_LOGIC_VECTOR (n-1 DOWNTO 0);
      cout : OUT STD_LOGIC
    );
  END COMPONENT;

  SIGNAL FADD, FSUB, FINC, FDEC : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
  SIGNAL CADD, CSUB, CINC, CDEC : STD_LOGIC;
  SIGNAL FINV, NEGB : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
  SIGNAL CNEGB : STD_LOGIC;
  SIGNAL LEFTB, RIGHTB : STD_LOGIC_VECTOR(n-1 DOWNTO 0);

  CONSTANT ONE      : STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (0 => '1', OTHERS => '0');
  CONSTANT ALL_ONES : STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (OTHERS => '1');  -- -1 in two's complement

BEGIN

  -- NOT B
  FINV <= NOT B;

  -- -B = ~B + 1
  NegB_Adder: addernbit GENERIC MAP(n) PORT MAP(FINV, ONE, '0', NEGB, CNEGB);

  -- A + B
  Adder: addernbit GENERIC MAP(n) PORT MAP(A, B, '0', FADD, CADD);

  -- A - B = A + (-B)
  Sub_Adder: addernbit GENERIC MAP(n) PORT MAP(A, NEGB, '0', FSUB, CSUB);

  -- INC (A + 1)
  Inc_Adder: addernbit GENERIC MAP(n) PORT MAP(A, ONE, '0', FINC, CINC);

  -- DEC (A - 1) = A + x"FFFFFFFF"
  Dec_Adder: addernbit GENERIC MAP(n) PORT MAP(A, ALL_ONES, '0', FDEC, CDEC);

  -- ???? ????? ?? ?? ??...

  -- Logical shifts (arithmetic not needed since no sign extend required in your ISA)
  LEFTB  <= STD_LOGIC_VECTOR(shift_left(unsigned(B), to_integer(unsigned(A(4 DOWNTO 0)))));
  RIGHTB <= STD_LOGIC_VECTOR(shift_right(unsigned(B), to_integer(unsigned(A(4 DOWNTO 0)))));

  -- Main output mux
  F <= (OTHERS => '0')               WHEN selector = "0001" ELSE  -- Clear / Zero
       FINV                          WHEN selector = "0010" ELSE  -- NOT
       FINC                          WHEN selector = "0011" ELSE  -- INC
       NEGB                          WHEN selector = "0100" ELSE  -- NEG
       FDEC                          WHEN selector = "0101" ELSE  -- DEC
       B(n-2 DOWNTO 0) & cin         WHEN selector = "0110" ELSE  -- RLC
       cin & B(n-1 DOWNTO 1)         WHEN selector = "0111" ELSE  -- RRC
       A                             WHEN selector = "1000" ELSE  -- MOV
       FADD                          WHEN selector = "1001" ELSE  -- ADD
       FSUB                          WHEN selector = "1010" ELSE  -- SUB
       (A AND B)                     WHEN selector = "1011" ELSE  -- AND
       (A OR B)                      WHEN selector = "1100" ELSE  -- OR
       LEFTB                         WHEN selector = "1101" ELSE  -- SHL
       RIGHTB                        WHEN selector = "1110" ELSE  -- SHR
       B;  -- Default (or NOP)

  -- Carry out mux
  cout <= CINC WHEN selector = "0011" ELSE
          CNEGB WHEN selector = "0100" ELSE
          CDEC WHEN selector = "0101" ELSE
          B(n-1) WHEN selector = "0110" OR selector = "1101" ELSE  -- MSB into carry for RLC/SHL
          B(0) WHEN selector = "0111" OR selector = "1110" ELSE    -- LSB out for RRC/SHR
          CADD WHEN selector = "1001" ELSE
          CSUB WHEN selector = "1010" ELSE
          cin;  -- Default keep previous carry

END a_alu;