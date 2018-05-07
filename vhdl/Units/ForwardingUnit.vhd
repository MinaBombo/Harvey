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

        decode_needs_in : in std_logic;  -- From CU
        decode_needs_r_dst_index_in : in std_logic_vector(2 downto 0);

        decode_has_in : in std_logic_vector(1 downto 0);        --Used in EU needs
        
        execute_has_in : in std_logic_vector(1 downto 0); -- From buffer after
        execute_has_r_src_index_in : in std_logic_vector(2 downto 0);
        execute_has_r_dst_index_in : in std_logic_vector(2 downto 0);

        execute_needs_in : in std_logic_vector(1 downto 0);  -- From stage
        execute_needs_r_src_index_in : in std_logic_vector(2 downto 0);
        execute_needs_r_dst_index_in : in std_logic_vector(2 downto 0);

        memory_has_in : in std_logic_vector(1 downto 0);
        memory_has_r_src_index_in : in std_logic_vector(2 downto 0);
        memory_has_r_dst_index_in : in std_logic_vector(2 downto 0);

        memory_needs_in : in std_logic;
        memory_needs_r_src_index_in : in std_logic_vector(2 downto 0);
        immediate_fetched_in : in std_logic; -- From DecodeExecuteBuffer, It has no use now, remove it when you are sure

        stall_stage_index_out : out std_logic_vector(1 downto 0);

        decode_r_dst_selection_out : out std_logic_vector(1 downto 0);

        execute_r_src_selection_out : out std_logic_vector(1 downto 0);
        execute_r_src_selection_from_r_src : out std_logic;
        execute_r_dst_selection_out : out std_logic_vector(1 downto 0);
        execute_r_dst_selection_from_r_dst : out std_logic;

        --TODO Make sure there can be no stalls in anything forwarding to memrory
        memory_r_src_selection_out : out std_logic;
        decode_has_out : out std_logic_vector(1 downto 0);       --To tell the decode what it has

        write_back_has_written_src_index_in,write_back_has_written_dst_index_in : in std_logic_vector(2 downto 0);
        write_back_select_in : in std_logic_vector(1 downto 0)

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

    component nBitsDecoder is
        generic (
            n : integer
        );
        port (
            enable_in : in std_logic;
            selection_in : in std_logic_vector(n-1 downto 0);
    
            data_out : out std_logic_vector((2**n)-1 downto 0)
        );
    end component;

    signal current_registers_change_status_s : std_logic_vector(7 downto 0);
    signal last_registers_change_status_s : std_logic_vector(7 downto 0);
    signal registers_change_status_register_enable_s : std_logic; 

    signal current_execution_src_status_s, current_execution_dst_status_s : std_logic;
    signal execution_src_status_decoder_s, execution_dst_status_decoder_s : std_logic_vector(7 downto 0);
    signal current_execution_has_status_s : std_logic_vector(5 downto 0);
    
    signal current_memory_src_status_s, current_memory_dst_status_s : std_logic;
    signal memory_src_status_decoder_s, memory_dst_status_decoder_s : std_logic_vector(7 downto 0);
    signal current_memory_has_status_s : std_logic_vector(5 downto 0);

    signal decode_availble_s, execute_available_s : std_logic;
   
    signal decode_needs_r_dst_index_s :integer := 0;
    signal execute_needs_r_src_index_s, execute_needs_r_dst_index_s : integer:= 0;
    signal memory_needs_r_src_index_s : integer:= 0;
    signal decode_r_src_index_s,decode_r_dst_index_s : integer := 0;
    signal write_back_has_written_src_index_s,write_back_has_written_dst_index_s : integer:= 0;
    signal decode_r_dst_selection_s : std_logic_vector(1 downto 0);
    signal execute_r_src_selection_s, execute_r_dst_selection_s : std_logic_vector(1 downto 0);
    signal memory_r_src_selection_s : std_logic;
    signal current_decode_r_src_status_s, current_decode_r_dst_status_s, current_write_back_r_src_status_s,current_write_back_r_dst_status_s : std_logic_vector(7 downto 0) := (Others => '0');  
    signal current_decode_r_src_status_decoder_enable_s : std_logic;
    signal current_decode_r_dst_status_decoder_enable_s : std_logic;
    signal current_write_back_r_src_status_decoder_enable_s : std_logic;
    signal current_write_back_r_dst_status_decoder_enable_s : std_logic;

