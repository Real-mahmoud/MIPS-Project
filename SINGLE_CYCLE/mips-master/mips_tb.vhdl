library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_tb is
end entity;

architecture sim of mips_tb is

    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';
    signal memwrite  : std_logic;
    signal readdata  : std_logic_vector(31 downto 0);
    signal address   : std_logic_vector(31 downto 0);
    signal writedata : std_logic_vector(31 downto 0);

    -- Simple data memory (256 words)
    type mem_t is array (0 to 255) of std_logic_vector(31 downto 0);
    signal data_mem : mem_t := (others => (others => '0'));

begin

    -- Clock generation (50 MHz equivalent)
    clk <= not clk after 10 ns;

    -- DUT
    uut: entity work.MIPS
        port map (
            clk       => clk,
            reset     => reset,
            memwrite  => memwrite,
            readdata  => readdata,
            address   => address,
            writedata => writedata
        );

    -- Data memory model
    process(clk)
    begin
        if rising_edge(clk) then
            if memwrite = '1' then
                data_mem(to_integer(unsigned(address(9 downto 2)))) <= writedata;
            end if;
        end if;
    end process;

    -- Combinational read
    readdata <= data_mem(to_integer(unsigned(address(9 downto 2))));

    -- Stimulus
    process
    begin
        -- Reset
        reset <= '1';
        wait for 40 ns;
        reset <= '0';

        -- Let the program run
        wait for 2000 ns;

        -- Stop simulation
        assert false report "Simulation finished" severity failure;
    end process;

end architecture;
