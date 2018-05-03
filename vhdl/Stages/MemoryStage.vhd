library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity MemoryStage is
    port (
        clk_c, enable_in, memory_read_write_in : in std_logic;
         -- enable_in : write to cache and saving to buffer

        -- this is saved in the buffer by the EU, then the buffer sends it to the EU
       is_return_interrupt_in : in std_logic;

        --Memory buffer must output memory_needs
        memory_data_src_selection_in : in std_logic;
        memry_address_in, data_from_execute_in, data_from_memory_in: in std_logic_vector(15 downto 0);

        memory_data_out, pc_address_out : out std_logic_vector(15 downto 0); -- will be put in r_dst
        flags_out : out std_logic_vector(3 downto 0);

        pc_starting_address_out, pc_interrupt_address_out : out  std_logic_vector(15 downto 0)
    ) ;
end MemoryStage;

architecture memory_stage_arch of MemoryStage is

    component DataCache is
        generic(
            word_width : integer := 16; 
            cache_size : integer := 512
        );
        port(
            clkc_c, write_enable_in : in std_logic;
            address_in, data_word_in : in std_logic_vector (word_width-1 downto 0);
            
            data_word_out, pc_starting_address, pc_interupt_address : out std_logic_vector (word_width-1 downto 0)
        ) ;
    end component;

    signal memory_input_s, data_word_s : std_logic_vector(15 downto 0);
    signal memory_write_enable_s : std_logic;

begin

    memory_input_s <= data_from_execute_in when memory_data_src_selection_in = MEMORY_SRC_NORMAL
    else data_from_memory_in when memory_data_src_selection_in = MEMORY_SRC_SELF
    else (others => 'Z');

    memory_write_enable_s <= '1' when enable_in =  ENABLE_MEMORY and memory_read_write_in = MEMORY_WRITE
    else '0';

    Data_Cache : DataCache generic map (word_width=>16,cache_size=>512) port map (
        clkc_c => clk_c, write_enable_in => memory_write_enable_s,
        address_in => memry_address_in, data_word_in => memory_input_s,
        data_word_out => data_word_s , pc_starting_address => pc_starting_address_out,
        pc_interupt_address => pc_interrupt_address_out
    );

    memory_data_out <= data_word_s;

    pc_address_out <= x"0" & data_word_s(15 downto 6) when is_return_interrupt_in = '1'
    else data_word_s;

    flags_out <= data_word_s(5 downto 2);
end memory_stage_arch ; -- memory_stage_arch