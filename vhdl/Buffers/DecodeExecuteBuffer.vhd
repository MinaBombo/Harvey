library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity DecodeExecuteBuffer is
    port (
        clk_c, reset_in ,enable_in : in std_logic;
        --From Decode stage
        immediate_data_in : in std_logic_vector(15 downto 0);
        r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
        r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);
        opcode_in : in std_logic_vector(4 downto 0);
        
        --From CU
        input_word_type_in : in std_logic_vector(1 downto 0);
        cu_is_interrupt_in : in std_logic;
        is_return_in : in std_logic; -- Pass through to MemoryBuffer to send it to the CU to reset return
        --Control Word
        enable_memory_in, memory_read_write_in : in std_logic;
        enable_writeback_in : in std_logic_vector(1 downto 0);

        --From last buffer directly
        last_buffer_is_interrupt_in : in std_logic;
        next_instruction_address_in : in std_logic_vector (15 downto 0);

        --From FU
        decode_has_in : in std_logic_vector(1 downto 0); 

        --Control Word
        enable_memory_out, memory_read_write_out : out std_logic;
        enable_writeback_out : out std_logic_vector(1 downto 0);

        is_interrupt_out,is_return_out : out std_logic; -- Goes to ExecuteMemoryBuffer
        decode_has_out : out std_logic_vector(1 downto 0); -- Goes to FU
        immediate_fetched_out : out std_logic; -- To stall unit, decodeStage
        input_word_type_out : out std_logic_vector(1 downto 0);

        r_src_address_out, r_dst_address_out : out std_logic_vector(2 downto 0);
        r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0);
        next_instruction_address_out : out std_logic_vector (15 downto 0);
        opcode_out : out std_logic_vector(4 downto 0)


    ) ;
end DecodeExecuteBuffer;

architecture decode_execute_buffer_arch of DecodeExecuteBuffer is
    signal enable_memory_s, memory_read_write_s : std_logic;
    signal enable_writeback_s : std_logic_vector(1 downto 0);

    signal input_word_type_s : std_logic_vector(1 downto 0);

    signal is_interrupt_s, is_return_s : std_logic; 
    signal decode_has_s : std_logic_vector(1 downto 0);
    signal immediate_fetched_s : std_logic;

    signal r_src_address_s, r_dst_address_s : std_logic_vector(2 downto 0);
    signal r_src_data_s, r_dst_data_s : std_logic_vector(15 downto 0);
    signal opcode_s : std_logic_vector(4 downto 0);
    signal next_instruction_address_s : std_logic_vector (15 downto 0);

begin
        Interrupt_Logic : process( clk_c )
        begin
            if (rising_edge(clk_c)) then
                is_interrupt_s <= cu_is_interrupt_in and last_buffer_is_interrupt_in;
            end if;
        end process ; -- Interrupt_Logic

        Buffer_Logic : process( clk_c,reset_in )
        begin
            if (reset_in = '1') then 
                enable_memory_s <= '0';
                memory_read_write_s <= '0';
                enable_writeback_s <= (others => '0');
                input_word_type_s <= (others => '0');
                decode_has_s <= (others => '0');
                opcode_s <= (others => '0');
                next_instruction_address_s <= (others => '0');
                is_return_s <= '0';
                immediate_fetched_s <= FETCHED;
            elsif (rising_edge(clk_c)) then
                if (enable_in = '1')then
                    if(input_word_type_in /= WORD_TYPE_INSTRUCTION or immediate_fetched_s = NOT_FETCHED) then
                        immediate_fetched_s <= not immediate_fetched_s;
                    end if;
                    if(immediate_fetched_s = FETCHED) then
                        enable_memory_s <= enable_memory_in;
                        memory_read_write_s <= memory_read_write_in;
                        enable_writeback_s <= enable_writeback_in;
                        r_src_address_s <= r_src_address_in;
                        r_dst_address_s <= r_dst_address_in;
                        is_return_s <= is_return_in;
                        decode_has_s <= decode_has_in;
                        next_instruction_address_s <= next_instruction_address_in;
                        opcode_s <= opcode_in;  
                        r_src_data_s <= r_src_data_in;
                        r_dst_data_s <= r_dst_data_in; 
                    else 
                        r_dst_data_s <= immediate_data_in;         
                    end if;
                    input_word_type_s <= input_word_type_in;
                end if;
            end if;
        end process ; -- buffer_logic

        enable_memory_out <= enable_memory_s;
        memory_read_write_out <= memory_read_write_s;
        enable_writeback_out <= enable_writeback_s;
        input_word_type_out <= input_word_type_s;
        is_return_out <= is_return_s;
        decode_has_out <= decode_has_s;
        r_src_address_out <= r_src_address_s;
        r_dst_address_out <= r_dst_address_s;
        r_src_data_out <= r_src_data_s;
        r_dst_data_out <= r_dst_data_s;
        is_interrupt_out <= is_interrupt_s;
        immediate_fetched_out <= immediate_fetched_s;
        next_instruction_address_out <= next_instruction_address_s;
        opcode_out <= opcode_s;
        
end decode_execute_buffer_arch ; -- decode_execute_buffer_arch