library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity ControlUnit is
    port (
        interrupt_in : in std_logic;
        opcode_in : in std_logic_vector(4 downto 0);
        interrupt_reset_in : in std_logic; --Comes from memory buffer
        jump_taken_in : in std_logic;
        return_reset_in : in std_logic;

        is_interrupt_out : out std_logic;
        is_return_out : out std_logic;

        enable_memory_out, memory_read_write_out : out std_logic;
        enable_writeback_out, input_word_type_out : out std_logic_vector(1 downto 0);

        stall_index_out :  out std_logic_vector(1 downto 0);

        decode_needs_out : out std_logic
    );
end ControlUnit;

architecture control_unit_arch of ControlUnit is
    component ControlWordsRom is
        port (
            opcode_in : in std_logic_vector(4 downto 0);
    
            enable_memory_out, memory_read_write_out : out std_logic;
            enable_writeback_out : out std_logic_vector(1 downto 0);
            input_word_type_out : out std_logic_vector(1 downto 0)
        );
    end component;

    signal is_interrupt_s : std_logic;
    signal is_return_s : std_logic;
begin

    Control_Words_Rom : ControlWordsRom port map (
        opcode_in => opcode_in, enable_memory_out => enable_memory_out, memory_read_write_out => memory_read_write_out, 
        enable_writeback_out => enable_writeback_out, input_word_type_out => input_word_type_out);

    -- Self-lacthing (thanks Dr. Sultan)
    is_interrupt_s <= '0' when interrupt_reset_in = '1' else '1' when  (interrupt_in or is_interrupt_s) = '1' else '0';
    is_interrupt_out <= is_interrupt_s;

    -- Self-lacthing (thanks Dr. Sultan)
    is_return_s <= '0' when return_reset_in = '1' else '1' when  ((opcode_in = OP_RET) or (opcode_in = OP_RTI) or (is_return_s = '1')) else '0';
    is_return_out <= is_return_s;

    decode_needs_out <= '1' when opcode_in = OP_JMP
    else '0';

    stall_index_out <= CU_STALL_FETCH_AND_DECODE when jump_taken_in = '1'
    else CU_STALL_FETCH when opcode_in = OP_CALL or is_interrupt_s ='1' or is_return_s = '1';
end control_unit_arch ; -- control_unit_arch

