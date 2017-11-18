--Engineer     : Bryce Williams
--Date         : 11/10/2017
--Name of file : tb_sobel_image.vhd
--Description  : Imports an image (text file formatted) and writes filtered images out
-- (vertical, horizontal, summed)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;
--use std.env.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_sobel_image is
end tb_sobel_image;

architecture Behavioral of tb_sobel_image is

    constant image_size : integer := 160*120;
    constant latency : integer := 328;  
    constant num_cycles : integer := image_size + latency + 50;     -- Plus 50 for good measure

    component sobel is
        Generic(N : natural := 8;                 -- Data Width 
                LINE_WIDTH : natural := 160;      -- Image Line Width (5 or 160)
                ADDRESS_BUS_WIDTH : natural := 8  -- FIFO Address Width
                );          
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               fval_in : in STD_LOGIC :='0';
               lval_in : in STD_LOGIC :='0';
               d_in : in unsigned (7 downto 0);
               
               fval_out : out STD_LOGIC :='0';
               lval_out : out STD_LOGIC :='0';
               vert_out : out unsigned (7 downto 0);
               horz_out : out unsigned (7 downto 0);
               sum_out  : out unsigned (7 downto 0));
    end component sobel;
    
    signal vert_output_data : unsigned (7 downto 0);
    signal horz_output_data : unsigned (7 downto 0);
    signal sum_output_data : unsigned (7 downto 0);    
    
    signal rst_int  : std_logic;
    signal fval_in_int : std_logic;
    signal lval_in_int : std_logic;
    signal fval_out_int : std_logic;
    signal lval_out_int : std_logic;    
    
    signal clk_cnt : integer := 0;
    signal data_cnt: integer := 0;
    signal   data_in       : unsigned ( 7  downto 0);
    signal   clk           : std_logic;
    constant T: time       := 20 ns;
    file input_file_data   : text;

    file vert_output_file_data  : text;
    file horz_output_file_data  : text;
    file sum_output_file_data   : text;

begin

    dut : sobel port map(clk => clk, rst => rst_int, fval_in => fval_in_int, lval_in => lval_in_int,
                         d_in => data_in, fval_out => fval_out_int, lval_out => lval_out_int,
                         vert_out => vert_output_data, horz_out => horz_output_data, sum_out => sum_output_data);

    clkgen:
    process 
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process;
    
    cntr:
    process(clk)
    begin
        if rising_edge(clk) then
            clk_cnt <= clk_cnt+1;
        end if;
    end process;
    
    FileIn:
    process
        variable input_line     : line;
        variable data_term      : std_logic_vector ( 7 downto 0);
        variable data_vert_out  : line;
        variable data_horz_out  : line;
        variable space_char  : character;
    begin
        -- Open Files and reset system
        rst_int <= '1';
        file_open(input_file_data, "image_data.txt", read_mode);
        
        -- Init vars
        data_in <= (others => '0');
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rst_int <= '0';
        wait until falling_edge(clk);
        
        while not endfile(input_file_data) loop
            wait until falling_edge(clk);
                fval_in_int <= '1';
                lval_in_int <= '1';
                readline(input_file_data, input_line);
                read(input_line, data_term);
                data_in <= unsigned(data_term);
                read(input_line, space_char);
       end loop;
       wait until falling_edge(clk);
       fval_in_int <= '0';
       lval_in_int <= '0';
       file_close(input_file_data);
       wait;
   end process;     

   -- Open Output files, capture and write valid data outputs to file (space delimited)
   FileOut:
   process (clk, fval_out_int, lval_out_int) is
        variable vert_output_line : line;
        variable horz_output_line : line;
        variable sum_output_line  : line;
   begin
    if(rising_edge(clk)) then
        if(clk_cnt = 3) then
            -- Open Output Files After System Reset from FileIn Process
            file_open(vert_output_file_data, "vert_filter_output_data.txt", write_mode);
            file_open(horz_output_file_data, "horz_filter_output_data.txt", write_mode);
            file_open(sum_output_file_data, "sum_filter_output_data.txt", write_mode);
        -- Check for and write valid data sample outputs
        elsif (fval_out_int = '1' and lval_out_int = '1') then
            write(vert_output_line, std_logic_vector(vert_output_data));
            --write(vert_output_line, string'(" ");
            writeline(vert_output_file_data, vert_output_line);
            
            write(horz_output_line, std_logic_vector(horz_output_data));
            --write(horz_output_line, string'(" ");
            writeline(horz_output_file_data, horz_output_line);
            
            write(sum_output_line, std_logic_vector(sum_output_data));
            --write(sum_output_line, string'(" ");
            writeline(sum_output_file_data, sum_output_line);
            
            data_cnt <= data_cnt + 1;
            
            if(data_cnt = image_size) then
                file_close(vert_output_file_data);
                file_close(horz_output_file_data);
                file_close(sum_output_file_data);
                report "Test Completed Successfully";
--                stop(0);
            end if;
        end if;  
    end if;
   end process;

end Behavioral;
