library ieee;
use ieee.std_logic_1164.all;

entity FetchDecodeBuffer is
    generic (
        word_width : integer := 16
    );
    port (
        clk_c, enable_in, reset_in : in std_logic;
        is_interrupt_in : in std_logic; -- Comes from CU
        next_instruction_address_in, data_word_in: in std_logic_vector(word_width-1 downto 0); --From pc, fetch stage

        is_interrupt_out : out std_logic; -- Pass through to other buffers
        next_instruction_address_out, data_word_out: out std_logic_vector(word_width-1 downto 0)
    ) ;
end FetchDecodeBuffer;

architecture fetch_decoder_buffer_arch of FetchDecodeBuffer is
    signal is_interrupt_s : std_logic;
    signal input_word_type_s : std_logic_vector(1 downto 0);
    signal current_instruction_address_s, next_instruction_address_s, data_word_s: std_logic_vector(word_width-1 downto 0);

begin
    Interrupt_Logic : process( clk_c )
    begin
        if (rising_edge(clk_c)) then
            is_interrupt_s <= not is_interrupt_in;
        end if;
    end process ; -- Interrupt_Logic

    Buffer_Logic : process( clk_c, reset_in )
    begin
        if (reset_in = '1') then 
            input_word_type_s <= (others => '0');
            current_instruction_address_s <= (others => '0');
            next_instruction_address_s <= (others => '0');
            data_word_s <= (others => '0');
        elsif (rising_edge(clk_c)) then
            if (enable_in = '1') then
                next_instruction_address_s <= next_instruction_address_in;
                data_word_s <= data_word_in;
            end if;
        end if;
    end process ; -- buffer_logic

    is_interrupt_out <= is_interrupt_s;
    next_instruction_address_out <= next_instruction_address_s;
    data_word_out <= data_word_s;
end fetch_decoder_buffer_arch ; -- fetch_decoder_buffer_arch