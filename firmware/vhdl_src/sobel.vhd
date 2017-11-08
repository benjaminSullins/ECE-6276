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
    Generic(N : natural := 8);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           d_in : in STD_LOGIC_VECTOR (7 downto 0);
           fval_in : in STD_LOGIC;
           lval_in : in STD_LOGIC;
           d_out : out STD_LOGIC_VECTOR (7 downto 0);
           fval_out : out STD_LOGIC;
           lval_out : out STD_LOGIC);
end sobel;

architecture Behavioral of sobel is
    component line_buff_240 is
        Port ( 
               clka : in std_logic;
               clkb : in std_logic;
               rsta : in std_logic;
               rstb : in std_logic;
               wea  : in std_logic;
               web  : in std_logic;
               addra: in std_logic_vector (2 downto 0);
               addrb: in std_logic_vector (2 downto 0);
               dina : in std_logic_vector (7 downto 0) := (others => '1'); 
               dinb : in std_logic_vector (7 downto 0);
               douta: out std_logic_vector (7 downto 0);
               doutb: out std_logic_vector (7 downto 0) := (others => '1')
              );   
    end component line_buff_240;
    
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
               in1 : in STD_LOGIC_VECTOR (N - 1 downto 0);
               in2 : in STD_LOGIC_VECTOR (N - 1 downto 0);
               in3 : in STD_LOGIC_VECTOR (N - 1 downto 0);
               dout : out STD_LOGIC_VECTOR (N - 1 downto 0));
    end component filter_mask_3x3;
    
    constant line_buffer_depth : natural := 4;

--    signal cntA      : unsigned (7 downto 0) := (others => '0');
--    signal cntB      : unsigned (7 downto 0) := (others => '0');              
    signal read_addr : std_logic_vector (2 downto 0);
    signal write_addr: std_logic_vector (2 downto 0);
    signal din   : std_logic_vector (N-1 downto 0);
    signal tap_1 : std_logic_vector (N-1 downto 0);
    signal tap_2 : std_logic_vector (N-1 downto 0);
    signal d_horz: std_logic_vector (N-1 downto 0);
                  
begin
    ----------------------------------------------------------------------------
    ---------------------- Line Buffer Components ------------------------------
    ----------------------------------------------------------------------------
    line_buff_1 : line_buff_240 port map (clka => clk, clkb => clk, rsta => rst,
                                          rstb => rst, wea => '0', web => '1',
                                          addra => read_addr, 
                                          addrb => write_addr,
                                          dina => din, dinb => din, 
                                          douta => tap_1, doutb => open);
    line_buff_2 : line_buff_240 port map (clka => clk, clkb => clk, rsta => rst,
                                          rstb => rst, wea => '0', web => '1',
                                          addra => read_addr, 
                                          addrb => write_addr,
                                          dina => tap_1, dinb => tap_1, 
                                          douta => tap_2, doutb => open);
    
    horz_filter : filter_mask_3x3 generic map (N => N,
                                               a_v => "001", b_v => "010", c_v =>"001",
                                               a_h => "111", b_h =>"000", c_h =>"001")
                                  port map (clk => clk, rst => rst, 
                                            in1 => din,
                                            in2 => tap_1,
                                            in3 => tap_2,
                                            dout => d_horz);
    
    d_out <= d_horz;
    
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
    
    -- Circular Address Counter
    addr_count: 
        process (clk, rst) is
            variable cntA : unsigned (2 downto 0) := (others => '0');
            variable cntB : unsigned (2 downto 0) := (others => '0');
        begin
            if(rst = '1') then
                cntB := (others => '0');
                cntA := (others => '0');
            elsif rising_edge(clk) then
                cntB := cntA + 1;
                if (cntB = line_buffer_depth) then
                    cntB := (others => '0');
                end if;
                
                write_addr <= std_logic_vector(cntA);
                read_addr  <= std_logic_vector(cntB);
                
                cntA := cntA + 1;
                if (cntA = line_buffer_depth) then
                    cntA := (others => '0');
                end if;
            end if;
        end process addr_count; 

end Behavioral;
