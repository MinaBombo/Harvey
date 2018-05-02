library ieee;
use ieee.std_logic_1164.all;
library work;
use work.Commons.all;

entity DecodeStage is
    port (
        clk_c, reset_in : in std_logic;

        instruction_in : in std_logic_vector(15 downto 0);

        -- From writeback
        enable_r_src_in, enable_r_dst_in : in std_logic; 
        r_src_address_in, r_dst_address_in : in std_logic_vector(2 downto 0);
        r_src_data_in, r_dst_data_in : in std_logic_vector(15 downto 0);

        opcode_out : out  std_logic_vector(4 downto 0);
        r_src_address_out, r_dst_address_out : out std_logic_vector(2 downto 0);
        r_src_data_out, r_dst_data_out : out std_logic_vector(15 downto 0)
    ) ;
end DecodeStage;

architecture decode_stage_arch of DecodeStage is
    component nRegistersFile is
        generic (
            n : integer;
            num_selection_bits : integer;
            register_width : integer
        );
        port (
            clk_c, enable1_in, enable2_in, reset_in : in std_logic;
    
            r_src_write_address_in, r_dst_write_address_in : in std_logic_vector(num_selection_bits downto 0);
            r_src_read_address_in, r_dst_read_address_in : in std_logic_vector(num_selection_bits downto 0);
    
            r_src_data_in, r_dst_data_in : in std_logic_vector(register_width-1 downto 0);
    
            r_src_data_out, r_dst_data_out : out std_logic_vector(register_width-1 downto 0)
        );
    end component;

    signal r_src_read_address_s, r_dst_read_address_s : std_logic_vector(2 downto 0);
begin

    r_src_read_address_s <= instruction_in(R_SRC_HIGHER_LIMIT downto R_DST_HIGHER_LIMIT+1);
    r_dst_read_address_s <= instruction_in(R_DST_HIGHER_LIMIT downto R_DST_LOWER_LIMIT);

    Inner_Register_File : nRegistersFile generic map (n => 6, num_selection_bits => 3, register_width => 16) port map (
        clk_c => clk_c, enable1_in => enable_r_src_in, enable2_in => enable_r_dst_in, reset_in => reset_in,
        r_src_write_address_in => r_src_address_in, r_dst_write_address_in => r_dst_address_in,
        r_src_read_address_in => r_src_read_address_s, r_dst_read_address_in => r_dst_read_address_s,
        r_src_data_in => r_src_data_in, r_dst_data_in => r_dst_data_in,
        r_src_data_out => r_src_data_out, r_dst_data_out => r_dst_data_out
    );

    --implement has and needs
end decode_stage_arch ; -- decode_stage_arch