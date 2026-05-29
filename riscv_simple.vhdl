-- =====================================================
-- riscv_simple.vhd
-- Traduction VHDL du processeur RISC-V simplifié
-- =====================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_simple is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        inport  : in  std_logic_vector(7 downto 0);
        outport : out std_logic_vector(7 downto 0);
        pc_dbg  : out std_logic_vector(23 downto 0)
    );
end entity riscv_simple;

architecture rtl of riscv_simple is

    -- =====================================================
    -- TYPES MEMOIRES
    -- =====================================================
    type imem_t is array (0 to 255) of std_logic_vector(31 downto 0);
    type dmem_t is array (0 to 255) of std_logic_vector(31 downto 0);
    type regfile_t is array (0 to 31) of std_logic_vector(31 downto 0);

    -- =====================================================
    -- ETATS
    -- =====================================================
    constant FETCH : integer := 0;
    constant DECODE : integer := 1;
    constant EXECUTE : integer := 2;
    constant MEM : integer := 3;
    constant WB : integer := 4;
    constant TRAP : integer := 5;
    signal state : integer;

--    type state_t is (FETCH, DECODE, EXECUTE, MEM, WB, TRAP);
--    signal state : state_t;

    -- =====================================================
    -- CPU
    -- =====================================================
    signal PC          : std_logic_vector(31 downto 0);
    signal instruction : std_logic_vector(31 downto 0);

