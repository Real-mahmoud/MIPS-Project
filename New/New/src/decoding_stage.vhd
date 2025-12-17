LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY decoding_stage IS
    GENERIC (
        controlSignalsSize : INTEGER := 32
    );
    PORT (
        clk : IN STD_LOGIC;
        pc : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        IR : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RdstNewValue : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RdstWriteBackNum : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        inputPort : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        flags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        RESET : IN STD_LOGIC;
        loadFlagEXMEM : IN STD_LOGIC;
        RdestNumEXMEM : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rdstNumMEMWB : IN STD_LOGIC_VECTOR(3 DOWNTO 0);  -- تم تعديل الاسم ليطابق cpu.vhd
        pcOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdstOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrcOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        offsetOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        inputportOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdstNumOut : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rsrcNumOut : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        controlSignalsOut : OUT STD_LOGIC_VECTOR(controlSignalsSize - 1 DOWNTO 0)
    );
END decoding_stage;

ARCHITECTURE decoding_stage_arch OF decoding_stage IS
    SIGNAL controlSignals : STD_LOGIC_VECTOR(controlSignalsSize - 1 DOWNTO 0);
BEGIN

    -- Control Unit instantiation (named association عشان ما يحصلش غلط في الترتيب)
    control_unit_lbl : ENTITY work.control_unit PORT MAP (
        IR              => IR,
        flags           => flags,
        RESET           => RESET,
        loadFlagEXMEM   => loadFlagEXMEM,
        RdestNumEXMEM   => RdestNumEXMEM,
        memRead         => controlSignals(0),
        memWrite        => controlSignals(1),
        flagWrite       => controlSignals(3),
        spOperationSelector => controlSignals(5 DOWNTO 4),
        spWrite         => controlSignals(6),
        rdstWBSeclector => controlSignals(8 DOWNTO 7),
        memAddressSelector => controlSignals(9),
        outputPort      => controlSignals(10),
        inputPort       => controlSignals(11),
        aluSelect       => controlSignals(15 DOWNTO 12),
        clrCFlag        => controlSignals(16),
        setCFlag        => controlSignals(17),
        immFlag         => controlSignals(18),
        loadFlag        => controlSignals(19),
        rdstWB          => controlSignals(20),
        branch_taken    => controlSignals(21),
        loadUse         => open  -- مش مستخدم هنا، بيطلع في cpu.vhd
    );

    -- Register File
    register_file_lbl : ENTITY work.register_file PORT MAP (
        clk                 => clk,
        RESET               => RESET,
        IR                  => IR,
        RdstNewValue        => RdstNewValue,
        RdstWriteBacknum    => RdstWriteBackNum,
        spOperationSelector => controlSignals(5 DOWNTO 4),
        rdstWB              => controlSignals(20),
        offset              => offsetOut,
        Rdst                => rdstOut,
        Rsrc                => rsrcOut,
        RdstNum             => rdstNumOut,
        RsrcNum             => rsrcNumOut
    );

    -- Outputs
    controlSignalsOut <= controlSignals;
    pcOut             <= pc;
    inputportOut      <= inputPort;

END decoding_stage_arch;