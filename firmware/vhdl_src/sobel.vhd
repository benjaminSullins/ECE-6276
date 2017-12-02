----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Bryce Williams
-- 
-- Create Date: 11/06/2017 03:26:26 PM
-- Design Name: Sobel
-- Module Name: sobel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Implements a 2D 3x3 Convolution Filter to Implement Sobel Edge
-- detection
-- 
-- Dependencies: True Dual Port RAM BMG module, line_buffer_240
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sobel is
    Generic(N : natural := 8;                   -- Data Width 
            LINE_WIDTH : natural := 160;        -- Image Line Width (5 or 160)
            ADDRESS_BUS_WIDTH : natural := 8    -- FIFO Address Width
            );          
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           fval_in : in STD_LOGIC :='0';
           lval_in : in STD_LOGIC :='0';
           d_in : in unsigned (N-1 downto 0);
           
           fval_out : out STD_LOGIC :='0';
           lval_out : out STD_LOGIC :='0';
           vert_out : out unsigned (7 downto 0);
           horz_out : out unsigned (7 downto 0);
           sum_out  : out unsigned (7 downto 0));
end sobel;

architecture Behavioral of sobel is
    component line_buff_4 is
        Port ( 
               clka : in std_logic;
               clkb : in std_logic;
               rsta : in std_logic;
               rstb : in std_logic;
               wea  : in std_logic;
               web  : in std_logic;
               addra: in unsigned (1 downto 0);
               addrb: in unsigned (1 downto 0);
               dina : in unsigned (7 downto 0) := (others => '1'); 
               dinb : in unsigned (7 downto 0);
               douta: out unsigned (7 downto 0);
               doutb: out unsigned (7 downto 0) := (others => '1')
              );   
    end component line_buff_4;

    component line_buff_159 is
        Port ( 
               clka : in std_logic;
               clkb : in std_logic;
               rsta : in std_logic;
               rstb : in std_logic;
               wea  : in std_logic;
               web  : in std_logic;
               addra: in unsigned (7 downto 0);
               addrb: in unsigned (7 downto 0);
               dina : in unsigned (7 downto 0) := (others => '1'); 
               dinb : in unsigned (7 downto 0);
               douta: out unsigned (7 downto 0);
               doutb: out unsigned (7 downto 0) := (others => '1')
              );   
    end component line_buff_159;

    component line_buff_175 is
        Port ( 
               clka : in std_logic;
               clkb : in std_logic;
               rsta : in std_logic;
               rstb : in std_logic;
               wea  : in std_logic;
               web  : in std_logic;
               addra: in unsigned (7 downto 0);
               addrb: in unsigned (7 downto 0);
               dina : in unsigned (7 downto 0) := (others => '1'); 
               dinb : in unsigned (7 downto 0);
               douta: out unsigned (7 downto 0);
               doutb: out unsigned (7 downto 0) := (others => '1')
              );   
    end component line_buff_175;
    
    component filter_mask_3x3 is
        Generic( N : natural;
                 a_v : signed (2 downto 0);
                 b_v : signed (2 downto 0);
                 c_v : signed (2 downto 0);
                 a_h : signed (2 downto 0);
                 b_h : signed (2 downto 0);
                 c_h : signed (2 downto 0));
        Port ( clk : in STD_LOGIC;
               rst : in std_logic;
               in1 : in unsigned (N - 1 downto 0);
               in2 : in unsigned (N - 1 downto 0);
               in3 : in unsigned (N - 1 downto 0);
               dout: out unsigned (N - 1 downto 0));
    end component filter_mask_3x3;
    
    signal fval_int : std_logic_vector (0 to 1*(LINE_WIDTH-1) + 8);
    signal lval_int : std_logic_vector (0 to 1*(LINE_WIDTH-1) + 8);
               
    signal read_addr : unsigned (ADDRESS_BUS_WIDTH - 1 downto 0);
    signal write_addr: unsigned (ADDRESS_BUS_WIDTH - 1 downto 0);
    signal din   : unsigned (N-1 downto 0);
    signal tap_1 : unsigned (N-1 downto 0);
    signal tap_2 : unsigned (N-1 downto 0);
    signal d_horz: unsigned (N-1 downto 0);
    signal d_vert: unsigned (N-1 downto 0);
    signal d_sum : unsigned (N downto 0);
                  
