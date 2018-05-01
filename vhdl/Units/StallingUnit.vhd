library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity StallingUnit is
    port (
        cu_stall_stage_index_in, fu_stall_stage_index_in : in std_logic_vector(1 downto 0);

        enable_pc_inc_out : out std_logic;
        enable_fetch_decode_buffer_out, reset_fetch_decode_buffer_out : out std_logic; -- Will never reset fetch
        enable_decode_execute_buffer_out, reset_decode_execute_buffer_out : out std_logic;
        reset_execute_memory_buffer_out : out std_logic -- Will never keep value of execute
    );
end StallingUnit;

architecture stalling_unit_arch of StallingUnit is
begin
    enable_pc_inc_out <= '1' when cu_stall_stage_index_in /= NO_STALL or fu_stall_stage_index_in /= NO_STALL
    else '0';  -- Will always stop pc if there is stall

    enable_fetch_decode_buffer_out <= '1' when cu_stall_stage_index_in /= NO_STALL or fu_stall_stage_index_in /= NO_STALL
    else '0';  -- Will always keep last fetch when there is stall

    -- At stall[stage] we keep all buffers before stage as is (disable them)
    -- and flush the next buffer only (reset)
    -- reset will override enable
    reset_fetch_decode_buffer_out <= '1' when cu_stall_stage_index_in = CU_STALL_FETCH
    else '0';
    reset_decode_execute_buffer_out <= '1' when fu_stall_stage_index_in = STALL_DECODE xor fu_stall_stage_index_in = STALL_DECODE
    else 'Z' when fu_stall_stage_index_in = STALL_DECODE and fu_stall_stage_index_in = STALL_DECODE
    else '0';
    reset_execute_memory_buffer_out <= '1' when fu_stall_stage_index_in = FU_STALL_EXECUTE
    else '0';

    enable_decode_execute_buffer_out <= '0' when fu_stall_stage_index_in = FU_STALL_EXECUTE
    else '1';
end stalling_unit_arch ; -- stalling_unit_arch

