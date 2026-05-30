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

    constant FETCH : integer := 0;
    constant DECODE : integer := 1;
    constant EXECUTE : integer := 2;
    constant MEM : integer := 3;
    constant WB : integer := 4;
    constant TRAP : integer := 5;


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

    -- pour recuperer les registres du cpu
    signal i_reg_all : std_logic_vector(1023 downto 0);
    type regfile_t is array (0 to 31) of std_logic_vector(31 downto 0);
    signal reg       : regfile_t;

    -- pour recuperer dmem du cpu
    signal i_dmem_all : std_logic_vector(8191 downto 0);
    type dmem_t is array (0 to 255) of std_logic_vector(31 downto 0);
    signal dmem : dmem_t;


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
            pc_dbg  => pc_dbg);

        -- recuperation des registres du cpu
	i_reg_all <= <<signal dut.registers_all : std_logic_vector(1023 downto 0)>>;
        g1:for i in 0 to 31 generate
              reg(i) <= i_reg_all(31+(32*i) downto 32*i);
        end generate;

        -- recuperation de dmem du cpu
        i_dmem_all <= <<signal dut.dmem_all : std_logic_vector(8191 downto 0)>>;
        g2: for i in 0 to 255 generate
               dmem(i) <= i_dmem_all(31+(32*i) downto 32*i);
        end generate;



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

        -- -----------------------------------------------
        -- Affichage du banc de registres
        -- -----------------------------------------------
        assert false report "==== REGISTERS ====" severity Note;

        for i in 0 to 7 loop
            assert false report "r" & integer'image(i) & " = 0x" & to_hex8(reg(i)) severity Note;
        end loop;

        -- -----------------------------------------------
        -- Affichage de la mémoire de données
        -- -----------------------------------------------
        assert false report "==== MEMORY ====" severity Note;

        for i in 128 to 135 loop
            assert false report "MEM[" & integer'image(i) & "] = 0x" & to_hex8(dmem(i)) severity Note;
        end loop;

        -- -----------------------------------------------
        -- Vérification automatique
        -- -----------------------------------------------
        if    dmem(128) = x"00000000"
          and dmem(129) = x"00000001"
          and dmem(130) = x"00000002"
          and dmem(131) = x"00000003"
          and dmem(132) = x"00000004"
        then
            assert false report "TEST PASSED" severity Note;
        else
            assert false report "TEST FAILED" severity Note;
        end if;

        -- Fin de simulation
        std.env.finish;
        wait;
    end process;

    -- =====================================================
    -- Processus de trace (équivalent always @posedge clk)
    -- Affiche l'instruction en cours à l'état WB
    -- =====================================================
    trace_proc : process(clk)
        variable l      : line;
        -- Accès aux signaux internes du DUT via VHDL-2008 external name
--    type state_t is (FETCH, DECODE, EXECUTE, MEM, WB, TRAP);

        alias dut_state      is <<signal dut.state : integer>>;
        alias dut_opcode     is <<signal dut.opcode     : std_logic_vector(6 downto 0)>>;
        alias dut_alu_ctrl   is <<signal dut.alu_ctrl   : std_logic_vector(3 downto 0)>>;
        alias dut_PC         is <<signal dut.PC         : std_logic_vector(31 downto 0)>>;
        alias dut_instruction is <<signal dut.instruction : std_logic_vector(31 downto 0)>>;
        alias dut_rd         is <<signal dut.rd         : std_logic_vector(4 downto 0)>>;
        alias dut_rs1        is <<signal dut.rs1        : std_logic_vector(4 downto 0)>>;
        alias dut_rs2        is <<signal dut.rs2        : std_logic_vector(4 downto 0)>>;
        alias dut_imm        is <<signal dut.imm        : std_logic_vector(31 downto 0)>>;
        alias dut_alu_result is <<signal dut.alu_result : std_logic_vector(31 downto 0)>>;
        alias dut_dmem_data  is <<signal dut.dmem_data  : std_logic_vector(31 downto 0)>>;
        alias dut_read_data2 is <<signal dut.read_data2 : std_logic_vector(31 downto 0)>>;

        -- Lecture du banc de registres DUT
--        impure function reg(idx : std_logic_vector(4 downto 0)) return std_logic_vector is
--        begin
--            return <<signal dut.registers : dut.rtl.regfile_t>>;
--            return <<signal dut.registers : std_logic_vector(1023 downto 0)>>;
--        end function;

        -- PC + imm (pour affichage branchement)
        impure function pc_plus_imm return std_logic_vector is
        begin
            return std_logic_vector(unsigned(dut_PC) + unsigned(dut_imm));
        end function;

    begin
        if rising_edge(clk) then

            if reset = '0' then
                assert false report "RESET" severity Note;

            elsif dut_state = WB then

                case dut_opcode is

                    -- -----------------------------------
                    -- R-TYPE
                    -- -----------------------------------
                    when "0110011" =>
                        case dut_alu_ctrl is
                            when "0000" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (R) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " + r" & to_reg(dut_rs2) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs2)))) & ")" &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when "0001" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (R) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " & r" & to_reg(dut_rs2) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs2)))) & ")" &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when "0010" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (R) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " | r" & to_reg(dut_rs2) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs2)))) & ")" &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when "0011" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (R) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " ^ r" & to_reg(dut_rs2) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs2)))) & ")" &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when others =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (R) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " ?? r" & to_reg(dut_rs2) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs2)))) & ")" &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                        end case;

                    -- -----------------------------------
                    -- I-TYPE
                    -- -----------------------------------
                    when "0010011" =>
                        case dut_alu_ctrl is
                            when "0000" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (I) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " + 0x" & to_hex8(dut_imm) &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when "0001" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (I) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " & 0x" & to_hex8(dut_imm) &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when "0010" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (I) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " | 0x" & to_hex8(dut_imm) &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when "0011" =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (I) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " ^ 0x" & to_hex8(dut_imm) &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                            when others =>
                                assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                                      " (I) r" & to_reg(dut_rd) &
                                      " = r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                                      " ?? 0x" & to_hex8(dut_imm) &
                                      " = 0x" & to_hex8(dut_alu_result) severity Note;
                        end case;

                    -- -----------------------------------
                    -- LOAD
                    -- -----------------------------------
                    when "0000011" =>
                        assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                              " (L) r" & to_reg(dut_rd) &
                              " = mem[r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                              "+0x" & to_hex8(dut_imm) & "]" &
                              " = 0x" & to_hex8(dut_dmem_data) severity Note;
                        writeline(output, l);

                    -- -----------------------------------
                    -- STORE
                    -- -----------------------------------
                    when "0100011" =>
                        assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                              " (S) mem[r" & to_reg(dut_rs1) & "(0x" & to_hex8(reg(to_integer(unsigned(dut_rs1)))) & ")" &
                              "+0x" & to_hex8(dut_imm) & "]" &
                              " = r" & to_reg(dut_rs2) & "(0x" & to_hex8(dut_read_data2) & ")" severity Note;

                    -- -----------------------------------
                    -- BRANCH
                    -- -----------------------------------
                    when "1100011" =>
                        assert false report "0x" & to_hex8(dut_PC) & ":0x" & to_hex8(dut_instruction) &
                              " (B) PC = PC + (0x" & to_hex8(dut_imm) & ")" &
                              " = 0x" & to_hex8(pc_plus_imm) severity Note;

                    when others =>
                        assert false report "UNKNOW !" severity Note;

                end case;
            end if;
        end if;
    end process;

end architecture sim;
