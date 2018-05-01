library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity ExecuteStage is
    port (
        clk_c, reset_in : in std_logic;

        opcode_in : std_logic_vector(4 downto 0)
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

    signal sp_operation_s : std_logic_vector(1 downto 0);
    signal sp_address_s : std_logic_vector(15 downto 0);
begin

    sp_operation_s <= SP_PUSH when opcode_in = OP_PUSH 
    else SP_POP when opcode_in = OP_POP
    else SP_NO_OP;
    Stack_Pointer : SP port map (
        clk_c => clk_c, reset_in => reset_in, operation_in => sp_operation_s
        address_out => sp_address_s
    );



end execute_stage_arch ; -- execute_stage_arch