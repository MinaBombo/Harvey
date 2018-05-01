library ieee;
use ieee.std_logic_1164.all;

entity nBitsDoubleRegister is
    generic (
        n : integer
    );
    port (
        clk_c, enable1_in, enable2_in, reset_in : in std_logic;
        data1_in, data2_in : in std_logic_vector(n-1 downto 0);

        data_out : out std_logic_vector(n-1 downto 0)
    );
end nBitsDoubleRegister;

architecture n_bits_double_register_arch of nBitsDoubleRegister is
    component nBitRegister is
        generic (
            n : integer
        );
        port (
            clk_c, enable_in, reset_in : in std_logic;
            data_in : in std_logic_vector(n-1 downto 0);
    
            data_out : out std_logic_vector(n-1 downto 0)
        );
    end component;

    signal data_s : std_logic_vector(n-1 downto 0);
    signal enable_s : std_logic;

begin
    enable_s <= enable1_in or enable2_in;
    data_s <= data1_in when enable1_in = '1' 
    else data2_in when enable2_in = '1'
    else (others => 'Z');

    Inner_Register : nBitRegister generic map (n => n) port map (
        clk_c => clk_c, enable_in => enable_s, reset_in => reset_in, data_in => data_s,
        data_out => data_out
    );
end n_bits_double_register_arch ; -- n_bits_double_register_arch

