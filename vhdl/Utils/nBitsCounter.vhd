library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nBitsCounter is
    generic (
        n : integer
    );
    port (
        -- count_direction_in : 1 for up 0 for down
        clk_c, count_enable_in, count_direction_in, load_enable_in : in std_logic;
        parallel_load_in : in std_logic_vector(n-1 downto 0);

        data_out : out std_logic_vector(n-1 downto 0)
    );
end nBitsCounter;

architecture n_bits_counter_arch of nBitsCounter is
   signal data_s : std_logic_vector(n-1 downto 0);
begin
    process(clk_c, load_enable_in)
    begin
        if (load_enable_in = '1') then
            data_s <= parallel_load_in;
        elsif (rising_edge(clk_c)) then
            if (count_enable_in = '1') then 
                if (count_direction_in = '1') then
                    data_s <= std_logic_vector(unsigned(data_s)+1);
                else 
                    data_s <= std_logic_vector(unsigned(data_s)-1);
                end if;
            end if;
        end if;
    end process ;
    data_out <= data_s;
end n_bits_counter_arch ; -- n_bits_counter_arch

