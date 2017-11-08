----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Bryce Williams
-- 
-- Create Date: 11/08/2017 04:17:07 AM
-- Design Name: 
-- Module Name: filter_mask_3x3 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Implements a 3x3 Matrix Mult Filter Mask
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
USE IEEE.STD_LOGIC_SIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity filter_mask_3x3 is
    Generic( N : natural := 8;
             a_v : signed (2 downto 0) := "010";
             b_v : signed (2 downto 0) := "010";
             c_v : signed (2 downto 0) := "010";
             a_h : signed (2 downto 0) := "010";
             b_h : signed (2 downto 0) := "001";
             c_h : signed (2 downto 0) := "101");
    Port ( clk : in STD_LOGIC;
           rst : in std_logic;
           in1 : in STD_LOGIC_VECTOR (N - 1 downto 0);
           in2 : in STD_LOGIC_VECTOR (N - 1 downto 0);
           in3 : in STD_LOGIC_VECTOR (N - 1 downto 0);
           dout : out STD_LOGIC_VECTOR (N - 1 downto 0));
end filter_mask_3x3;

architecture Behavioral of filter_mask_3x3 is
 
    signal mult_a_v : signed (N+2 downto 0);
    signal mult_b_v : signed (N+2 downto 0);
    signal mult_c_v : signed (N+2 downto 0);
    signal sum_v    : signed (N+3 downto 0);
    
    signal mult_a_h : signed (N+6 downto 0);
    signal mult_b_h : signed (N+6 downto 0);
    signal mult_c_h : signed (N+6 downto 0);
    signal sum_h1   : signed (N+7 downto 0);
    signal sum_h2   : signed (N+8 downto 0);
    
    signal d_dly1   : signed (N+6 downto 0);
    signal d_dly2   : signed (N+7 downto 0);
    
    signal dout_int : signed (N+8 downto 0);
    
begin

    -- Math operations
    mult_a_v <= signed(in1) * a_v;
    mult_b_v <= signed(in2) * b_v;
    mult_c_v <= signed(in3) * c_v;
    sum_v <= resize(mult_a_v, mult_a_v'length + 1) + 
             resize(mult_b_v, mult_b_v'length + 1) + 
             resize(mult_c_v, mult_c_v'length + 1);
   
    mult_a_h <= sum_v * a_h;
    mult_b_h <= sum_v * b_h;
    mult_c_h <= sum_v * c_h;
    sum_h1   <= resize(d_dly1, d_dly1'length + 1) + resize(mult_b_h, mult_b_h'length + 1);
    sum_h2   <= resize(d_dly2, d_dly2'length + 1) + resize(mult_c_h, mult_c_h'length + 1);
    
    -- Delay Capture
    datadelay:
    process (clk, rst) is
    begin
        if(rst = '1') then
            d_dly1 <= (others => '0');
            d_dly2 <= (others => '0');
        elsif rising_edge(clk) then 
            d_dly1 <= mult_a_h;
            d_dly2 <= sum_h1;
        end if;
    end process datadelay;
    
    -- Output Capture
        clkout:
        process (clk, rst) is
        begin
            if(rst = '1') then
                dout_int <= (others => '0');
            elsif rising_edge(clk) then 
                dout_int <= abs(resize(d_dly2, d_dly2'length + 1) + resize(mult_c_h, d_dly2'length + 1));
            end if;
        end process clkout;
    
    -- Assign Output 
    dout <= std_logic_vector(dout_int(7 downto 0));
end Behavioral;
