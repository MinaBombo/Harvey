library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity InstructionCache is
    generic(
        word_width : integer := 16; 
        cache_size : integer := 512
    );
    port(
        address_in : in std_logic_vector (word_width-1 downto 0);
        
        data_word_out : out std_logic_vector (word_width-1 downto 0)
    ) ;
end InstructionCache;

architecture instruction_cahce_arch of InstructionCache is
    type ram_t is array(cache_size-1 downto 0) of std_logic_vector(word_width-1 downto 0); 
    signal ram_s : ram_t;     
begin
    data_word_out <= ram_s(to_integer(unsigned(address_in)));
end instruction_cahce_arch ; -- instruction_cahce_arch