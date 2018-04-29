library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity ForwardingUnit is
    port (
        clk_c, reset_in : in std_logic;

        will_change_in : in std_logic_vector(1 downto 0);      --This comes form the CU(enable_writeback_out), to tell me if this instruction will change anything
        decode_r_src_index_in : in std_logic_vector(2 downto 0);
        decode_r_dst_index_in : in std_logic_vector(2 downto 0);

        decode_needs_in : in std_logic_vector(1 downto 0);  -- From stage
        decode_needs_r_dst_index_in : in std_logic_vector(2 downto 0);

        execute_has_in : in std_logic_vector(1 downto 0); -- From buffer after
        execute_has_r_src_index_in : in std_logic_vector(2 downto 0);
        execute_has_r_dst_index_in : in std_logic_vector(2 downto 0);

        execute_needs_in : in std_logic_vector(1 downto 0);  -- From stage
        execute_needs_r_src_index_in : in std_logic_vector(2 downto 0);
        execute_needs_r_dst_index_in : in std_logic_vector(2 downto 0);

        memory_has_in : in std_logic_vector(1 downto 0);
        memory_has_r_src_index_in : in std_logic_vector(2 downto 0);
        memory_has_r_dst_index_in : in std_logic_vector(2 downto 0);

        memory_needs_in : in std_logic_vector(1 downto 0);
        memory_needs_r_src_index_in : in std_logic_vector(2 downto 0);

        stall_stage_index_out : out std_logic_vector(1 downto 0);

        decode_r_dst_selection_out : out std_logic_vector(1 downto 0);

        execute_r_src_selection_out : out std_logic_vector(1 downto 0);
        execute_r_dst_selection_out : out std_logic_vector(1 downto 0);

        --TODO Make sure there can be no stalls in anything forwarding to memrory
        memory_r_src_selection_out : out std_logic
    );
end ForwardingUnit;

architecture forwarding_unit_arch of ForwardingUnit is
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

    signal current_registers_change_status_s : std_logic_vector(5 downto 0);
    signal last_registers_change_status_s : std_logic_vector(5 downto 0);
    signal registers_change_status_register_enable_s : std_logic; 

    signal current_execution_has_status_s : std_logic_vector(5 downto 0);
    signal last_execution_has_status_s : std_logic_vector(5 downto 0);
    signal execution_has_status_register_enable_s : std_logic; 

    signal current_memory_has_status_s : std_logic_vector(5 downto 0);
    signal last_memory_has_status_s : std_logic_vector(5 downto 0);
    signal memory_has_status_register_enable_s : std_logic; 

    signal decode_availble_s, execute_available_s : std_logic;
   
    signal decode_needs_r_dst_index_s :integer;
    signal execute_needs_r_src_index_s, execute_needs_r_dst_index_s : integer;
    signal memory_needs_r_src_index_s : integer;

    signal decode_r_dst_selection_s : std_logic_vector(1 downto 0);
    signal execute_r_src_selection_s, execute_r_dst_selection_s : std_logic_vector(1 downto 0);
    signal memory_r_src_selection_s : std_logic;

