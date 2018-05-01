library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.Commons.all;

entity ALU is
    port (
        data1_in, data2_in : in std_logic_vector(15 downto 0);
        flags_in : in std_logic_vector(3 downto 0);
        alu_instruction_in : in std_logic_vector(4 downto 0);

        result_out : out std_logic_vector(15 downto 0);
        flags_out : out std_logic_vector(3 downto 0)
    );
end ALU;

architecture alu_arch of ALU is
    signal result_s : std_logic_vector(16 downto 0); 
begin

    result_s <= (others => 'Z') when alu_instruction_in = ALU_OP_NOP
    else std_logic_vector(unsigned('0'&data1_in) + unsigned('0'&data2_in)) when alu_instruction_in = ALU_OP_ADD
    else std_logic_vector(unsigned('0'&data1_in) - unsigned('0'&data2_in)) when alu_instruction_in = ALU_OP_SUB
    else '0'&(data1_in and data2_in) when alu_instruction_in = ALU_OP_AND
    else '0'&(data1_in or data2_in) when alu_instruction_in = ALU_OP_OR
    else '0'&data1_in(15 downto 1)&flags_in(FLAG_CARRY_INDEX) when alu_instruction_in = ALU_OP_RLC
    else '0'&flags_in(FLAG_CARRY_INDEX)&data1_in(14 downto 0) when alu_instruction_in = ALU_OP_RRC
    else std_logic_vector(SHIFT_LEFT(unsigned('0'&data1_in), to_integer(unsigned(data2_in)))) when alu_instruction_in = ALU_OP_SHL
    else std_logic_vector(SHIFT_RIGHT(unsigned('0'&data1_in), to_integer(unsigned(data2_in)))) when alu_instruction_in = ALU_OP_SHR
    else (others => 'Z') when alu_instruction_in = ALU_OP_SETC
    else (others => 'Z') when alu_instruction_in = ALU_OP_CLRC
    else '0'&(not data1_in) when alu_instruction_in = ALU_OP_NOT
    else std_logic_vector(unsigned('0'&data1_in) + 1) when alu_instruction_in = ALU_OP_INC
    else std_logic_vector(unsigned('0'&data1_in) - 1) when alu_instruction_in = ALU_OP_DEC
    else (others => 'Z');

    flags_out(FLAG_ZERO_INDEX) <= 
    flags_in(FLAG_ZERO_INDEX) when alu_instruction_in = ALU_OP_NOP or alu_instruction_in = ALU_OP_SETC or alu_instruction_in = ALU_OP_CLRC
    else '1' when  result_s = '0'&x"0000" else '0';

    flags_out(FLAG_NEGATIVE_INDEX) <= 
    flags_in(FLAG_NEGATIVE_INDEX) when alu_instruction_in = ALU_OP_NOP or alu_instruction_in = ALU_OP_SETC or alu_instruction_in = ALU_OP_CLRC
    else result_s(15);

    flags_out(FLAG_CARRY_INDEX) <= 
    flags_in(FLAG_CARRY_INDEX) when alu_instruction_in = ALU_OP_NOP or alu_instruction_in = ALU_OP_AND 
    or alu_instruction_in = ALU_OP_OR or alu_instruction_in = ALU_OP_DEC or alu_instruction_in = ALU_OP_INC
    else '1'  when alu_instruction_in = ALU_OP_SETC
    else '0' when alu_instruction_in = ALU_OP_CLRC
    else result_s(16);

    flags_out (FLAG_OVERFLOW_INDEX) <= 
    flags_in(FLAG_OVERFLOW_INDEX) when alu_instruction_in /= ALU_OP_ADD  or  alu_instruction_in /= ALU_OP_SUB
    else '1' when (((data1_in(15) = '0' and data2_in (15) ='0' and result_s(15) = '1') or (data1_in(15) = '1' and data2_in (15) ='1' and result_s(15) = '0'))  and alu_instruction_in = ALU_OP_ADD)
    or ((((data1_in(15) = '0' and data2_in (15) ='1' and result_s(15) = '1') or (data1_in(15) = '1' and data2_in (15) ='0' and result_s(15) = '0'))) and alu_instruction_in = ALU_OP_SUB);


end alu_arch ; -- alu_arch