signal imem : imem_t := (
X"00000093",
X"00500113",
X"20000193",
X"00000293",
X"0011a023",
X"0001a203",
X"00108093",
X"00418193",
X"004282b3",
X"00208463",
X"fe0004e3",
X"40000193",
X"0001a203",
X"00f24093",
X"0011a223",
X"fe0008e3",
others => X"00000000" );

    -- =====================================================
    -- BANC DE REGISTRES
    -- =====================================================
    signal registers : regfile_t := (others => X"00000000");
    signal registers_all : std_logic_vector(1023 downto 0);

    -- =====================================================
    -- MEMOIRE DE DONNEES
    -- =====================================================
    signal dmem      : dmem_t := (others => X"00000000");
    signal dmem_data : std_logic_vector(31 downto 0);
    signal dmem_all  : std_logic_vector(8191 downto 0);

    -- =====================================================
    -- DECODE
    -- =====================================================
    signal opcode : std_logic_vector(6 downto 0);
    signal rd     : std_logic_vector(4 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal rs1    : std_logic_vector(4 downto 0);
    signal rs2    : std_logic_vector(4 downto 0);

    signal read_data1 : std_logic_vector(31 downto 0);
    signal read_data2 : std_logic_vector(31 downto 0);

    -- =====================================================
    -- IMMEDIATS
    -- =====================================================
    signal imm_i : std_logic_vector(31 downto 0);
    signal imm_s : std_logic_vector(31 downto 0);
    signal imm_b : std_logic_vector(31 downto 0);
    signal imm   : std_logic_vector(31 downto 0);

    -- =====================================================
    -- SIGNAUX DE CONTROLE
    -- =====================================================
    signal reg_write  : std_logic;
    signal alu_src    : std_logic;
    signal branch     : std_logic;
    signal mem_read   : std_logic;
    signal mem_write  : std_logic;
    signal mem_to_reg : std_logic;

    -- =====================================================
    -- ALU
    -- =====================================================
    signal alu_ctrl   : std_logic_vector(3 downto 0);
    signal alu_in2    : std_logic_vector(31 downto 0);
    signal alu_result : std_logic_vector(31 downto 0);

    -- =====================================================
    -- BRANCH
    -- =====================================================
    signal zero : std_logic;

begin
    -- pour que tb recupere les registres
    g1:for i in 0 to 31 generate
          registers_all(31+(32*i) downto 32*i) <= registers(i);
    end generate;

    -- pour que le tb recupere dmem
    g2: for i in 0 to 255 generate
          dmem_all(31+(32*i) downto 32*i) <= dmem(i);
    end generate;

    -- =====================================================
    -- DECODE (signaux combinatoires issus de l'instruction)
    -- =====================================================
    opcode <= instruction(6 downto 0);
    rd     <= instruction(11 downto 7);
    funct3 <= instruction(14 downto 12);
    rs1    <= instruction(19 downto 15);
    rs2    <= instruction(24 downto 20);

    -- =====================================================
    -- IMMEDIATS
    -- =====================================================
    imm_i <= (31 downto 12 => instruction(31)) & instruction(31 downto 20);

    imm_s <= (31 downto 12 => instruction(31)) &
             instruction(31 downto 25) &
             instruction(11 downto 7);

    imm_b <= (31 downto 13 => instruction(31)) &
             instruction(31) &
             instruction(7) &
             instruction(30 downto 25) &
             instruction(11 downto 8) &
             '0';

    imm <= imm_b when opcode = "1100011" else
           imm_s when opcode = "0100011" else
           imm_i;

    -- =====================================================
    -- SIGNAUX DE CONTROLE
    -- =====================================================
    reg_write  <= '1' when (opcode = "0110011" or
                            opcode = "0010011" or
                            opcode = "0000011") else '0';

    alu_src    <= '1' when (opcode = "0010011" or
                            opcode = "0000011" or
                            opcode = "0100011") else '0';

    branch     <= '1' when opcode = "1100011" else '0';
    mem_read   <= '1' when opcode = "0000011" else '0';
    mem_write  <= '1' when opcode = "0100011" else '0';
    mem_to_reg <= '1' when opcode = "0000011" else '0';

    -- =====================================================
    -- DEBUG PC
    -- =====================================================
    pc_dbg <= PC(23 downto 0);

    -- =====================================================
    -- ALU CONTROL (combinatoire)
    -- =====================================================
    process(opcode, funct3)
    begin
        case opcode is
            -- R-TYPE
            when "0110011" =>
                case funct3 is
                    when "000"  => alu_ctrl <= "0000"; -- ADD
                    when "111"  => alu_ctrl <= "0001"; -- AND
                    when "110"  => alu_ctrl <= "0010"; -- OR
                    when "100"  => alu_ctrl <= "0011"; -- XOR
                    when others => alu_ctrl <= "0000";
                end case;
            -- I-TYPE
            when "0010011" =>
                case funct3 is
                    when "000"  => alu_ctrl <= "0000"; -- ADDI
                    when "100"  => alu_ctrl <= "0011"; -- XORI
                    when others => alu_ctrl <= "0000";
                end case;
            -- LOAD / STORE
            when "0000011" | "0100011" =>
                alu_ctrl <= "0000";
            when others =>
                alu_ctrl <= "0000";
        end case;
    end process;

    -- =====================================================
    -- ALU (combinatoire)
    -- =====================================================
    alu_in2 <= imm when alu_src = '1' else read_data2;

    process(alu_ctrl, read_data1, alu_in2)
    begin
        case alu_ctrl is
            when "0000" =>
                alu_result <= std_logic_vector(
                    unsigned(read_data1) + unsigned(alu_in2));
            when "0001" =>
                alu_result <= read_data1 and alu_in2;
            when "0010" =>
                alu_result <= read_data1 or alu_in2;
            when "0011" =>
                alu_result <= read_data1 xor alu_in2;
            when others =>
                alu_result <= (others => '0');
        end case;
    end process;

    -- =====================================================
    -- BRANCH : comparaison pour BEQ
    -- =====================================================
    zero <= '1' when read_data1 = read_data2 else '0';

    -- =====================================================
    -- MACHINE D'ETAT (synchrone)
    -- =====================================================
    process(clk)
    begin
        if rising_edge(clk) then

            if reset = '0' then
                PC    <= (others => '0');
                state <= FETCH;

            else
                case state is

                    -- -----------------------------------------
                    -- FETCH
                    -- -----------------------------------------
                    when FETCH =>
                        instruction <= imem(to_integer(unsigned(PC(9 downto 2))));
                        state <= DECODE;

                    -- -----------------------------------------
                    -- DECODE
                    -- -----------------------------------------
                    when DECODE =>
                        read_data1 <= registers(to_integer(unsigned(rs1)));
                        read_data2 <= registers(to_integer(unsigned(rs2)));
                        state <= EXECUTE;

                    -- -----------------------------------------
                    -- EXECUTE
                    -- -----------------------------------------
                    when EXECUTE =>
                        state <= MEM;

                    -- -----------------------------------------
                    -- MEM
                    -- -----------------------------------------
                    when MEM =>
                        -- Accès mémoire données (bit 10 = 0)
                        if alu_result(10) = '0' then
                            if mem_read = '1' then
                                dmem_data <= dmem(to_integer(unsigned(alu_result(9 downto 2))));
                            end if;
                            if mem_write = '1' then
                                dmem(to_integer(unsigned(alu_result(9 downto 2)))) <= read_data2;
                            end if;
                        end if;

                        -- Accès GPIO (adresse 0x400 / 0x404, bit 10 = 1)
                        if alu_result(10) = '1' then
                            if mem_read = '1' and alu_result(10 downto 0) = "10000000000" then
                                -- adresse 0x400
                                dmem_data <= x"000000" & inport;
                            end if;
                            if mem_write = '1' and alu_result(10 downto 0) = "10000000100" then
                                -- adresse 0x404
                                outport <= read_data2(7 downto 0);
                            end if;
                        end if;

                        state <= WB;

                    -- -----------------------------------------
                    -- WRITEBACK
                    -- -----------------------------------------
                    when WB =>
                        -- Ecriture registre
                        if reg_write = '1' and rd /= "00000" then
                            if mem_to_reg = '1' then
                                registers(to_integer(unsigned(rd))) <= dmem_data;
                            else
                                registers(to_integer(unsigned(rd))) <= alu_result;
                            end if;
                        end if;

                        -- Mise à jour du PC
                        if branch = '1' and zero = '1' then
                            PC <= std_logic_vector(unsigned(PC) + unsigned(imm));
                        else
                            PC <= std_logic_vector(unsigned(PC) + 4);
                        end if;

                        state <= FETCH;

                    when TRAP =>
                        null;

		    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- =====================================================
    -- INITIALISATION (simulation uniquement)
    -- =====================================================
    -- Note : l'initialisation du banc de registres à zéro
    -- et le chargement de imem via $readmemh n'ont pas
    -- d'équivalent synthétisable en VHDL standard.
    -- Pour la simulation, utiliser un process d'initialisation
    -- ou un testbench dédié avec std.textio.

end architecture rtl;