begin
    
    decode_r_src_index_s <= to_integer(unsigned(decode_r_src_index_in));
    decode_r_dst_index_s <= to_integer(unsigned(decode_r_dst_index_in));
    write_back_has_written_src_index_s <= to_integer(unsigned(write_back_has_written_src_index_in));
    write_back_has_written_dst_index_s <= to_integer(unsigned(write_back_has_written_dst_index_in));

    registers_change_status_register_enable_s <= '1' when  (will_change_in /= WILL_CHANGE_NOTHING or write_back_select_in /= WILL_CHANGE_NOTHING);

    current_decode_r_src_status_decoder_enable_s <= '0' when reset_in = '1' else  '1' when will_change_in = WILL_CHANGE_BOTH else '0' ; 
    current_decode_r_dst_status_decoder_enable_s<=  '0' when reset_in = '1' else  '1' when will_change_in /= WILL_CHANGE_NOTHING else '0';

    Decode_Src_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_decode_r_src_status_decoder_enable_s, selection_in => decode_r_src_index_in,
        data_out => current_decode_r_src_status_s
    );

    Decode_Dst_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_decode_r_dst_status_decoder_enable_s, selection_in => decode_r_dst_index_in,
        data_out => current_decode_r_dst_status_s
    );

    current_write_back_r_src_status_decoder_enable_s <= 
             '0' when reset_in = '1' 
        else '1' when (decode_r_src_index_s /= write_back_has_written_src_index_s and  write_back_select_in = WILL_CHANGE_BOTH) 
                   or (decode_r_src_index_s = write_back_has_written_src_index_s and  ((will_change_in = WILL_CHANGE_NOTHING or will_change_in = WILL_CHANGE_DST) and  (write_back_select_in = WILL_CHANGE_BOTH))) 
        else '0';

        current_write_back_r_dst_status_decoder_enable_s <=
             '0' when reset_in = '1'
        else '1' when (decode_r_dst_index_s /= write_back_has_written_dst_index_s and write_back_select_in /= WILL_CHANGE_NOTHING) 
                   or (decode_r_dst_index_s = write_back_has_written_dst_index_s  and will_change_in = WILL_CHANGE_NOTHING and write_back_select_in /= WILL_CHANGE_NOTHING)
        else '0';
    Write_Back_Src_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_decode_r_dst_status_decoder_enable_s, selection_in => write_back_has_written_src_index_in,
        data_out => current_write_back_r_src_status_s
    );
    Write_Back_Dst_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_decode_r_dst_status_decoder_enable_s, selection_in => write_back_has_written_dst_index_in,
        data_out => current_write_back_r_dst_status_s
    );

    current_registers_change_status_s <= (current_decode_r_src_status_s or current_decode_r_dst_status_s) and not (current_write_back_r_src_status_s or current_write_back_r_dst_status_s);
    Registers_Change_Status_Register : nBitRegister generic map (n => 8) port map (
        clk_c => clk_c, enable_in => registers_change_status_register_enable_s, reset_in => reset_in, 
        data_in => current_registers_change_status_s, data_out => last_registers_change_status_s);

    current_execution_src_status_s <= '1' when execute_has_in = HAS_ALL else '0';
    current_execution_dst_status_s <= '1' when execute_has_in /= HAS_NONE else '0';
    Execution_Src_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_execution_src_status_s, selection_in => execute_has_r_src_index_in,
        data_out => execution_src_status_decoder_s
    );
    Execution_Dst_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_execution_dst_status_s, selection_in => execute_has_r_dst_index_in,
        data_out => execution_dst_status_decoder_s
    );
    current_execution_has_status_s <= execution_src_status_decoder_s(5 downto 0) or execution_dst_status_decoder_s(5 downto 0);


    current_memory_src_status_s <= '1' when memory_has_in = HAS_ALL else '0';
    current_memory_dst_status_s <= '1' when memory_has_in /= HAS_NONE else '0';
    Memory_Src_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_memory_src_status_s, selection_in => memory_has_r_src_index_in,
        data_out => memory_src_status_decoder_s
    );
    Memory_Dst_Status_Decoder : nBitsDecoder generic map (n => 3) port map (
        enable_in => current_memory_dst_status_s, selection_in => memory_has_r_dst_index_in,
        data_out => memory_dst_status_decoder_s
    );
    current_memory_has_status_s <= memory_src_status_decoder_s(5 downto 0) or memory_dst_status_decoder_s(5 downto 0);

    decode_needs_r_dst_index_s <= to_integer(unsigned(decode_needs_r_dst_index_in));

    decode_r_dst_selection_s <= DECODE_DST_NORMAL when decode_needs_in = '0' or 
    last_registers_change_status_s(decode_needs_r_dst_index_s) = '0' else DECODE_DST_EXECUTE when 
    current_execution_has_status_s(decode_needs_r_dst_index_s) = '1' else DECODE_DST_MEMORY when
    current_memory_has_status_s(decode_needs_r_dst_index_s) = '1' else NO_FORWARD_POSSIBLE;

    decode_availble_s <= '0' when decode_r_dst_selection_s = NO_FORWARD_POSSIBLE else '1';


    execute_needs_r_src_index_s <= to_integer(unsigned(execute_needs_r_src_index_in));

    execute_r_src_selection_s <= 
    EXECUTE_SELECT_NORMAL when execute_needs_in = NEEDS_NOTHING else
    EXECUTE_SELECT_SELF when current_execution_has_status_s(execute_needs_r_src_index_s) = '1' 
    else EXECUTE_SELECT_MEMORY when current_memory_has_status_s(execute_needs_r_src_index_s) = '1' 
    else EXECUTE_SELECT_NORMAL when execute_needs_in = NEED_DST 
    or last_registers_change_status_s(execute_needs_r_src_index_s) = '0' or decode_has_in = HAS_ALL 
    else NO_FORWARD_POSSIBLE;
    
    execute_r_src_selection_from_r_src <= 
    '1' 
    when execute_r_src_selection_s = EXECUTE_SELECT_NORMAL 
    or (execute_r_src_selection_s = EXECUTE_SELECT_SELF and(execute_has_in = HAS_SRC or (execute_has_in = HAS_ALL and execute_has_r_src_index_in = execute_needs_r_src_index_in))) 
    or (execute_r_src_selection_s = EXECUTE_SELECT_MEMORY and memory_has_in = HAS_ALL and memory_has_r_src_index_in = execute_needs_r_src_index_in)
    else '0' 
    when (execute_r_src_selection_s = EXECUTE_SELECT_SELF and (execute_has_in = HAS_DST or (execute_has_in = HAS_ALL and execute_has_r_dst_index_in = execute_needs_r_src_index_in)))
    or(execute_r_src_selection_s = EXECUTE_SELECT_MEMORY and (memory_has_in = HAS_DST or (memory_has_in = HAS_ALL and memory_has_r_dst_index_in = execute_needs_r_src_index_in)))
    else 'Z';


    execute_needs_r_dst_index_s <= to_integer(unsigned(execute_needs_r_dst_index_in));

    execute_r_dst_selection_s <= 
    EXECUTE_SELECT_NORMAL when execute_needs_in = NEEDS_NOTHING else
    EXECUTE_SELECT_SELF when current_execution_has_status_s(execute_needs_r_dst_index_s) = '1' 
    else EXECUTE_SELECT_MEMORY when current_memory_has_status_s(execute_needs_r_dst_index_s) = '1'
    else EXECUTE_SELECT_NORMAL when execute_needs_in = NEED_SRC or 
    last_registers_change_status_s(execute_needs_r_dst_index_s) = '0' or decode_has_in = HAS_DST 
    or decode_has_in = HAS_ALL 
    else NO_FORWARD_POSSIBLE;

    execute_r_dst_selection_from_r_dst <= 
    '1' 
    when execute_r_dst_selection_s = EXECUTE_SELECT_NORMAL 
    or (execute_r_dst_selection_s = EXECUTE_SELECT_SELF and (execute_has_in = HAS_DST or (execute_has_in = HAS_ALL and execute_has_r_dst_index_in = execute_needs_r_dst_index_in)))
    or (execute_r_dst_selection_s = EXECUTE_SELECT_MEMORY and (memory_has_in = HAS_DST or (memory_has_in = HAS_ALL and memory_has_r_dst_index_in = execute_needs_r_dst_index_in)))
    else '0' 
    when (execute_r_dst_selection_s = EXECUTE_SELECT_SELF and (execute_has_in = HAS_SRC or (execute_has_in = HAS_ALL and execute_has_r_src_index_in = execute_needs_r_dst_index_in)))
    or   (execute_r_dst_selection_s = EXECUTE_SELECT_MEMORY and memory_has_in = HAS_ALL and memory_has_r_src_index_in = execute_needs_r_dst_index_in)
    else 'Z';

    execute_available_s <= '0' when execute_r_src_selection_s = NO_FORWARD_POSSIBLE or 
    execute_r_dst_selection_s = NO_FORWARD_POSSIBLE  else '1';

    --Memory can only need src, can't need dst
    memory_needs_r_src_index_s <= to_integer(unsigned(memory_needs_r_src_index_in));

    memory_r_src_selection_s <=
    MEMORY_SRC_SELF when current_memory_has_status_s(memory_needs_r_src_index_s) ='1'else MEMORY_SRC_NORMAL;
    

    decode_has_out <= 
    HAS_NONE when last_registers_change_status_s(decode_r_src_index_s) = '1' and last_registers_change_status_s(decode_r_dst_index_s) = '1' 
    else HAS_SRC when last_registers_change_status_s(decode_r_dst_index_s) = '1' 
    else HAS_DST when last_registers_change_status_s(decode_r_src_index_s) = '1' 
    else HAS_ALL;


    decode_r_dst_selection_out  <= decode_r_dst_selection_s;
    execute_r_src_selection_out <= execute_r_src_selection_s;
    execute_r_dst_selection_out <= execute_r_dst_selection_s;
    memory_r_src_selection_out  <= memory_r_src_selection_s;

    stall_stage_index_out <= FU_STALL_EXECUTE when execute_available_s = '0' 
    else STALL_DECODE when decode_availble_s = '0' else NO_STALL;
    
end forwarding_unit_arch ; -- forwarding_unit_arch

