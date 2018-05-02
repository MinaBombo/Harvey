library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity ExecuteStage is
    port (
        clk_c, reset_in : in std_logic;

        opcode_in : in std_logic_vector(4 downto 0);
        pc_address_in : in std_logic_vector(15 downto 0);
        is_interrupt_in : in std_logic;
        next_instruction_address_in : in std_logic_vector(15 downto 0);

        r_src_data_from_decode_in, r_dst_data_from_decode_in : in std_logic_vector(15 downto 0);
        r_src_data_from_execute_in, r_dst_data_from_execute_in : in std_logic_vector(15 downto 0);
        r_src_data_from_memory_in, r_dst_data_from_memory_in : in std_logic_vector(15 downto 0);
        execute_r_src_selection_in, execute_r_dst_selection_in: in std_logic_vector(1 downto 0);

    
        memory_address_out, memory_input_out : out std_logic_vector(15 downto 0); -- for memory stage
        memory_needs_src_out : out std_logic;
        r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0); -- for write back stage
        execute_needs_out, execute_has_out : out std_logic_vector(1 downto 0);  -- for FU

        is_jump_taken_out : out std_logic;
        pc_address_out : out std_logic_vector(15 downto 0)
    );
end ExecuteStage;

architecture execute_stage_arch of ExecuteStage is
    component SP is
        port (
            clk_c, reset_in : in std_logic;
            operation_in : in std_logic_vector(1 downto 0);
            
            address_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component ALU is
        port (
            data1_in, data2_in : in std_logic_vector(15 downto 0);
            flags_in : in std_logic_vector(3 downto 0);
            alu_instruction_in : in std_logic_vector(4 downto 0);
    
            result_out : out std_logic_vector(15 downto 0);
            flags_out : out std_logic_vector(3 downto 0)
        );
    end component;

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

    signal r_src_data_s, r_dst_data_s:  std_logic_vector(15 downto 0);

    signal sp_operation_s : std_logic_vector(1 downto 0);
    signal sp_address_s : std_logic_vector(15 downto 0);

    signal is_alu_operation_s : std_logic;
    signal alu_data1_s, alu_data2_s, alu_result_s : std_logic_vector(15 downto 0);
    signal flag_register_input_s, flag_register_output_s : std_logic_vector(3 downto 0);

    signal mult_result_s : std_logic_vector(31 downto 0);

begin

    sp_operation_s <= SP_PUSH when opcode_in = OP_PUSH 
    else SP_POP when opcode_in = OP_POP
    else SP_NO_OP;
    Stack_Pointer : SP port map (
        clk_c => clk_c, reset_in => reset_in, operation_in => sp_operation_s,
        address_out => sp_address_s
    );

    is_alu_operation_s <= not opcode_in(4);
    Flags_Register : nBitRegister generic map (n=>4) port map (
        clk_c => clk_c, enable_in => is_alu_operation_s, data_in => flag_register_input_s, 
        data_out => flag_register_output_s
    );

    r_src_data_s <= r_src_data_from_decode_in when execute_r_src_selection_in = EXECUTE_SELECT_NORMAL 
    else r_src_data_from_execute_in when execute_r_src_selection_in = EXECUTE_SELECT_SELF
    else r_src_data_from_memory_in when execute_r_src_selection_in = EXECUTE_SELECT_MEMORY
    else (others => 'Z');

    r_dst_data_s <= r_dst_data_from_decode_in when execute_r_dst_selection_in = EXECUTE_SELECT_NORMAL 
    else r_dst_data_from_execute_in when execute_r_dst_selection_in = EXECUTE_SELECT_SELF
    else r_dst_data_from_memory_in when execute_r_dst_selection_in = EXECUTE_SELECT_MEMORY
    else (others => 'Z');

    Inner_ALU : ALU port map (
        data1_in => r_src_data_s, data2_in => r_dst_data_s, flags_in => flag_register_output_s, 
        alu_instruction_in => opcode_in, 
        result_out => alu_result_s, flags_out => flag_register_input_s
    );

    mult_result_s <= std_logic_vector(unsigned(r_src_data_s) * unsigned(r_dst_data_s));

    r_dst_data_out <= alu_result_s when is_alu_operation_s = '1'
    else r_src_data_s when opcode_in = OP_MOV or opcode_in = OP_IN -- source is in port
    else mult_result_s(15 downto 0) when opcode_in = OP_MUL
    else r_dst_data_s when opcode_in = OP_LDM -- immediate comes in dst
    else (others => 'Z');

    r_src_data_out <= mult_result_s(31 downto 16) when opcode_in = OP_MUL else (others => 'Z'); 
    

    sp_operation_s <= 
    SP_PUSH when opcode_in = OP_PUSH or  opcode_in = OP_CALL or is_interrupt_in = '1'
    else SP_POP when opcode_in = OP_POP or opcode_in = OP_RET or opcode_in = OP_RTI
    else SP_NO_OP;

    execute_needs_out <= 
    NEED_BOTH when opcode_in = ALU_OP_ADD or opcode_in = ALU_OP_SUB or opcode_in = ALU_OP_AND
    or opcode_in = ALU_OP_OR or opcode_in = OP_MUL 
    else NEED_SRC when opcode_in = ALU_OP_SHL or opcode_in = ALU_OP_SHR 
    or opcode_in = OP_MOV
    else NEED_DST when opcode_in = ALU_OP_RLC or opcode_in = ALU_OP_RRC or opcode_in = ALU_OP_NOT
    or opcode_in = ALU_OP_INC or opcode_in = ALU_OP_DEC or opcode_in = OP_OUT or opcode_in = OP_JZ
    or opcode_in = OP_JN or opcode_in = OP_JC or opcode_in = OP_JMP or opcode_in = OP_CALL
    else NEEDS_NOTHING when opcode_in = ALU_OP_NOP or opcode_in = ALU_OP_SETC or opcode_in = ALU_OP_CLRC
    or opcode_in = OP_POP or opcode_in = OP_PUSH or opcode_in = OP_IN or opcode_in = OP_RET or opcode_in = OP_RTI 
    or opcode_in = OP_LDM or opcode_in = OP_LDD
    else (others => 'Z'); 

    execute_has_out <= 
    HAS_ALL when opcode_in = OP_MUL
    else HAS_DST  when opcode_in = ALU_OP_ADD or opcode_in = ALU_OP_SUB or opcode_in = ALU_OP_AND 
    or opcode_in = ALU_OP_OR or opcode_in = ALU_OP_RLC or opcode_in = ALU_OP_RRC or opcode_in = ALU_OP_SHL 
    or opcode_in = ALU_OP_SHR or opcode_in = ALU_OP_NOT or opcode_in = ALU_OP_INC or opcode_in = ALU_OP_DEC
    or opcode_in = OP_MOV or opcode_in = OP_IN
    else HAS_NONE when opcode_in = ALU_OP_NOP or opcode_in = ALU_OP_SETC or opcode_in = ALU_OP_CLRC
    or opcode_in = OP_POP or opcode_in = OP_PUSH or opcode_in = OP_OUT or opcode_in = OP_JZ
    or opcode_in = OP_JN or opcode_in = OP_JC or opcode_in = OP_JMP or opcode_in = OP_CALL
    or opcode_in = OP_RET or opcode_in = OP_RTI or opcode_in =  OP_LDM or opcode_in = OP_LDD
    or opcode_in = OP_STD
    else (others => 'Z'); 

    memory_address_out <= 
    sp_address_s when sp_operation_s /= SP_NO_OP
    else r_dst_data_s when opcode_in = OP_LDD or opcode_in = OP_STD --effective address 
    else (others => 'Z'); 

    memory_needs_src_out <= '1' when  opcode_in = OP_STD or opcode_in = OP_PUSH  else '0';

    memory_input_out <= 
    next_instruction_address_in when opcode_in = OP_CALL
    else pc_address_in(9 downto 0) & flag_register_output_s when is_interrupt_in = '1'
    else r_src_data_s when opcode_in = OP_PUSH or opcode_in = OP_STD
    else (others => 'Z');  
        

    is_jump_taken_out <= '1' when opcode_in = OP_JMP 
    or (opcode_in = OP_JZ and flag_register_output_s(FLAG_ZERO_INDEX) = '1')
    or (opcode_in = OP_JN and flag_register_output_s(FLAG_NEGATIVE_INDEX) = '1')
    or (opcode_in = OP_JC and flag_register_output_s(FLAG_CARRY_INDEX) = '1')
    else '0';
    pc_address_out <= r_dst_data_s;

end execute_stage_arch ; -- execute_stage_arch