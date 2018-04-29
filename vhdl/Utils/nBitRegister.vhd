library ieee;
use ieee.std_logic_1164.all;

entity nBitRegister is
    generic (
        n : integer
    );
    port (
        clk_c, enable_in, reset_in : in std_logic;
        data_in : in std_logic_vector(n-1 downto 0);

        data_out : out std_logic_vector(n-1 downto 0)
    );
end nBitRegister;

architecture n_bit_register_unit_arch of nBitRegister is
   signal data_s : std_logic_vector(n-1 downto 0);
begin
    process(clk_c, reset_in)
    begin
        if (reset_in = '1') then
            data_s <= (others => '0');
        elsif (rising_edge(clk_c)) then
            if (enable_in = '1') then 
                data_s <= data_in;
            end if;
        end if;
    end process ;
    data_out <= data_s;
end n_bit_register_unit_arch ; -- n_bit_register_unit_arch

