library ieee;
use ieee.std_logic_1164.all;

entity oneBitHalfCycleRegister is
    port (
        clk_c, reset_in : in std_logic;
        data_in : in std_logic;

        data_out : out std_logic
    );
end oneBitHalfCycleRegister;

architecture one_bit_half_cycle_register_arch of oneBitHalfCycleRegister is
   signal data_s : std_logic;
begin
    process(clk_c, reset_in)
    begin
        if (reset_in = '1') then
            data_s <= '1';
        elsif (rising_edge(clk_c)) then
            data_s <= data_in;
        elsif (falling_edge(clk_c)) then
            data_s <= '0';
        end if;
    end process ;
    data_out <= data_s;
end one_bit_half_cycle_register_arch ; -- one_bit_half_cycle_register_arch

