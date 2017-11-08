----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Bryce Williams
-- 
-- Create Date: 11/08/2017 04:17:07 AM
-- Design Name: 
-- Module Name: tb_filter_mask_3x3 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Test bench for 3x3 Matrix Mult Filter Mask
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

entity tb_filter_mask_3x3 is
end tb_filter_mask_3x3;

architecture Behavioral of tb_filter_mask_3x3 is
    component filter_mask_3x3 is
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
    end component filter_mask_3x3;

    constant T: time := 20 ns;

    signal clk_int : std_logic;
    signal din: std_logic_vector (7 downto 0)   := "00001011";
    signal tap_1: std_logic_vector (7 downto 0) := "00000110";
    signal tap_2: std_logic_vector (7 downto 0) := "00000001";
    signal d_horz: std_logic_vector (7 downto 0);
    signal cnt : natural := 0;

begin
    horz_filter : filter_mask_3x3 generic map (N => 8,
                                           a_v => "001", b_v => "010", c_v =>"001",
                                           a_h => "111", b_h =>"000", c_h =>"001")
                              port map (clk => clk_int, rst => '0', 
                                        in1 => din,
                                        in2 => tap_1,
                                        in3 => tap_2,
                                        dout => d_horz);
    
    clkgen: 
    process is 
    begin
        clk_int <= '1';
        wait for T/2;
        clk_int <= '0';
        wait for T/2;
    end process; 

    clkcnt:
    process (clk_int) is
    begin
        if rising_edge(clk_int) then
         cnt <= cnt + 1;
        end if;
    end process;

    r_w_buff:
    process (clk_int) is
    begin
        if rising_edge(clk_int) then
            din <= din + 1;
            tap_1 <= tap_1 + 1;
            tap_2 <= tap_2 + 1;
        end if;
    end process;
end Behavioral;