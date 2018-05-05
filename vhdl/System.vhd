library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity System is
  port (
    clk_c, reset_in, interrupt_in : in std_logic;
    in_port_in : in  std_logic_vector (15 downto 0);
    out_port_out : out std_logic_vector(15 downto 0)
  ) ;
end System;

architecture system_arch of System is

    component PC is
        port (
            clk_c, reset_in : in std_logic;

            execute_is_jump_taken_in, decode_is_call_in : in std_logic;
            memory_is_return_in, memory_is_interrupt_in, su_enable_pc_inc_in, decode_is_interrupt_in : in std_logic;
            
            starting_address_in, execute_jump_address_in : in std_logic_vector(15 downto 0);
            decode_call_address_in, memory_return_address_in, interupt_address_in : in std_logic_vector(15 downto 0);
            
            address_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component FetchStage is
        generic (
            word_width : integer := 16;
            cache_size : integer := 512
        );
        port (
            clk_c : in std_logic;
            current_instruction_address_in : in std_logic_vector(word_width-1 downto 0);
            
            data_word_out : out std_logic_vector(word_width-1 downto 0)
        ) ;
    end component; 

    component FetchDecodeBuffer is
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
    end component;

    component DecodeStage is
        port (
            clk_c, reset_in : in std_logic;
    
            instruction_in : in std_logic_vector(15 downto 0);
    
            -- From writeback
            r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
            enable_writeback_in : in std_logic_vector(1 downto 0);
            r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);
            immediate_fetched_in : in std_logic; -- From Buffer After me
            
            r_dst_from_execute_in, r_dst_from_memory_in : in std_logic_vector(15 downto 0);
            call_pc_address_select_in : in std_logic_vector(1 downto 0);
            opcode_out : out  std_logic_vector(4 downto 0);
            r_src_address_out, r_dst_address_out : out std_logic_vector(2 downto 0);
            r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0);
            immediate_data_out: out std_logic_vector(15 downto 0);
            pc_address_out : out  std_logic_vector(15 downto 0)
        ) ;
    end component;

    component DecodeExecuteBuffer is
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
    end component;

    component ExecuteStage is
        port (
            clk_c, reset_in, enable_in : in std_logic;

            opcode_in : in std_logic_vector(4 downto 0);
            pc_address_in, in_port_data_in : in std_logic_vector(15 downto 0);
            is_interrupt_in : in std_logic; --From DecodeExecuteBuffer
            next_instruction_address_in : in std_logic_vector(15 downto 0); -- From FetchDecode Buffer

            r_src_data_from_decode_in, r_dst_data_from_decode_in : in std_logic_vector(15 downto 0);
            r_src_data_from_execute_in, r_dst_data_from_execute_in : in std_logic_vector(15 downto 0);
            r_src_data_from_memory_in, r_dst_data_from_memory_in : in std_logic_vector(15 downto 0);
            execute_r_src_selection_in, execute_r_dst_selection_in: in std_logic_vector(1 downto 0);
            memory_is_return_interrupt_in : in std_logic; -- from memory
            flags_in : in std_logic_vector(3 downto 0); --From memory
            select_r_src_from_r_src, select_r_dst_from_r_dst : in std_logic;

            memory_address_out, memory_input_out : out std_logic_vector(15 downto 0); -- for memory stage
            memory_needs_src_out : out std_logic;
            memory_has_out: out std_logic_vector(1 downto 0);
            memory_is_return_interrupt_out : out std_logic;
            r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0); -- for write back stage
            execute_needs_out, execute_has_out : out std_logic_vector(1 downto 0);  -- for FU

            is_jump_taken_out, is_out_instruction_out : out std_logic;
            pc_address_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component ExecuteMemoryBuffer is
        port (
            clk_c, reset_in ,enable_in : in std_logic;

            --From Execute Stage
            memory_address_in, memory_input_in : in std_logic_vector(15 downto 0);
            memory_needs_src_in : in std_logic;
            memory_has_in : in std_logic_vector (1 downto 0);
            memory_is_return_interrupt_in : in std_logic;
            r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);
            execute_has_in : in std_logic_vector(1 downto 0);

            --From Decode Execute buffer
            r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
            last_buffer_is_interrupt_in : in std_logic;
            is_return_in : in std_logic;
            is_out_instruction_in : in std_logic;

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
            is_return_out : out std_logic; -- Goes to Memory buffer
            is_out_instruction_out : out std_logic;
            memory_has_out : out std_logic_vector (1 downto 0)
        ) ;
    end component;

    component MemoryStage is
        port (
            clk_c, enable_in, memory_read_write_in : in std_logic;
             -- enable_in : write to cache and saving to buffer
    
            -- this is saved in the buffer by the EU, then the buffer sends it to the EU
           is_return_interrupt_in : in std_logic;
    
            --Memory buffer must output memory_needs
            memory_data_src_selection_in : in std_logic; -- From FU
            memry_address_in, data_from_execute_in, data_from_memory_in: in std_logic_vector(15 downto 0);
    
            memory_data_out, pc_address_out : out std_logic_vector(15 downto 0); -- will be put in r_dst
            flags_out : out std_logic_vector(3 downto 0);
            memory_read_out: out std_logic;
            pc_starting_address_out, pc_interrupt_address_out : out  std_logic_vector(15 downto 0)
        ) ;
    end component;

    component MemoryBuffer is
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
    end component;

    component ControlUnit is
        port (
            interrupt_in : in std_logic; -- From input
            opcode_in : in std_logic_vector(4 downto 0); -- From decode stage
            interrupt_reset_in : in std_logic; --Comes from memory buffer
            jump_taken_in : in std_logic; --From execute Stage
            return_reset_in : in std_logic; -- From MemoryStageBuffer
    
            is_interrupt_out : out std_logic; -- Goes to fetchDecodeBuffer
            is_return_out : out std_logic; -- Goes to DecodeExecute buffer
    
            enable_memory_out, memory_read_write_out : out std_logic; -- Goes to memoryStage
            enable_writeback_out, input_word_type_out : out std_logic_vector(1 downto 0); -- Goes to memory WriteBack Buffer, fetchDecodeBuffer
    
            stall_index_out :  out std_logic_vector(1 downto 0); -- Goes to Stall unit
    
            decode_needs_out : out std_logic -- Goes to Stall Unit
        );
    end component;
    component ForwardingUnit is
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
    end component;
    component StallingUnit is
        port (
            cu_stall_stage_index_in, fu_stall_stage_index_in : in std_logic_vector(1 downto 0);
            global_reset_in : in std_logic;
            immediate_fetched_in : in std_logic;
            enable_pc_inc_out : out std_logic;
            enable_fetch_decode_buffer_out, reset_fetch_decode_buffer_out : out std_logic;
            enable_decode_execute_buffer_out, reset_decode_execute_buffer_out : out std_logic;
            enable_execute_stage : out std_logic; --Flags and jumps
            reset_execute_memory_buffer_out : out std_logic -- Will never keep value of execute
        );
    end component;

    signal execute_pc_is_jump_taken, decode_pc_is_call : std_logic;
    signal memory_pc_is_return, memory_pc_cu_is_interrupt, decode_pc_is_interrupt : std_logic; --is interrupt and is return coming form the memory are resets to the CU
    signal su_pc_enable_pc_increment : std_logic;
    signal memory_pc_start_address, memory_pc_interrupt_address, memory_pc_return_adress, decode_pc_call_address, execute_pc_jmp_address, current_pc_address : std_logic_vector(15 downto 0);
    signal fetch_fetch_decode_buffer_data :  std_logic_vector(15 downto 0);
    signal su_fetch_decode_buffer_enable, su_fetch_decode_buffer_reset : std_logic;
    signal cu_buffers_is_interrupt,fetch_decode_next_buffer_is_interrupt : std_logic;
    signal fetch_decode_next_buffers_pc : std_logic_vector(15 downto 0);
    signal fetch_buffer_decode_data_word : std_logic_vector(15 downto 0);
    signal memory_buffer_r_src_address, memory_buffer_r_dst_address : std_logic_vector (2 downto 0);
    signal memory_buffer_enable_write_back : std_logic_vector(1 downto 0);
    signal memory_buffer_r_src, memory_buffer_r_dst : std_logic_vector(15 downto 0);
    signal decode_execute_buffer_immediate_fetched : std_logic;
    signal execute_memory_buffer_r_dst_data, execute_memory_buffer_r_src_data: std_logic_vector(15 downto 0);
    signal fu_decode_r_dst_select : std_logic_vector(1 downto 0);
    signal decode_next_buffer_op_code : std_logic_vector(4 downto 0);
    signal decode_next_buffer_r_src_address, decode_next_buffer_r_dst_address :  std_logic_vector(2 downto 0);
    signal decode_next_buffer_r_src_data, decode_next_buffer_r_dst_data : std_logic_vector(15 downto 0);
    signal decode_next_buffer_immediate : std_logic_vector(15 downto 0);
    signal su_decode_execute_buffer_reset, su_decode_execute_buffer_enable : std_logic;
    signal cu_decode_buffer_input_word_type :std_logic_vector(1 downto 0); 
    signal cu_is_return : std_logic;
    signal cu_enable_memory, cu_memory_read_write : std_logic;
    signal cu_enable_write_back : std_logic_vector(1 downto 0);
    signal decode_execute_buffer_fu_decode_has, fu_decode_execute_buffer_decode_has : std_logic_vector(1 downto 0); 
    signal decode_execute_buffer_next_enable_memory, decode_execute_buffer_next_memory_read_write_out : std_logic;
    signal decode_execute_buffer_next_enable_writeback : std_logic_vector(1 downto 0);
    signal decode_execute_buffer_next_is_interrupt, decode_execute_buffer_next_is_return : std_logic;
    signal decode_execute_buffer_next_input_word_type : std_logic_vector(1 downto 0);
    signal decode_execute_buffer_next_r_src_address, decode_execute_buffer_next_r_dst_address : std_logic_vector(2 downto 0);
    signal decode_execute_buffer_next_r_src_data, decode_execute_buffer_next_r_dst_data : std_logic_vector(15 downto 0);
    signal decode_execute_buffer_next_op_code : std_logic_vector(4 downto 0);
    signal decode_execute_buffer_next_instruction_address : std_logic_vector (15 downto 0);
    signal su_enable_execute_stage : std_logic;
    signal execute_next_buffer_r_src_data, execute_next_buffer_r_dst_data : std_logic_vector(15 downto 0);
    signal fu_execute_r_src_selection, fu_execute_r_dst_selection : std_logic_vector (1 downto 0);
    signal memory_eu_is_interrupt_return : std_logic; 
    signal memory_eu_flags : std_logic_vector(3 downto 0);
    signal eu_next_buffer_memory_address , eu_next_buffer_memory_input : std_logic_vector(15 downto 0);
    signal eu_next_buffer_memory_needs_src,eu_next_buffer_memory_is_return_interrupt : std_logic;
    signal eu_fu_execute_needs, eu_next_buffer_execute_has : std_logic_vector(1 downto 0);
    signal eu_next_buffer_is_out_instruction : std_logic; -- Know if this is actually used
    signal su_execute_memory_buffer_reset : std_logic;
    signal execute_memory_buffer_next_memory_address , execute_memory_buffer_next_memory_input : std_logic_vector(15 downto 0);
    signal execute_memory_buffer_fu_memory_needs_src : std_logic;
    signal execute_memory_buffer_next_r_src_address, execute_memory_buffer_next_r_dst_address : std_logic_vector(2 downto 0);
    signal execute_memory_buffer_next_is_interrupt : std_logic;
    signal execute_memory_buffer_fu_execute_has : std_logic_vector(1 downto 0);
    signal execute_memory_buffer_next_enable_memory , execute_memory_buffer_next_memory_read_write : std_logic;
    signal execute_memory_buffer_enable_write_back : std_logic_vector(1 downto 0);
    signal fu_memory_src_selection : std_logic;
    signal memory_next_buffer_memory_data : std_logic_vector(15 downto 0);
    signal memory_next_buffer_memory_read_enable : std_logic;
    signal memory_cu_is_return, memory_cu_is_interrupt : std_logic;
    signal memory_fu_memory_has : std_logic_vector (1 downto 0);
    signal cu_su_stall_index,fu_su_stall_index : std_logic_vector(1 downto 0);
    signal cu_fu_decode_needs : std_logic;
    signal execute_memory_buffer_next_is_out_instruction : std_logic;
    signal fu_execute_select_r_src_from_r_src, fu_execute_select_r_dst_from_r_dst : std_logic;
    signal eu_next_buffer_memory_has, execute_memory_buffer_next_memory_has : std_logic_vector(1 downto 0);
