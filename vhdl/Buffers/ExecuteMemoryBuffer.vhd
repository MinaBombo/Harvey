library ieee;
use ieee.std_logic_1164.all;

entity ExecuteMemoryBuffer is
    port (
        clk_c, reset_in ,enable_in : in std_logic;

        --From Execute Stage
        memory_address_in, memory_input_in : in std_logic_vector(15 downto 0);
        memory_needs_src_in : in std_logic;
        memory_is_return_interrupt_in : in std_logic;
        r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);
        execute_has_in : in std_logic_vector(1 downto 0);

        --From Decode Execute buffer
        r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
        last_buffer_is_interrupt_in : in std_logic;
        is_return_in : in std_logic;

        --From CU
        cu_is_interrupt_in : in std_logic;

        --Control Word
        enable_memory_in, memory_read_write_in : in std_logic;
        enable_writeback_in : in std_logic_vector(1 downto 0);

        memory_address_out, memory_input_out : out std_logic_vector(15 downto 0);
        memory_needs_src_out : out std_logic; -- To FU
        memory_is_return_interrupt_out : out std_logic; -- Back to EU
        r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0);
        r_src_address_out, r_dst_address_out : out std_logic_vector(2 downto 0);
        is_interrupt_out : out std_logic;
        execute_has_out :  out std_logic_vector(1 downto 0); -- GOES TO FU
        enable_memory_out ,memory_read_write_out : out std_logic;
        enable_writeback_out : out std_logic_vector(1 downto 0);
        is_return_out : out std_logic -- Goes to Memory buffer
    ) ;
end ExecuteMemoryBuffer;

architecture execute_memory_buffer_arch of ExecuteMemoryBuffer is

    signal memory_address_s, memory_input_s : std_logic_vector(15 downto 0);
    signal memory_needs_src_s : std_logic;
    signal memory_is_return_interrupt_s : std_logic;
    signal r_src_data_s, r_dst_data_s : std_logic_vector(15 downto 0);
    signal execute_has_s : std_logic_vector(1 downto 0);

    signal is_return_s : std_logic;
    signal r_src_address_s, r_dst_address_s : std_logic_vector(2 downto 0);

    signal is_interrupt_s : std_logic;

    signal enable_memory_s, memory_read_write_s : std_logic;
    signal enable_writeback_s : std_logic_vector(1 downto 0);

begin
    Interrupt_Logic : process( clk_c )
    begin
        if (rising_edge(clk_c)) then
            is_interrupt_s <= cu_is_interrupt_in and last_buffer_is_interrupt_in;
        end if;
    end process ; -- Interrupt_Logic

    Buffer_Logic : process( clk_c, reset_in )
    begin
        if (reset_in = '1') then 
            memory_address_s             <=  (others => '0');
            memory_input_s               <=  (others => '0');
            memory_needs_src_s           <=  '0';
            memory_is_return_interrupt_s <=  '0';
            r_src_data_s                 <=   (others => '0');
            r_dst_data_s                 <=   (others => '0');
            execute_has_s                <=   (others => '0');
            r_src_address_s              <=   (others => '0');
            r_dst_address_s              <=   (others => '0');
            enable_memory_s              <=   '0';
            memory_read_write_s          <=   '0';
            enable_writeback_s           <=   (others => '0');
        elsif (rising_edge(clk_c)) then
            if (enable_in = '1') then
                memory_address_s <= memory_address_in;
                memory_input_s <= memory_input_in;
                memory_needs_src_s <= memory_needs_src_in;
                memory_is_return_interrupt_s <= memory_is_return_interrupt_in;
                r_src_data_s <= r_src_data_in ;
                r_dst_data_s <= r_dst_data_in;
                execute_has_s <= execute_has_in;
                r_src_address_s <= r_src_address_in;
                r_dst_address_s <= r_dst_address_in;
                enable_memory_s <= enable_memory_in;
                memory_read_write_s <= memory_read_write_in;
                enable_writeback_s <= enable_writeback_in;
            end if;
        end if;
    end process ; -- buffer_logic
    
    memory_address_out <= memory_address_s;
    memory_input_out <= memory_input_s;
    memory_needs_src_out <= memory_needs_src_s;
    memory_is_return_interrupt_out <= memory_is_return_interrupt_s;
    r_src_data_out <= r_src_data_s;
    r_dst_data_out <= r_dst_data_s;
    r_src_address_out <= r_src_address_s;
    r_dst_address_out <= r_dst_address_in;
    execute_has_out <= execute_has_in;
    is_interrupt_out <= is_interrupt_s;
    enable_memory_out <= enable_memory_s;
    memory_read_write_out <= memory_read_write_s;
    enable_writeback_out <= enable_writeback_s;
    is_return_out <= is_return_s;
end execute_memory_buffer_arch ; -- decode_execute_buffer_arch