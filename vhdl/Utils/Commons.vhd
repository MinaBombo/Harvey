library ieee;
use ieee.std_logic_1164.all;

package Commons is

    constant WORD_TYPE_INSTRUCTION       : std_logic_vector(1 downto 0) := "00";
    constant WORD_TYPE_IMMEDIATE         : std_logic_vector(1 downto 0) := "01";
    constant WORD_TYPE_EFFECTIVE_ADDRESS : std_logic_vector(1 downto 0) := "10";

    constant DISABLE_WRITEBACK    : std_logic_vector(1 downto 0) := "00";
    constant ENABLE_WRITEBACK_1   : std_logic_vector(1 downto 0) := "01";
    constant ENABLE_WRITEBACK_all : std_logic_vector(1 downto 0) := "11";

    constant ENABLE_MEMORY  : std_logic := '1';
    constant DISABLE_MEMORY : std_logic := '0';
    constant MEMORY_READ  : std_logic := '1';
    constant MEMORY_WRITE : std_logic := '0';

    constant ALU_OP_NOP  : std_logic_vector(4 downto 0) := "00000";
    constant ALU_OP_ADD  : std_logic_vector(4 downto 0) := "00001";
    constant ALU_OP_SUB  : std_logic_vector(4 downto 0) := "00010";
    constant ALU_OP_AND  : std_logic_vector(4 downto 0) := "00011";
    constant ALU_OP_OR   : std_logic_vector(4 downto 0) := "00100";
    constant ALU_OP_RLC  : std_logic_vector(4 downto 0) := "00101";
    constant ALU_OP_RRC  : std_logic_vector(4 downto 0) := "00110";
    constant ALU_OP_SHL  : std_logic_vector(4 downto 0) := "00111";
    constant ALU_OP_SHR  : std_logic_vector(4 downto 0) := "01000";
    constant ALU_OP_SETC : std_logic_vector(4 downto 0) := "01001";
    constant ALU_OP_CLRC : std_logic_vector(4 downto 0) := "01010";
    constant ALU_OP_NOT  : std_logic_vector(4 downto 0) := "01011";
    constant ALU_OP_INC  : std_logic_vector(4 downto 0) := "01100";
    constant ALU_OP_DEC  : std_logic_vector(4 downto 0) := "01101";
    
    
    constant OP_MOV  : std_logic_vector(4 downto 0) := "10000";
    constant OP_MUL  : std_logic_vector(4 downto 0) := "10001";
    constant OP_PUSH : std_logic_vector(4 downto 0) := "10010";
    constant OP_POP  : std_logic_vector(4 downto 0) := "10011";
    constant OP_OUT  : std_logic_vector(4 downto 0) := "10100";
    constant OP_IN   : std_logic_vector(4 downto 0) := "10101";
    constant OP_JZ   : std_logic_vector(4 downto 0) := "10110";
    constant OP_JN   : std_logic_vector(4 downto 0) := "10111";
    constant OP_JC   : std_logic_vector(4 downto 0) := "11000";
    constant OP_JMP  : std_logic_vector(4 downto 0) := "11001";
    constant OP_CALL : std_logic_vector(4 downto 0) := "11010";
    constant OP_RET  : std_logic_vector(4 downto 0) := "11011";
    constant OP_RTI  : std_logic_vector(4 downto 0) := "11100";
    constant OP_LDM  : std_logic_vector(4 downto 0) := "11101";
    constant OP_LDD  : std_logic_vector(4 downto 0) := "11110";
    constant OP_STD  : std_logic_vector(4 downto 0) := "11111";

    constant MEMORY_READ_WRITE_CW_INDEX    : integer := 0;
    constant ENABLE_MEMORY_CW_INDEX        : integer := 1;
    constant ENABLE_WRITEBACK_CW_INDEX_LOW : integer := 2;
    constant ENABLE_WRITEBACK_CW_INDEX_UP  : integer := 3;
    constant INPUT_WORD_TYPE_CW_INDEX_LOW  : integer := 4;
    constant INPUT_WORD_TYPE_CW_INDEX_UP   : integer := 5;

end package Commons;