begin
    
    registers_change_status_register_enable_s <= will_change_in(1) or will_change_in(0);
    current_registers_change_status_s(to_integer(unsigned(decode_r_src_index_in))) <= will_change_in(1); -- 1 when will_change_in = WILL_CHANGE_BOTH = "11"
    current_registers_change_status_s(to_integer(unsigned(decode_r_dst_index_in))) <= '1'; -- enable will be 0 if will_change = "00" otherwise will_change(dst) = '1'
    Registers_Change_Status_Register : nBitRegister generic map (n => 6) port map (
        clk_c => clk_c, enable_in => registers_change_status_register_enable_s, reset_in => reset_in, 
        data_in => current_registers_change_status_s, data_out => last_registers_change_status_s);

    execution_has_status_register_enable_s <= execute_has_in(1) or execute_has_in(0);
    current_execution_has_status_s(to_integer(unsigned(execute_has_r_src_index_in))) <= execute_has_in(1);
    current_execution_has_status_s(to_integer(unsigned(execute_has_r_dst_index_in))) <= '1';
    Execution_Has_Status_Register : nBitRegister generic map (n => 6) port map (
        clk_c => clk_c, enable_in => execution_has_status_register_enable_s, reset_in => reset_in, 
        data_in => current_execution_has_status_s, data_out => last_execution_has_status_s);

    memory_has_status_register_enable_s <= memory_has_in(1) or memory_has_in(0);
    current_memory_has_status_s(to_integer(unsigned(memory_has_r_src_index_in))) <= memory_has_in(1);
    current_memory_has_status_s(to_integer(unsigned(memory_has_r_dst_index_in))) <= '1';
    Memory_Has_Status_Register : nBitRegister generic map (n => 6) port map (
        clk_c => clk_c, enable_in => memory_has_status_register_enable_s, reset_in => reset_in, 
        data_in => current_memory_has_status_s, data_out => last_memory_has_status_s); 

    decode_needs_r_dst_index_s <= to_integer(unsigned(decode_needs_r_dst_index_in));

    decode_r_dst_selection_s <= DECODE_DST_NORMAL when decode_needs_in = NEEDS_NOTHING or 
    last_registers_change_status_s(decode_needs_r_dst_index_s) = '0' else DECODE_DST_EXECUTE when 
    last_execution_has_status_s(decode_needs_r_dst_index_s) = '1' else DECODE_DST_MEMORY when
    last_memory_has_status_s(decode_needs_r_dst_index_s) = '1' else NO_FORWARD_POSSIBLE;

    decode_availble_s <= '0' when decode_r_dst_selection_s = NO_FORWARD_POSSIBLE else '1';


    execute_needs_r_src_index_s <= to_integer(unsigned(execute_needs_r_src_index_in));

    execute_r_src_selection_s <= EXECUTE_SELECT_NORMAL when execute_needs_in = NEEDS_NOTHING or 
    execute_needs_in = NEED_DST or last_registers_change_status_s(execute_needs_r_src_index_s) = '0' else 
    EXECUTE_SELECT_SELF when last_execution_has_status_s(execute_needs_r_src_index_s) = '1' else 
    EXECUTE_SELECT_MEMORY when last_memory_has_status_s(execute_needs_r_src_index_s) = '1' else NO_FORWARD_POSSIBLE;


    execute_needs_r_dst_index_s <= to_integer(unsigned(execute_needs_r_dst_index_in));

    execute_r_dst_selection_s <= EXECUTE_SELECT_NORMAL when execute_needs_in = NEEDS_NOTHING or 
    execute_needs_in = NEED_SRC or last_registers_change_status_s(execute_needs_r_dst_index_s) = '0' else 
    EXECUTE_SELECT_SELF when last_execution_has_status_s(execute_needs_r_dst_index_s) = '1' else 
    EXECUTE_SELECT_MEMORY when last_memory_has_status_s(execute_needs_r_dst_index_s) = '1' else NO_FORWARD_POSSIBLE;

    execute_available_s <= '0' when execute_r_src_selection_s = NO_FORWARD_POSSIBLE or 
    execute_r_dst_selection_s = NO_FORWARD_POSSIBLE else '1';

    --Memory can only need src, can't need dst
    memory_needs_r_src_index_s <= to_integer(unsigned(memory_needs_r_src_index_in));

    memory_r_src_selection_s <=  MEMORY_SRC_NORMAL when memory_needs_in = NEEDS_NOTHING or
    last_registers_change_status_s(memory_needs_r_src_index_s) = '0' 
    or last_execution_has_status_s(memory_needs_r_src_index_s) = '1'  else
    MEMORY_SRC_SELF when last_memory_has_status_s(memory_needs_r_src_index_s) ='1';


    decode_r_dst_selection_out  <= decode_r_dst_selection_s;
    execute_r_src_selection_out <= execute_r_src_selection_s;
    execute_r_dst_selection_out <= execute_r_dst_selection_s;
    memory_r_src_selection_out  <= memory_r_src_selection_s;


    stall_stage_index_out <= STALL_EXECUTE when execute_available_s = '0' 
    else STALL_DECODE when decode_availble_s = '0' else NO_STALL;
    
end forwarding_unit_arch ; -- forwarding_unit_arch
