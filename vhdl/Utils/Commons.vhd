library ieee;
use ieee.std_logic_1164.all;

package Commons is

    constant WORD_TYPE_INSTRUCTION       : std_logic_vector(1 downto 0) := "00";
    constant WORD_TYPE_IMMEDIATE         : std_logic_vector(1 downto 0) := "01";
    constant WORD_TYPE_EFFECTIVE_ADDRESS : std_logic_vector(1 downto 0) := "10";

end package Commons;