begin
    System_PC : PC port map (
            clk_c => clk_c, reset_in => reset_in,
            execute_is_jump_taken_in => execute_pc_is_jump_taken, decode_is_call_in => decode_pc_is_call,
            memory_is_return_in => memory_pc_is_return, memory_is_interrupt_in => memory_pc_cu_is_interrupt, 
            su_enable_pc_inc_in => su_pc_enable_pc_increment, decode_is_interrupt_in => decode_pc_is_interrupt, 
            starting_address_in => memory_pc_start_address, execute_jump_address_in => execute_pc_jmp_address,
            decode_call_address_in => decode_pc_call_address, memory_return_address_in =>memory_pc_return_adress, 
            interupt_address_in => memory_pc_interrupt_address,address_out => current_pc_address
        );

    System_Fetch_Stage : FetchStage generic map (word_width => 16, cache_size => 512)
        port map ( clk_c => clk_c,current_instruction_address_in => current_pc_address,data_word_out => fetch_fetch_decode_buffer_data);
    
    System_Fetch_Decode_Buffer : FetchDecodeBuffer generic map (word_width => 16) port map (
            clk_c => clk_c, enable_in => su_fetch_decode_buffer_enable, reset_in => su_fetch_decode_buffer_reset,
            is_interrupt_in =>cu_buffers_is_interrupt, next_instruction_address_in => current_pc_address, 
            data_word_in => fetch_fetch_decode_buffer_data, is_interrupt_out => fetch_decode_next_buffer_is_interrupt,
            next_instruction_address_out => fetch_decode_next_buffers_pc, data_word_out => fetch_buffer_decode_data_word
        );

        System_Decode_Stage : DecodeStage port map (
                clk_c => clk_c, reset_in => reset_in,instruction_in => fetch_buffer_decode_data_word,
                r_src_address_in => memory_buffer_r_src_address , r_dst_address_in => memory_buffer_r_dst_address,
                enable_writeback_in => memory_buffer_enable_write_back,
                r_src_data_in => memory_buffer_r_src, r_dst_data_in => memory_buffer_r_dst,
                immediate_fetched_in => decode_execute_buffer_immediate_fetched,
                r_dst_from_execute_in => execute_memory_buffer_r_dst_data, r_dst_from_memory_in => memory_buffer_r_dst,
                call_pc_address_select_in => fu_decode_r_dst_select, opcode_out => decode_next_buffer_op_code,
                r_src_address_out => decode_next_buffer_r_src_address, r_dst_address_out => decode_next_buffer_r_dst_address,
                r_src_data_out =>decode_next_buffer_r_src_data, r_dst_data_out=>decode_next_buffer_r_dst_data,
                immediate_data_out =>decode_next_buffer_immediate ,pc_address_out => decode_pc_call_address
            ) ;

        System_Decode_Execute_Buffer : DecodeExecuteBuffer port map (
                clk_c => clk_c, reset_in =>su_decode_execute_buffer_reset ,enable_in =>su_decode_execute_buffer_enable,
                --From Decode stage
                immediate_data_in => decode_next_buffer_immediate,r_src_address_in =>decode_next_buffer_r_src_address,
                r_dst_address_in => decode_next_buffer_r_dst_address,
                r_src_data_in => decode_next_buffer_r_src_data, r_dst_data_in => decode_next_buffer_r_dst_data,
                opcode_in => decode_next_buffer_op_code,
                
                --From CU
                input_word_type_in => cu_decode_buffer_input_word_type,
                cu_is_interrupt_in => cu_buffers_is_interrupt, is_return_in => cu_is_return, --TODO : Make sure that is return acts in a right way
                --Control Word
                enable_memory_in => cu_enable_memory, memory_read_write_in => cu_memory_read_write, enable_writeback_in => cu_enable_write_back,
                last_buffer_is_interrupt_in =>fetch_decode_next_buffer_is_interrupt, next_instruction_address_in => fetch_decode_next_buffers_pc,     
                --From FU
                decode_has_in => fu_decode_execute_buffer_decode_has, 
                enable_memory_out =>decode_execute_buffer_next_enable_memory, memory_read_write_out =>decode_execute_buffer_next_memory_read_write_out,
                enable_writeback_out => decode_execute_buffer_next_enable_writeback,
                is_interrupt_out => decode_execute_buffer_next_is_interrupt,is_return_out => decode_execute_buffer_next_is_return ,-- Goes to ExecuteMemoryBuffer
                decode_has_out => decode_execute_buffer_fu_decode_has,
                immediate_fetched_out => decode_execute_buffer_immediate_fetched,-- To stall unit, decodeStage
                input_word_type_out =>decode_execute_buffer_next_input_word_type,
                r_src_address_out => decode_execute_buffer_next_r_src_address, r_dst_address_out => decode_execute_buffer_next_r_dst_address,
                r_src_data_out => decode_execute_buffer_next_r_src_data, r_dst_data_out =>decode_execute_buffer_next_r_dst_data,
                next_instruction_address_out =>decode_execute_buffer_next_instruction_address, opcode_out =>decode_execute_buffer_next_op_code
            ) ;

        System_Execute_Stage : ExecuteStage port map (
                clk_c => clk_c, reset_in => reset_in, enable_in => su_enable_execute_stage,
                opcode_in => decode_execute_buffer_next_op_code,
                pc_address_in => current_pc_address, in_port_data_in => in_port_in,
                is_interrupt_in =>decode_execute_buffer_next_is_interrupt,
                next_instruction_address_in => decode_execute_buffer_next_instruction_address,
        
                r_src_data_from_decode_in => decode_execute_buffer_next_r_src_data, r_dst_data_from_decode_in => decode_execute_buffer_next_r_dst_data,
                r_src_data_from_execute_in => execute_memory_buffer_r_src_data, 
                r_dst_data_from_execute_in => execute_memory_buffer_r_dst_data,
                r_src_data_from_memory_in => memory_buffer_r_src, r_dst_data_from_memory_in => memory_buffer_r_dst,
                execute_r_src_selection_in => fu_execute_r_src_selection, execute_r_dst_selection_in => fu_execute_r_dst_selection,
                
                memory_is_return_interrupt_in => memory_eu_is_interrupt_return, flags_in => memory_eu_flags,
                 select_r_src_from_r_src => fu_execute_select_r_src_from_r_src, select_r_dst_from_r_dst => fu_execute_select_r_dst_from_r_dst,
                memory_address_out => eu_next_buffer_memory_address, memory_input_out => eu_next_buffer_memory_input,
                memory_needs_src_out => eu_next_buffer_memory_needs_src,
                memory_has_out => eu_next_buffer_memory_has,
                memory_is_return_interrupt_out => eu_next_buffer_memory_is_return_interrupt,
                r_src_data_out => execute_next_buffer_r_src_data, r_dst_data_out =>execute_next_buffer_r_dst_data,
                execute_needs_out => eu_fu_execute_needs, execute_has_out => eu_next_buffer_execute_has,
                is_jump_taken_out => execute_pc_is_jump_taken, is_out_instruction_out =>eu_next_buffer_is_out_instruction,
                pc_address_out => execute_pc_jmp_address
            );

    System_Execute_Memory_Buffer: ExecuteMemoryBuffer  port map (
            clk_c => clk_c, reset_in => su_execute_memory_buffer_reset ,enable_in => '1', --TODO: Make sure that it always is enabled
            --From Execute Stage
            memory_address_in => eu_next_buffer_memory_address, memory_input_in =>eu_next_buffer_memory_input,
            memory_needs_src_in => eu_next_buffer_memory_needs_src,memory_has_in => eu_next_buffer_memory_has,
            memory_is_return_interrupt_in => eu_next_buffer_memory_is_return_interrupt,
            r_src_data_in => execute_next_buffer_r_src_data, r_dst_data_in => execute_next_buffer_r_dst_data,
            execute_has_in => eu_next_buffer_execute_has,is_out_instruction_in => eu_next_buffer_is_out_instruction,
    
            --From Decode Execute buffer
            r_src_address_in => decode_execute_buffer_next_r_src_address, r_dst_address_in => decode_execute_buffer_next_r_dst_address,
            last_buffer_is_interrupt_in => decode_execute_buffer_next_is_interrupt,is_return_in => decode_execute_buffer_next_is_return,
            
            --From CU
            cu_is_interrupt_in => cu_buffers_is_interrupt,
    
            --Control Word
            enable_memory_in => decode_execute_buffer_next_enable_memory, memory_read_write_in => decode_execute_buffer_next_memory_read_write_out,
            enable_writeback_in => decode_execute_buffer_next_enable_writeback,
    
            memory_address_out => execute_memory_buffer_next_memory_address, memory_input_out => execute_memory_buffer_next_memory_input,
            memory_needs_src_out => execute_memory_buffer_fu_memory_needs_src,
            memory_is_return_interrupt_out => memory_eu_is_interrupt_return,
            r_src_data_out => execute_memory_buffer_r_src_data, r_dst_data_out => execute_memory_buffer_r_dst_data,
            r_src_address_out => execute_memory_buffer_next_r_src_address, r_dst_address_out => execute_memory_buffer_next_r_dst_address,
            is_interrupt_out => execute_memory_buffer_next_is_interrupt,
            execute_has_out => execute_memory_buffer_fu_execute_has,-- GOES TO FU
            enable_memory_out => execute_memory_buffer_next_enable_memory ,memory_read_write_out => execute_memory_buffer_next_memory_read_write,
            enable_writeback_out => execute_memory_buffer_enable_write_back,
            is_return_out => memory_pc_is_return,is_out_instruction_out =>execute_memory_buffer_next_is_out_instruction,  -- Goes to Memory buffer and pc
            memory_has_out => execute_memory_buffer_next_memory_has
        ) ;
        

    System_Memory_Stage :  MemoryStage port map (
            clk_c => clk_c, enable_in => execute_memory_buffer_next_enable_memory, memory_read_write_in => execute_memory_buffer_next_memory_read_write,
             -- enable_in : write to cache and saving to buffer
    
            -- this is saved in the buffer by the EU, then the buffer sends it to the EU
           is_return_interrupt_in => execute_memory_buffer_next_is_interrupt,
            --Memory buffer must output memory_needs
            memory_data_src_selection_in => fu_memory_src_selection, -- From FU
            memry_address_in => execute_memory_buffer_next_memory_address, 
            data_from_execute_in => execute_memory_buffer_next_memory_input, data_from_memory_in => memory_buffer_r_dst,
            memory_data_out => memory_next_buffer_memory_data, pc_address_out => memory_pc_return_adress, -- will be put in r_dst
            flags_out => memory_eu_flags,
            memory_read_out => memory_next_buffer_memory_read_enable,
            pc_starting_address_out => memory_pc_start_address, pc_interrupt_address_out=> memory_pc_interrupt_address
        ) ;

    System_Memory_Buffer :  MemoryBuffer port map (
            clk_c => clk_c, reset_in => reset_in,
            --From Execute, Memory Buffer
            r_src_data_in => execute_memory_buffer_r_src_data, r_dst_data_in => execute_memory_buffer_r_dst_data,
            r_src_address_in =>execute_memory_buffer_next_r_src_address, r_dst_address_in => execute_memory_buffer_next_r_dst_address,
            is_return_in => memory_pc_is_return, is_interrupt_in =>execute_memory_buffer_next_is_interrupt,is_out_instruction_in =>execute_memory_buffer_next_is_out_instruction,
            enable_writeback_in => execute_memory_buffer_enable_write_back,

            --From memory Stage
            memory_data_in => memory_next_buffer_memory_data,
            memory_read_enable_in => memory_next_buffer_memory_read_enable,
            memory_has_in => execute_memory_buffer_next_memory_has,

            r_src_data_out => memory_buffer_r_src, r_dst_data_out => memory_buffer_r_dst,
            r_src_address_out => memory_buffer_r_src_address, r_dst_address_out =>memory_buffer_r_dst_address,
            is_return_out => memory_cu_is_return, is_interrupt_out => memory_cu_is_interrupt,
            enable_writeback_out =>memory_buffer_enable_write_back, -- goes also to FU
            out_port_out => out_port_out,memory_has_out => memory_fu_memory_has
        ) ;

    System_Control_Unit : ControlUnit port map (
                interrupt_in => interrupt_in, -- From input
                opcode_in => decode_next_buffer_op_code, -- From decode stage
                interrupt_reset_in =>memory_cu_is_interrupt, --Comes from memory buffer
                jump_taken_in => execute_pc_is_jump_taken, --From execute Stage
                return_reset_in => memory_cu_is_return, -- From MemoryStageBuffer
        
                is_interrupt_out => cu_buffers_is_interrupt, -- Goes to fetchDecodeBuffer
                is_return_out => cu_is_return, -- Goes to DecodeExecute buffer
        
                enable_memory_out => cu_enable_memory, memory_read_write_out => cu_memory_read_write, -- Goes to memoryStage after some cycles
                enable_writeback_out => cu_enable_write_back, input_word_type_out => cu_decode_buffer_input_word_type, -- Goes to memory WriteBack Buffer, DecodeExecute Buffer
        
                stall_index_out => cu_su_stall_index, -- Goes to Stall unit
        
                decode_needs_out => cu_fu_decode_needs -- Goes to forwarding Unit
            );

    System_Forward_Unit :  ForwardingUnit port map (
            clk_c => clk_c, reset_in => reset_in,
    
            will_change_in => cu_enable_write_back,      --This comes form the CU(enable_writeback_out), to tell me if this instruction will change anything
            decode_r_src_index_in => decode_next_buffer_r_src_address,
            decode_r_dst_index_in => decode_next_buffer_r_dst_address ,
    
            decode_needs_in => cu_fu_decode_needs,  -- From CU
            decode_needs_r_dst_index_in => decode_next_buffer_r_dst_address,
    
            decode_has_in => decode_execute_buffer_fu_decode_has,       --Used in EU needs
            
            execute_has_in => execute_memory_buffer_fu_execute_has, -- From buffer after
            execute_has_r_src_index_in => execute_memory_buffer_next_r_src_address,
            execute_has_r_dst_index_in  => execute_memory_buffer_next_r_dst_address,
    
            execute_needs_in => eu_fu_execute_needs, -- From stage
            execute_needs_r_src_index_in => decode_execute_buffer_next_r_src_address,
            execute_needs_r_dst_index_in => decode_execute_buffer_next_r_dst_address,
    
            memory_has_in => memory_fu_memory_has,
            memory_has_r_src_index_in => memory_buffer_r_src_address,
            memory_has_r_dst_index_in => memory_buffer_r_dst_address,
    
            memory_needs_in  => execute_memory_buffer_fu_memory_needs_src,--No need for it, make sure then remove it
            memory_needs_r_src_index_in => execute_memory_buffer_next_r_src_address,
            immediate_fetched_in => decode_execute_buffer_immediate_fetched,-- From DecodeExecuteBuffer
    
            stall_stage_index_out => fu_su_stall_index,
    
            decode_r_dst_selection_out => fu_decode_r_dst_select,
    
            execute_r_src_selection_out => fu_execute_r_src_selection,
            execute_r_dst_selection_out => fu_execute_r_dst_selection,
            execute_r_src_selection_from_r_src => fu_execute_select_r_src_from_r_src,
            execute_r_dst_selection_from_r_dst => fu_execute_select_r_dst_from_r_dst,
    
            --TODO Make sure there can be no stalls in anything forwarding to memrory
            memory_r_src_selection_out => fu_memory_src_selection,
            decode_has_out => fu_decode_execute_buffer_decode_has,      --To tell the decode what it has
    
            write_back_has_written_src_index_in => memory_buffer_r_src_address,write_back_has_written_dst_index_in =>memory_buffer_r_dst_address,
            write_back_select_in => memory_buffer_enable_write_back
        );

        System_Stall_Unit : StallingUnit port map (
            cu_stall_stage_index_in => cu_su_stall_index, fu_stall_stage_index_in => fu_su_stall_index,
            global_reset_in => reset_in,immediate_fetched_in => decode_execute_buffer_immediate_fetched,
            enable_pc_inc_out => su_pc_enable_pc_increment,
            enable_fetch_decode_buffer_out => su_fetch_decode_buffer_enable, reset_fetch_decode_buffer_out => su_fetch_decode_buffer_reset,
            enable_decode_execute_buffer_out => su_decode_execute_buffer_enable, reset_decode_execute_buffer_out => su_decode_execute_buffer_reset,
            enable_execute_stage => su_enable_execute_stage,--Flags and jumps
            reset_execute_memory_buffer_out => su_execute_memory_buffer_reset -- Will never keep value of execute
        );

end system_arch ; -- system_arch