library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity StallingUnit is
    port (
        clk_c, global_reset_in : in std_logic;

        cu_stall_stage_index_in, fu_stall_stage_index_in : in std_logic_vector(1 downto 0);
        immediate_fetched_in : in std_logic;
        
        enable_pc_inc_out : out std_logic;
        enable_fetch_decode_buffer_out, reset_fetch_decode_buffer_out : out std_logic;
        enable_decode_execute_buffer_out, reset_decode_execute_buffer_out : out std_logic;
        enable_execute_stage : out std_logic; --Flags and jumps
        reset_execute_memory_buffer_out : out std_logic -- Will never keep value of execute
    );
end StallingUnit;

architecture stalling_unit_arch of StallingUnit is
    component oneBitHalfCycleRegister is
        port (
            clk_c, reset_in : in std_logic;
            data_in : in std_logic;
    
            data_out : out std_logic
        );
    end component;
    component BitFlipFlop is
        port (
            clk_c, reset_in : in std_logic;
            data_in : in std_logic;
    
            data_out : out std_logic
        );
    end component;

    signal reset_fetch_decode_buffer_s, reset_decode_execute_buffer_s, reset_execute_memory_buffer_s : std_logic;
    signal enable_execute_stage_s , enable_pc_inc_s,enable_fetch_decode_buffer_s,enable_decode_execute_buffer_s : std_logic;
    signal not_clk_c : std_logic;
begin
    Fetch_Decode_Delay_Buffer : oneBitHalfCycleRegister port map (
        clk_c => clk_c, reset_in => global_reset_in, data_in => reset_fetch_decode_buffer_s,

        data_out => reset_fetch_decode_buffer_out
    );
    Decode_Execute_Delay_Buffer : oneBitHalfCycleRegister port map (
        clk_c => clk_c, reset_in => global_reset_in, data_in => reset_decode_execute_buffer_s,

        data_out => reset_decode_execute_buffer_out
    );
    Execute_Memory_Delay_Buffer : oneBitHalfCycleRegister port map (
        clk_c => clk_c, reset_in => global_reset_in, data_in => reset_execute_memory_buffer_s,
        data_out => reset_execute_memory_buffer_out
    );

    not_clk_c <= not clk_c;
    Enable_Execute_Stage_Buffer : BitFlipFlop port map (
        clk_c => not_clk_c , reset_in => global_reset_in, data_in => enable_execute_stage_s,
        data_out => enable_execute_stage
    );
    Enable_PC_Inc_Buffer : BitFlipFlop port map (
        clk_c => not_clk_c , reset_in => global_reset_in, data_in => enable_pc_inc_s,
        data_out => enable_pc_inc_out
    );
    Enable_Fetch_Decode_Buffer_Buffer : BitFlipFlop port map (
        clk_c => not_clk_c , reset_in => global_reset_in, data_in => enable_fetch_decode_buffer_s,
        data_out => enable_fetch_decode_buffer_out
    );

    Enable_Decode_Execute_Buffer_Buffer : BitFlipFlop port map (
        clk_c => not_clk_c , reset_in => global_reset_in, data_in => enable_decode_execute_buffer_s,
        data_out => enable_decode_execute_buffer_out
    );

    enable_pc_inc_s <= '0' when fu_stall_stage_index_in /= NO_STALL
    else '1';  -- Will always stop pc if there is stall

    enable_fetch_decode_buffer_s <= '0' when cu_stall_stage_index_in /= NO_STALL or fu_stall_stage_index_in /= NO_STALL
    else '1';  -- Will always keep last fetch when there is stall

    -- At stall[stage] we keep all buffers before stage as is (disable them)
    -- and flush the next buffer only (reset)
    -- reset will override enable
    reset_fetch_decode_buffer_s <= '1' when ((cu_stall_stage_index_in /= NO_STALL ) or global_reset_in = '1')
    else '0';
    reset_decode_execute_buffer_s <= '1' 
    when (((cu_stall_stage_index_in = CU_STALL_FETCH or cu_stall_stage_index_in = CU_STALL_FETCH_AND_DECODE) xor fu_stall_stage_index_in = STALL_DECODE) or global_reset_in = '1'or cu_stall_stage_index_in = CU_STALL_FETCH_AND_DECODE)
    else 'Z' when (cu_stall_stage_index_in = CU_STALL_FETCH or cu_stall_stage_index_in = CU_STALL_FETCH_AND_DECODE) and fu_stall_stage_index_in = STALL_DECODE
    else '0';
    reset_execute_memory_buffer_s <= '1' when fu_stall_stage_index_in = FU_STALL_EXECUTE or global_reset_in = '1'or immediate_fetched_in = NOT_FETCHED or cu_stall_stage_index_in = CU_STALL_FETCH_AND_DECODE
    else '0' ;
    enable_execute_stage_s <= '0' when fu_stall_stage_index_in = FU_STALL_EXECUTE or immediate_fetched_in = NOT_FETCHED or cu_stall_stage_index_in = CU_STALL_FETCH_AND_DECODE else '1';
    enable_decode_execute_buffer_s <= '0' when fu_stall_stage_index_in = FU_STALL_EXECUTE
    else '1';
end stalling_unit_arch ; -- stalling_unit_arch

