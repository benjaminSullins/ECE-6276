----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Bryce Williams :)
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
           in1 : in unsigned (N - 1 downto 0);
           in2 : in unsigned (N - 1 downto 0);
           in3 : in unsigned (N - 1 downto 0);
           dout : out unsigned (N - 1 downto 0));
end filter_mask_3x3;

architecture Behavioral of filter_mask_3x3 is
 
    signal multAv   : signed (N+3 downto 0);    -- 12-bit
    signal multBv   : signed (N+3 downto 0);    -- 12-bit
    signal multCv   : signed (N+3 downto 0);    -- 12-bit
    signal sumV     : signed (N+4 downto 0);    -- 13-bit
    
    signal multAh   : signed (N+7 downto 0);    --16-bit
    signal multBh   : signed (N+7 downto 0);    --16-bit
    signal multCh   : signed (N+7 downto 0);    --16-bit
    signal lineDly1 : signed (N+7 downto 0);    --16-bit
    
    signal sumh1    : signed (N+8 downto 0);    --17-bit
    
    signal sumh2    : signed (N+9 downto 0);    --18-bit
    signal dout_int : unsigned (N+9 downto 0);  --18-bit
    
    constant M      : natural := dout_int'length;
   
begin

    -- Math operations and line delays
    clkmath:
    process (clk, rst) is
    begin
        if(rst = '1') then
            multAv  <= (others => '0');
            multBv  <= (others => '0');
            multCv  <= (others => '0');
            sumV    <= (others => '0');
            
            multAh  <= (others => '0');
            multBh  <= (others => '0');
            multCh  <= (others => '0');
            
            lineDly1 <= (others => '0');
            
            sumh1    <= (others => '0');
            sumh2    <= (others => '0');
            
            dout_int <= (others => '0');  
        elsif rising_edge(clk) then
            multAv  <= signed(resize(in1,9)) * a_v;
            multBv  <= signed(resize(in2, 9)) * b_v;
            multCv  <= signed(resize(in3, 9)) * c_v;
            sumV    <= resize(multAv, sumV'length)+
                       resize(multBv, sumV'length)+ 
                       resize(multCv, sumV'length);
            
            multAh  <= sumV * a_h;
            multBh  <= sumV * b_h;
            multCh  <= sumV * c_h;
            
            lineDly1 <= multAh;
            
            sumh1    <= resize(lineDly1, sumh1'length) + 
                        resize(multBh, sumh1'length);
            sumh2    <= resize(sumh1, sumh2'length) + 
                        resize(multCh, sumh2'length);
            
            dout_int <= unsigned(abs(sumh2));
        end if;
    end process clkmath;
    
    
    -- Saturation Logic and Output
        clkout:
        process (clk, rst) is
            variable MSbs : unsigned (M-N-1 downto 0);
        begin
            if(rst = '1') then
                dout <= (others => '0');
            elsif rising_edge(clk) then 
                MSbs := dout_int(M-1 downto N);
                if(MSbs = 0) then          -- No overflow
                    dout <= dout_int(N-1 downto 0);
                else                                 -- Overflow
                    dout <= "11111111";              -- Saturate
                end if;
            end if;
        end process clkout;
end Behavioral;
