library ieee;
use ieee.std_logic_1164.all;

package Commons is

    constant WORD_TYPE_INSTRUCTION       : std_logic_vector(1 downto 0) := "00";
    constant WORD_TYPE_IMMEDIATE         : std_logic_vector(1 downto 0) := "01";
    constant WORD_TYPE_EFFECTIVE_ADDRESS : std_logic_vector(1 downto 0) := "10";

    constant FETCHED : std_logic_vector := '1';
    constant NOT_FETCHED : std_logic_vector := '0';

    constant OPCODE_HIGHER_LIMIT : integer := 15;
    constant R_SRC_HIGHER_LIMIT  : integer := 10;
    constant R_DST_HIGHER_LIMIT  : integer := 7;
    constant R_DST_LOWER_LIMIT   : integer := 5;

    constant DISABLE_WRITEBACK    : std_logic_vector(1 downto 0) := "00";
    constant ENABLE_WRITEBACK_1   : std_logic_vector(1 downto 0) := "01";
    --constant ENABLE_WRITEBACK_2 : std_logic_vector(1 downto 0) := "10"; (Forbidden) Can't write in src without dst
    constant ENABLE_WRITEBACK_all : std_logic_vector(1 downto 0) := "11"; -- mult
    -- Same and deduced from above but for useful naming 
    constant WILL_CHANGE_NOTHING : std_logic_vector(1 downto 0) := "00";
    constant WILL_CHANGE_DST     : std_logic_vector(1 downto 0) := "01";
    constant WILL_CHANGE_BOTH    : std_logic_vector(1 downto 0) := "11";

    constant NEEDS_NOTHING  : std_logic_vector(1 downto 0) := "00";
    constant NEED_DST       : std_logic_vector(1 downto 0) := "01";
    constant NEED_SRC       : std_logic_vector(1 downto 0) := "10";
    constant NEED_BOTH      : std_logic_vector(1 downto 0) := "11";


    constant HAS_ALL    : std_logic_vector (1 downto 0 ):= "00";
    constant HAS_SRC    : std_logic_vector (1 downto 0 ):= "01";
    constant HAS_DST    : std_logic_vector (1 downto 0 ):= "10";
    constant HAS_NONE   : std_logic_vector (1 downto 0 ):= "11";

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
    
    -- Common between CU and FU
    constant NO_STALL     : std_logic_vector(1 downto 0) := "00";
    constant STALL_DECODE : std_logic_vector(1 downto 0) := "01";
    -- Unique to CU
    constant CU_STALL_FETCH            : std_logic_vector(1 downto 0) := "10";
    constant CU_STALL_FETCH_AND_DECODE : std_logic_vector(1 downto 0) := "11";
    -- Unique to FU
    constant FU_STALL_EXECUTE : std_logic_vector(1 downto 0) := "10";
    -- "11" (forbidden): won't stall from any other stage 

    constant DECODE_DST_NORMAL  : std_logic_vector(1 downto 0) := "00";
    constant DECODE_DST_EXECUTE : std_logic_vector(1 downto 0) := "01";
    constant DECODE_DST_MEMORY  : std_logic_vector(1 downto 0) := "10";
    -- "11" (forbidden): won't take dst for decode from any other place 

    constant EXECUTE_SELECT_NORMAL  : std_logic_vector(1 downto 0) := "00";
    constant EXECUTE_SELECT_SELF    : std_logic_vector(1 downto 0) := "00";
    constant EXECUTE_SELECT_MEMORY  : std_logic_vector(1 downto 0) := "10";
    -- "11" (forbidden): won't take register for execute from any other place 

    constant NO_FORWARD_POSSIBLE : std_logic_vector(1 downto 0) := "11";
    -- Must be stall

    constant MEMORY_SRC_NORMAL  : std_logic := '0';
    constant MEMORY_SRC_SELF    : std_logic := '1';

    constant COUNT_UP   : std_logic := '1';
    constant COUNT_DOWN : std_logic := '0';

    constant SP_NO_OP : std_logic_vector(1 downto 0) := "00";
    constant SP_PUSH  : std_logic_vector(1 downto 0) := "01";
    constant SP_POP   : std_logic_vector(1 downto 0) := "10";
    -- "11" (forbidden): sp doesn't perform any more operations

    constant SP_INITIAL_ADDRESS : std_logic_vector(15 downto 0) := x"01FF";

    constant PC_STARTING_ADDRESS_INDEX : integer := 0;
    constant PC_INTERUPT_ADDRESS_INDEX : integer := 1;

    constant FLAG_ZERO_INDEX     : integer := 0;
    constant FLAG_NEGATIVE_INDEX : integer := 1;
    constant FLAG_CARRY_INDEX    : integer := 2;
    constant FLAG_OVERFLOW_INDEX : integer := 3;
    
    constant IN_PORT_INDEX  : std_logic_vector(2 downto 0) := "110";
    constant OUT_PORT_INDEX : std_logic_vector(2 downto 0) := "111";
end package Commons;