library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity ControlWordsRom is
    port (
        opcode_in : in std_logic_vector(4 downto 0);

        enable_memory_out, memory_read_write_out : out std_logic;
        enable_writeback_out : out std_logic_vector(1 downto 0);
        input_word_type_out : out std_logic_vector(1 downto 0)
    );
end ControlWordsRom;

architecture control_words_rom_arch of ControlWordsRom is
    type rom_t is array(31 downto 0) of std_logic_vector(5 downto 0); 
    constant rom_s : rom_t := (

        0  => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        1  => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        2  => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        3  => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        4  => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        5  => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        6  => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        7  => WORD_TYPE_IMMEDIATE & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        8  => WORD_TYPE_IMMEDIATE & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        9  => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        10 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        11 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        12 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        13 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
       
        
        ---------------
        -- Forbidden -- 14 & 15 
        ---------------
        14 => (others => 'Z'),
        15 => (others => 'Z'),

        16 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        17 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_all & DISABLE_MEMORY & MEMORY_WRITE,
        18 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & ENABLE_MEMORY & MEMORY_WRITE,
        19 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & ENABLE_MEMORY & MEMORY_READ,
        20 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE, -- OUT enable always 1 don't care for signal
        21 => WORD_TYPE_INSTRUCTION & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        22 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        23 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        24 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        25 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & DISABLE_MEMORY & MEMORY_WRITE,
        26 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & ENABLE_MEMORY & MEMORY_WRITE,
        27 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & ENABLE_MEMORY & MEMORY_READ,
        28 => WORD_TYPE_INSTRUCTION & DISABLE_WRITEBACK & ENABLE_MEMORY & MEMORY_READ,
        29 => WORD_TYPE_IMMEDIATE & ENABLE_WRITEBACK_1 & DISABLE_MEMORY & MEMORY_WRITE,
        30 => WORD_TYPE_EFFECTIVE_ADDRESS & ENABLE_WRITEBACK_1 & ENABLE_MEMORY & MEMORY_READ,
        31 => WORD_TYPE_EFFECTIVE_ADDRESS & DISABLE_WRITEBACK & ENABLE_MEMORY & MEMORY_WRITE
    );     
    signal index_s : integer := 0;
begin
    
    index_s <= to_integer(unsigned(opcode_in));
    enable_memory_out     <= rom_s(index_s)(ENABLE_MEMORY_CW_INDEX);
    memory_read_write_out <= rom_s(index_s)(MEMORY_READ_WRITE_CW_INDEX);
    enable_writeback_out  <= rom_s(index_s)(ENABLE_WRITEBACK_CW_INDEX_UP downto ENABLE_WRITEBACK_CW_INDEX_LOW);
    input_word_type_out   <= rom_s(index_s)(INPUT_WORD_TYPE_CW_INDEX_UP downto INPUT_WORD_TYPE_CW_INDEX_LOW);
end control_words_rom_arch ; -- control_words_rom_arch