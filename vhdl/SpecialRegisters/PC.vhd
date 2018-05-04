library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity PC is
    port (
        clk_c, reset_in : in std_logic;

        execute_is_jump_taken_in, decode_is_call_in : in std_logic;
        memory_is_return_in, memory_is_interrupt_in, su_enable_pc_inc_in, decode_is_interrupt_in : in std_logic;
        
        starting_address_in, execute_jump_address_in : in std_logic_vector(15 downto 0);
        decode_call_address_in, memory_return_address_in, interupt_address_in : in std_logic_vector(15 downto 0);
        
        address_out : out std_logic_vector(15 downto 0)
    );
end PC;

architecture pc_arch of PC is
    component nBitsCounter is
        generic (
            n : integer
        );
        port (
            clk_c, count_enable_in, count_direction_in, load_enable_in : in std_logic;
            parallel_load_in : in std_logic_vector(n-1 downto 0);
    
            data_out : out std_logic_vector(n-1 downto 0)
        );
    end component;
    
    signal load_enable_s : std_logic;
    signal parallel_load_s : std_logic_vector(15 downto 0);
    signal address_s : std_logic_vector(15 downto 0);
    signal decode_is_interrupt_latched_s : std_logic;
begin

    load_enable_s <= reset_in or execute_is_jump_taken_in or decode_is_call_in or memory_is_return_in or memory_is_interrupt_in 
    or (decode_is_interrupt_in and not decode_is_interrupt_latched_s);

    Decode_Is_Interrupt_latch : process(clk_c,decode_is_interrupt_in)
    begin
        if(rising_edge(clk_c)) then
            decode_is_interrupt_latched_s <= decode_is_interrupt_in;
        end if;
    end process ; -- Decode_Is_Interrupt_latch
    parallel_load_s <= starting_address_in when reset_in ='1'
    else execute_jump_address_in when execute_is_jump_taken_in = '1'
    else decode_call_address_in when decode_is_call_in ='1'
    else memory_return_address_in when memory_is_return_in ='1'
    else interupt_address_in when memory_is_interrupt_in = '1'
    else std_logic_vector(unsigned(address_s) - 1) when decode_is_interrupt_in = '1' and decode_is_interrupt_latched_s<='0'
    else (others => '0');

    Inner_Counter : nBitsCounter generic map ( n => 16) port map (
        clk_c => clk_c, count_enable_in => su_enable_pc_inc_in, count_direction_in => COUNT_UP, load_enable_in => load_enable_s,
        parallel_load_in => parallel_load_s,
        data_out => address_s
    );
    address_out <= address_s;

end pc_arch ; -- pc_arch