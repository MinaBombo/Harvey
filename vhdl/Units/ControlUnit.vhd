library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity ControlUnit is
    port (
        reset_in, interrupt_in : in std_logic;
        opcode_in : in std_logic_vector(4 downto 0);
        interrupt_reset_in : in std_logic; --Comes from memory buffer
        jump_taken_in : in std_logic;
        return_reset_in : in std_logic;

        is_interrupt_out : out std_logic;
        is_return_out : out std_logic;

        reset_fetch_decode_out : out std_logic;
        reset_decode_execute_out : out std_logic;
        reset_execute_memory_out : out std_logic;
        reset_memory_writeback_out : out std_logic;

        enable_memory_out, memory_read_write_out : out std_logic;
        enable_writeback_out, input_word_type_out : out std_logic_vector(1 downto 0);

        enable_pc_increment_out :out std_logic
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

    signal reset_fetch_decode_s : std_logic;

    signal enable_pc_increment_s : std_logic;
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

    reset_fetch_decode_s <= '1' when jump_taken_in = '1' or opcode_in = OP_CALL or is_return_s = '1' or reset_in = '1';
    reset_fetch_decode_out <= reset_fetch_decode_s;

    reset_decode_execute_out <= '1' when jump_taken_in = '1' or reset_in = '1';
    reset_execute_memory_out <= reset_in;
    reset_memory_writeback_out <= reset_in;

    enable_pc_increment_out <= '0' when reset_fetch_decode_s = '1' or  is_interrupt_s = '1' -- Anded with FU output
    else '1';
end control_unit_arch ; -- control_unit_arch

