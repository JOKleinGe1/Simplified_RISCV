-- =====================================================
-- tb_riscv.vhd
-- Traduction VHDL du testbench RISC-V simplifié
-- =====================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_riscv is
end entity tb_riscv;

architecture sim of tb_riscv is

    -- =====================================================
    -- Déclaration du composant DUT
    -- =====================================================
    component riscv_simple is
        port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            inport  : in  std_logic_vector(7 downto 0);
            outport : out std_logic_vector(7 downto 0);
            pc_dbg  : out std_logic_vector(23 downto 0)
        );
    end component;

    -- =====================================================
    -- Signaux de stimulation
    -- =====================================================
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '0';
    signal inport  : std_logic_vector(7 downto 0) := x"C8";
    signal outport : std_logic_vector(7 downto 0);
    signal pc_dbg  : std_logic_vector(23 downto 0);

    -- Période d'horloge : 10 ns  (équivalent #5 / #5)
    constant CLK_PERIOD : time := 10 ns;

    -- =====================================================
    -- Fonction utilitaire : slv -> hex string (8 chiffres)
    -- =====================================================
    function to_hex8(slv : std_logic_vector(31 downto 0)) return string is
        constant HEX_CHARS : string(1 to 16) := "0123456789abcdef";
        variable result    : string(1 to 8);
        variable nibble    : integer;
    begin
        for i in 0 to 7 loop
            nibble := to_integer(unsigned(slv(31 - i*4 downto 28 - i*4)));
            result(i + 1) := HEX_CHARS(nibble + 1);
        end loop;
        return result;
    end function;

    -- Variante 24 bits (pc_dbg)
    function to_hex6(slv : std_logic_vector(23 downto 0)) return string is
        constant HEX_CHARS : string(1 to 16) := "0123456789abcdef";
        variable result    : string(1 to 6);
        variable nibble    : integer;
    begin
        for i in 0 to 5 loop
            nibble := to_integer(unsigned(slv(23 - i*4 downto 20 - i*4)));
            result(i + 1) := HEX_CHARS(nibble + 1);
        end loop;
        return result;
    end function;

    -- Variante 5 bits → entier décimal (numéro de registre)
    function to_reg(slv : std_logic_vector(4 downto 0)) return string is
    begin
        return integer'image(to_integer(unsigned(slv)));
    end function;

begin

    -- =====================================================
    -- Instanciation du DUT
    -- =====================================================
    dut : riscv_simple
        port map (
            clk     => clk,
            reset   => reset,
            inport  => inport,
            outport => outport,
            pc_dbg  => pc_dbg
        );

    -- =====================================================
    -- Génération horloge (10 ns)
    -- =====================================================
    clk <= not clk after CLK_PERIOD / 2;

    -- =====================================================
    -- Processus de stimulation principal
    -- =====================================================
    stim_proc : process
        variable l : line;
    begin

        -- Reset actif (actif bas)
        reset <= '0';
        wait for 20 ns;
        reset <= '1';

        -- Laisser tourner assez longtemps pour la boucle
        wait for 2500 ns;
        inport <= x"A3";
        wait for 500 ns;
       -- assert FALSE report "End of simulation" severity failure;
	std.env.finish;
	wait;
     end process;

end architecture sim;
