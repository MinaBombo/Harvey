library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity SP is
    port (
        clk_c, reset_in : in std_logic;
        operation_in : in std_logic_vector(1 downto 0);
        
        address_out : out std_logic_vector(15 downto 0)
    );
end SP;

architecture sp_arch of SP is
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

    signal enable_s : std_logic;
    signal data_s, address_s : std_logic_vector(15 downto 0);

begin

    enable_s <= '0' when operation_in = SP_NO_OP else '1';
    Inner_Register : nBitRegister generic map (n => 16) port map (
        clk_c => clk_c, enable_in => enable_s, reset_in => '0',
        data_in => data_s,
        data_out => address_s
    );

    data_s <= SP_INITIAL_ADDRESS when reset_in = '1' 
    else std_logic_vector(unsigned(address_s)-1) when operation_in = SP_PUSH
    else std_logic_vector(unsigned(address_s)+1) when operation_in = SP_POP 
    else (others => '0');

    address_out <= data_s when operation_in = SP_POP else address_s;

end sp_arch ; -- sp_arch