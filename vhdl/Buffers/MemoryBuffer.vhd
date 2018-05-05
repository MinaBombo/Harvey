library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity MemoryBuffer is
    port (
        clk_c, reset_in : in std_logic;
        --From Execute, Memory Buffer
        r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);
        r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
        is_return_in, is_interrupt_in, is_out_instruction_in : in std_logic;
        enable_writeback_in : in std_logic_vector(1 downto 0);

        --From memory Stage
        memory_data_in : in std_logic_vector(15 downto 0);
        memory_read_enable_in : in std_logic;
        memory_has_in : std_logic_vector(1 downto 0);

        r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0);
        r_src_address_out, r_dst_address_out : out std_logic_vector(2 downto 0);
        is_return_out, is_interrupt_out : out std_logic;
        enable_writeback_out : out std_logic_vector(1 downto 0); -- goes also to FU
        out_port_out : out std_logic_vector(15 downto 0);

        memory_has_out : out std_logic_vector(1 downto 0)
    ) ;
end MemoryBuffer;

architecture memory_buffer_arch of MemoryBuffer is

    signal r_src_data_s, r_dst_data_s : std_logic_vector(15 downto 0);
    signal r_src_address_s, r_dst_address_s : std_logic_vector(2 downto 0);
    signal is_return_s, is_interrupt_s : std_logic;
    signal enable_writeback_s, memory_has_s : std_logic_vector(1 downto 0);

begin
    
    Buffer_Logic : process( clk_c )
    begin
        if(reset_in = '1') then
        r_src_data_s <= (others => '0');
        r_dst_data_s <= (others => '0');
        r_src_address_s <= (others => '0');
        r_dst_address_s <= (others => '0');
        is_return_s <= '0';
        is_interrupt_s <='0';
        enable_writeback_s <= (others => '0');
        memory_has_s <= (others => '0');
        elsif(rising_edge(clk_c)) then
            r_src_data_s <= r_src_data_in;
            if(memory_read_enable_in = '1') then
                r_dst_data_s <=  memory_data_in;
            else r_dst_data_s <= r_dst_data_in;
            end if;
            r_src_address_s <= r_src_address_in;
            r_dst_address_s <= r_dst_address_in;
            is_return_s     <= is_return_in;
            is_interrupt_s  <= is_interrupt_in;
            enable_writeback_s <= enable_writeback_in;
            memory_has_s <= memory_has_in;
	    end if;
    end process ; -- Buffer_Logic

    r_src_data_out <= r_src_data_s;
    r_dst_data_out <= r_dst_data_s;
    out_port_out <= r_dst_data_s when is_out_instruction_in = '1';
    r_src_address_out <= r_src_address_s;
    r_dst_address_out <= r_dst_address_s;
    is_return_out <= is_return_s;
    is_interrupt_out <= is_interrupt_s;
    enable_writeback_out <= enable_writeback_s;
    memory_has_out <= memory_has_s;
end memory_buffer_arch ; -- memory_buffer_arch