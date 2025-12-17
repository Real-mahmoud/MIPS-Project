library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;  -- ﬂ›«Ì… ··‹ write Ê line

entity cpu_tb is
end entity;

architecture sim of cpu_tb is

    -- Clock and reset
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';

    -- Ports
    signal inPort  : std_logic_vector(31 downto 0) := (others => '0');
    signal outPort : std_logic_vector(31 downto 0);

    -- Debug ports from CPU
    signal debug_pc       : std_logic_vector(31 downto 0);
    signal debug_ir       : std_logic_vector(31 downto 0);
    signal debug_mem_out  : std_logic_vector(31 downto 0);

    -- Function to convert std_logic_vector to hex string (safe alternative to to_hstring)
    function slv_to_hex (slv : std_logic_vector) return string is
        variable hex : string(1 to 8);  -- 32-bit = 8 hex digits
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in 0 to 7 loop
            nibble := slv((31 - i*4) downto (28 - i*4));
            case nibble is
                when x"0" => hex(i+1) := '0';
                when x"1" => hex(i+1) := '1';
                when x"2" => hex(i+1) := '2';
                when x"3" => hex(i+1) := '3';
                when x"4" => hex(i+1) := '4';
                when x"5" => hex(i+1) := '5';
                when x"6" => hex(i+1) := '6';
                when x"7" => hex(i+1) := '7';
                when x"8" => hex(i+1) := '8';
                when x"9" => hex(i+1) := '9';
                when x"A" => hex(i+1) := 'A';
                when x"B" => hex(i+1) := 'B';
                when x"C" => hex(i+1) := 'C';
                when x"D" => hex(i+1) := 'D';
                when x"E" => hex(i+1) := 'E';
                when x"F" => hex(i+1) := 'F';
                when others => hex(i+1) := 'X';  -- for U/X/etc.
            end case;
        end loop;
        return "0x" & hex;
    end function;

begin

    -- Clock generation
    clk <= not clk after 5 ns;

    -- Instantiate CPU
    uut : entity work.CPU
        port map (
            clk           => clk,
            RESET         => reset,
            inPort        => inPort,
            outPort       => outPort,
            debug_pc      => debug_pc,
            debug_ir      => debug_ir,
            debug_mem_out => debug_mem_out
        );

    -- Monitor process
    monitor_proc : process(clk)
        variable l     : line;
        variable cycle : integer := 0;
    begin
        if rising_edge(clk) then
            cycle := cycle + 1;

            write(l, string'("Cycle "));
            write(l, integer'image(cycle));
            write(l, string'(" | Reset: "));
            write(l, std_logic'image(reset));
            write(l, string'(" | PC: "));
            write(l, slv_to_hex(debug_pc));  -- «” Œœ„‰« «·œ«·… «·¬„‰…
            write(l, string'(" | IR: "));
            write(l, slv_to_hex(debug_ir));

            writeline(output, l);
        end if;
    end process;

    -- Stimulus process
    stimulus_proc : process
    begin
        report "=== CPU TESTBENCH START ===" severity note;

        reset <= '1';
        wait for 100 ns;

        report "Releasing reset..." severity note;
        reset <= '0';

        inPort <= x"0000000A";

        wait for 1000 ns;

        if unsigned(debug_pc) = 0 then
            report "WARNING: PC stuck at 0x00000000" severity warning;
        elsif unsigned(debug_pc) > 20 then
            report "SUCCESS: PC is advancing! Final PC = " & slv_to_hex(debug_pc) severity note;
        else
            report "INFO: PC moved a little: " & slv_to_hex(debug_pc) severity note;
        end if;

        report "=== SIMULATION COMPLETE ===" severity note;
        wait;
    end process;

end architecture sim;