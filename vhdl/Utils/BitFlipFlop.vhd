library ieee;
use ieee.std_logic_1164.all;

entity BitFlipFlop is
    port (
        clk_c, reset_in : in std_logic;
        data_in : in std_logic;

        data_out : out std_logic
    );
end BitFlipFlop;

architecture bit_flip_flop_unit_arch of BitFlipFlop is
   signal data_s : std_logic;
begin
    process(clk_c, reset_in)
    begin
        if (reset_in = '1') then
            data_s <= '0';
        elsif (rising_edge(clk_c)) then
                data_s <= data_in;
        end if;
    end process ;
    data_out <= data_s;
end bit_flip_flop_unit_arch ; -- bit_flip_flop_unit_arch

