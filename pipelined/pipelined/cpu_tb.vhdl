library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity cpu_tb is
end entity;

architecture sim of cpu_tb is
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal inPort  : std_logic_vector(31 downto 0) := (others => '0');
    signal outPort : std_logic_vector(31 downto 0);
    
    -- Debug signals
    signal debug_pc       : std_logic_vector(31 downto 0);
    signal debug_ir       : std_logic_vector(31 downto 0);
    signal debug_mem_out  : std_logic_vector(31 downto 0);
    
    -- Test signals (these should match your waveform names)
    signal inputportout : std_logic_vector(31 downto 0);
    signal ir          : std_logic_vector(31 downto 0);
    signal pcdecode    : std_logic_vector(31 downto 0);
    signal pcfetch     : std_logic_vector(31 downto 0);
    signal pcidexin    : std_logic_vector(31 downto 0);
    
begin

    -- Clock generation (10 ns period)
    clk <= not clk after 5 ns;

    -- Instantiate CPU with debug ports
    uut: entity work.CPU
        port map (
            clk           => clk,
            RESET         => reset,
            inPort        => inPort,
            outPort       => outPort,
            debug_pc      => debug_pc,
            debug_ir      => debug_ir,
            debug_mem_out => debug_mem_out
        );

    -- Monitor process - prints to console every clock cycle
    process(clk)
        variable line_out : line;
        variable cycle_count : integer := 0;
    begin
        if rising_edge(clk) then
            cycle_count := cycle_count + 1;
            
            write(line_out, string'("Cycle ") & integer'image(cycle_count));
            write(line_out, string'(" | Reset=") & std_logic'image(reset));
            write(line_out, string'(" | PC="));
            
            -- Check if signal is initialized
            if debug_pc = "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" then
                write(line_out, string'("UNINIT"));
            else
                write(line_out, to_hstring(debug_pc));
            end if;
            
            writeline(output, line_out);
        end if;
    end process;

    -- Stimulus process
    process
    begin
        report "=== STARTING CPU TEST ===";
        
        -- Hold reset for longer
        reset <= '1';
        wait for 100 ns;  -- 10 clock cycles
        
        report "Releasing reset...";
        reset <= '0';
        
        -- Set input value
        inPort <= x"0000000A";
        
        -- Run for many cycles
        wait for 500 ns;
        
        -- Check if anything happened
        if debug_pc = "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" then
            report "ERROR: PC still uninitialized after 500ns!" severity error;
        elsif debug_pc = x"00000000" then
            report "WARNING: PC stuck at 0x00000000" severity warning;
        else
            report "SUCCESS: PC is moving: " & to_hstring(debug_pc);
        end if;
        
        report "=== SIMULATION COMPLETE ===";
        wait;
    end process;

end architecture;