library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nRegistersFile is
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
end nRegistersFile;

architecture n_registers_file_arch of nRegistersFile is
    component nBitsDoubleRegister is
        generic (
            n : integer
        );
        port (
            clk_c, enable1_in, enable2_in, reset_in : in std_logic;
            data1_in, data2_in : in std_logic_vector(n-1 downto 0);
    
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

    signal enable1_s, enable2_s : std_logic_vector((2**num_selection_bits)-1 downto 0);

    type data_t is array(n-1 downto 0) of std_logic_vector(register_width-1 downto 0);
    signal data_s : data_t; 
begin

    Src_Decoder : nBitsDecoder generic map (n => num_selection_bits) port map (
        enable_in => enable1_in, selection_in => r_src_write_address_in,
        data_out => enable1_s
    );

    Dst_Decoder : nBitsDecoder generic map (n => num_selection_bits) port map (
        enable_in => enable2_in, selection_in => r_dst_write_address_in,
        data_out => enable2_s
    );

    Inner_Double_Registers_Generation : for i in 0 to n-1 generate
        N_Bits_Double_Register_i : nBitsDoubleRegister generic map ( n => register_width) port map (
            clk_c => clk_c, enable1_in => enable1_s(i), enable2_in => enable2_s(i), reset_in => reset_in,
            data1_in => r_src_data_in, data2_in => r_dst_data_in,
    
            data_out => data_s(i)
        );
    end generate;

    r_src_data_out <= data_s(to_integer(unsigned(r_src_read_address_in)));
    r_dst_data_out <= data_s(to_integer(unsigned(r_dst_read_address_in)));

end n_registers_file_arch ; -- n_registers_file_arch

