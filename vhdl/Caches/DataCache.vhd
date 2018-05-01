library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity DataCache is
    generic(
        word_width : integer := 16; 
        cache_size : integer := 512
    );
    port(
        clkc_c, write_enable_in : in std_logic;
        address_in, data_word_in : in std_logic_vector (word_width-1 downto 0);
        
        data_word_out, pc_starting_address, pc_interupt_address : out std_logic_vector (word_width-1 downto 0)
    ) ;
end DataCache;

architecture data_cahce_arch of DataCache is
    type ram_t is array(cache_size-1 downto 0) of std_logic_vector(word_width-1 downto 0); 
    signal ram_s : ram_t;     
begin

    Data_Writing : process( clkc_c )
    begin
        if (write_enable_in = '1') then
            ram_s(to_integer(unsigned(address_in))) <= data_word_in;
        end if;
    end process ; -- Data_Writing

    data_word_out <= ram_s(to_integer(unsigned(address_in)));
    pc_starting_address <= ram_s(PC_STARTING_ADDRESS_INDEX);
    pc_interupt_address <= ram_s(PC_INTERUPT_ADDRESS_INDEX);
end data_cahce_arch ; -- data_cahce_arch