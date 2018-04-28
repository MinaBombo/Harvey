library ieee;
use ieee.std_logic_1164.all;

entity FetchStage is
    generic (
        word_width : integer := 16;
        cache_size : integer := 512
    );
    port (
        clk_c : in std_logic;
        current_instruction_address_in : in std_logic_vector(word_width-1 downto 0);
        
        current_instruction_address_out, data_word_out : out std_logic_vector(word_width-1 downto 0)
    ) ;
end FetchStage;

architecture fetch_stage_arch of FetchStage is
    component InstructionCache is
        generic(
            word_width : integer := 16; 
            cache_size : integer := 512
        );
        port(
            address_in : in std_logic_vector (word_width-1 downto 0);
            data_word_out : out std_logic_vector (word_width-1 downto 0)
        ) ;
    end component;

    signal data_word_s, instruction_address_s : std_logic_vector(word_width-1 downto 0);
begin
    Instruction_Cache: InstructionCache generic map (word_width => word_width, cache_size => cache_size) 
                       port map(address_in => instruction_address_s, data_word_out => data_word_s);
    
    Current_Address_Latching : process( clk_c )
    begin
        if (rising_edge(clk_c)) then
            instruction_address_s <= current_instruction_address_in;
        end if;
    end process ; -- Current_Address_Latching
    current_instruction_address_out <=instruction_address_s;

    data_word_out <= data_word_s;
end fetch_stage_arch ; -- fetch_stage_arch