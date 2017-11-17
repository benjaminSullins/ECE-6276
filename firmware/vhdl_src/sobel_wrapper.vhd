----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Bryce Williams
-- 
-- Create Date: 11/15/2017 02:53:54 PM
-- Design Name: 
-- Module Name: sobel_wrapper - structural
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Wrapper for Sobel Filter, muxes outputs from the sobel filter
-- and provides a pass-thru option
-- 
-- Dependencies: 
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

entity sobel_wrapper is
    Generic(N : natural := 8;                   -- Data Width 
            LINE_WIDTH : natural := 160;        -- Image Line Width (5 or 160)
            ADDRESS_BUS_WIDTH : natural := 8    -- FIFO Address Width
            );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           fval_in : in STD_LOGIC;
           lval_in : in STD_LOGIC;
           data_in : in UNSIGNED (N-1 downto 0);
           sel     : in STD_LOGIC_VECTOR (1 downto 0);
           
           fval_out : out STD_LOGIC;
           lval_out : out STD_LOGIC;
           data_out : out UNSIGNED (7 downto 0));
end sobel_wrapper;

architecture structural of sobel_wrapper is

    component sobel is
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
    end component sobel;
    
    signal fval_sobel_out : std_logic;
    signal lval_sobel_out : std_logic;
    
    signal v_out_int : unsigned (N-1 downto 0);
    signal h_out_int : unsigned (N-1 downto 0);
    signal s_out_int : unsigned (N-1 downto 0);    
    
begin

    sobel_top : sobel generic map(N => N, LINE_WIDTH => LINE_WIDTH, 
                                  ADDRESS_BUS_WIDTH => ADDRESS_BUS_WIDTH)
                      port map(clk => clk, rst => rst, fval_in => fval_in, lval_in => lval_in,
                               fval_out => fval_sobel_out, lval_out => lval_sobel_out, 
                               d_in => data_in, vert_out => v_out_int, 
                               horz_out => h_out_int, sum_out => s_out_int);
    
    mux2t1_fval: fval_out <= fval_in when sel = "00" else fval_sobel_out;
                 lval_out <= lval_in when sel = "00" else lval_sobel_out;   
                    
    mux4t1: with sel select
        data_out <= s_out_int   when "01",
                    v_out_int   when "10",
                    h_out_int   when "11",
                    data_in     when others;

end structural;