begin
    ----------------------------------------------------------------------------
    ---------------------- Line Buffer Components ------------------------------
    ----------------------------------------------------------------------------

    -- Conditional Generate
    SimSize:
    if(LINE_WIDTH = 5) GENERATE         -- If Line Width Is 5 gen 4 depth buffs
    line_buff_1 : line_buff_4 port map (clka => clk, clkb => clk, rsta => rst,
                                          rstb => rst, wea => '0', web => '1',
                                          addra => read_addr, 
                                          addrb => write_addr,
                                          dina => din, dinb => din, 
                                          douta => tap_1, doutb => open);
    line_buff_2 : line_buff_4 port map (clka => clk, clkb => clk, rsta => rst,
                                          rstb => rst, wea => '0', web => '1',
                                          addra => read_addr, 
                                          addrb => write_addr,
                                          dina => tap_1, dinb => tap_1, 
                                          douta => tap_2, doutb => open);
     END GENERATE;                                     
                                          
     Line_160_size:
     if(LINE_WIDTH = 160) GENERATE          -- If Line Width is 160 gen 159 depth buffs
     line_buff_1 : line_buff_159 port map (clka => clk, clkb => clk, rsta => rst,
                                           rstb => rst, wea => '0', web => '1',
                                           addra => read_addr, 
                                           addrb => write_addr,
                                           dina => din, dinb => din, 
                                           douta => tap_1, doutb => open);
     line_buff_2 : line_buff_159 port map (clka => clk, clkb => clk, rsta => rst,
                                           rstb => rst, wea => '0', web => '1',
                                           addra => read_addr, 
                                           addrb => write_addr,
                                           dina => tap_1, dinb => tap_1, 
                                           douta => tap_2, doutb => open);
      END GENERATE;                                          

     Line_176_size:
     if(LINE_WIDTH = 176) GENERATE          -- If Line Width is 160 gen 159 depth buffs
     line_buff_1 : line_buff_175 port map (clka => clk, clkb => clk, rsta => rst,
                                           rstb => rst, wea => '0', web => '1',
                                           addra => read_addr, 
                                           addrb => write_addr,
                                           dina => din, dinb => din, 
                                           douta => tap_1, doutb => open);
     line_buff_2 : line_buff_175 port map (clka => clk, clkb => clk, rsta => rst,
                                           rstb => rst, wea => '0', web => '1',
                                           addra => read_addr, 
                                           addrb => write_addr,
                                           dina => tap_1, dinb => tap_1, 
                                           douta => tap_2, doutb => open);
      END GENERATE;
    
    horz_filter : filter_mask_3x3 generic map (N => N,
                                               a_v => "001", b_v => "010", c_v =>"001",
                                               a_h => "001", b_h =>"000", c_h =>"111")
                                  port map (clk => clk, rst => rst, 
                                            in1 => din,
                                            in2 => tap_1,
                                            in3 => tap_2,
                                            dout => d_horz);
                                            
    vert_filter : filter_mask_3x3 generic map (N => N,
                                               a_v => "001", b_v => "000", c_v =>"111",
                                               a_h => "001", b_h =>"010", c_h =>"001")
                                  port map (clk => clk, rst => rst, 
                                            in1 => din,
                                            in2 => tap_1,
                                            in3 => tap_2,
                                            dout => d_vert);                                            
    
    ----------------------------------------------------------------------------
    ---------------------- I/O and Address Counters ----------------------------
    ----------------------------------------------------------------------------    
    
    -- Input Capture
    clkin:
    process (clk, rst) is
    begin
        if(rst = '1') then
            din <= (others => '0');
        elsif rising_edge(clk) then
            din <= d_in;
        end if;
    end process clkin;
    
    -- Output
    output: 
    process (clk, rst) is
    begin
        if(rst = '1') then
            horz_out <= (others => '0');
            vert_out <= (others => '0');
            sum_out <= (others => '0');
        elsif rising_edge(clk) then
            horz_out <= d_horz;
            vert_out <= d_vert;
            -- Sum Vert and Horz Divide-by-2
            sum_out <= d_sum(N downto 1);   --TODO: Implement max(Gx,Gy) + min(Gx, Gy)/4 Approx
        end if;
    end process output;
   d_sum <= resize(d_horz, d_sum'length) + resize(d_vert, d_sum'length);
   
    -- Circular Address Counter
    addr_count: 
    process (clk, rst) is
        variable cntA : unsigned (ADDRESS_BUS_WIDTH-1 downto 0) := (others => '0');
        variable cntB : unsigned (ADDRESS_BUS_WIDTH-1 downto 0) := (others => '0');
    begin
        if(rst = '1') then
            cntB := (others => '0');
            cntA := (others => '0');
            write_addr <= (others => '0');
            read_addr <= (others => '0');
        elsif rising_edge(clk) then
            cntB := cntA + 1;
            if (cntB = LINE_WIDTH-1) then
                cntB := (others => '0');
            end if;
                
        write_addr <= cntA;
        read_addr  <= cntB;
                
        cntA := cntA + 1;
            if (cntA = LINE_WIDTH-1) then
                cntA := (others => '0');
            end if;
        end if;
    end process addr_count; 
    
    -- Valid Signal
    validate:
    process (clk, rst) is
    begin
        if(rst = '1') then
            fval_int <= (others => '0');
            lval_int <= (others => '0');
        elsif rising_edge(clk) then
            fval_int <= fval_in & fval_int(0 to fval_int'length -2);
            lval_int <= lval_in & lval_int(0 to lval_int'length -2);
        end if;
    end process validate;
    fval_out <= fval_int(fval_int'length-1);
    lval_out <= lval_int(lval_int'length-1);
    
end Behavioral;
