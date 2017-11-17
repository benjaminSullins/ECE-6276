----------------------------------------------------------------------------------
-- COMPANY: 
-- ENGINEER: BRYCE WILLIAMS
-- 
-- CREATE DATE: 11/15/2017 02:53:54 PM
-- DESIGN NAME: 
-- MODULE NAME: SOBEL_WRAPPER - STRUCTURAL
-- PROJECT NAME: 
-- TARGET DEVICES: 
-- TOOL VERSIONS: 
-- DESCRIPTION: WRAPPER FOR SOBEL FILTER, MUXES OUTPUTS FROM THE SOBEL FILTER
-- AND PROVIDES A PASS-THRU OPTION
-- 
-- DEPENDENCIES: 
-- 
-- REVISION:
-- REVISION 0.01 - FILE CREATED
-- ADDITIONAL COMMENTS:
-- 
----------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- UNCOMMENT THE FOLLOWING LIBRARY DECLARATION IF USING
-- ARITHMETIC FUNCTIONS WITH SIGNED OR UNSIGNED VALUES
USE IEEE.NUMERIC_STD.ALL;

-- UNCOMMENT THE FOLLOWING LIBRARY DECLARATION IF INSTANTIATING
-- ANY XILINX LEAF CELLS IN THIS CODE.
--LIBRARY UNISIM;
--USE UNISIM.VCOMPONENTS.ALL;

ENTITY SOBEL_WRAPPER IS
GENERIC(
  N                  : NATURAL :=   8; -- DATA WIDTH 
  LINE_WIDTH         : NATURAL := 160; -- IMAGE LINE WIDTH (5 OR 160)
  ADDRESS_BUS_WIDTH  : NATURAL :=   8  -- FIFO ADDRESS WIDTH
);
PORT( 
   CLK      : IN STD_LOGIC;
   RST      : IN STD_LOGIC;
   
   FVAL_IN  : IN STD_LOGIC;
   LVAL_IN  : IN STD_LOGIC;
   DATA_IN  : IN STD_LOGIC_VECTOR (N-1 DOWNTO 0);
   SEL      : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   
   FVAL_OUT : OUT STD_LOGIC;
   LVAL_OUT : OUT STD_LOGIC;
   DATA_OUT : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
END SOBEL_WRAPPER;

ARCHITECTURE STRUCTURAL OF SOBEL_WRAPPER IS

   COMPONENT SOBEL IS
   GENERIC(
      N                 : NATURAL := 8;                   -- DATA WIDTH 
      LINE_WIDTH        : NATURAL := 160;        -- IMAGE LINE WIDTH (5 OR 160)
      ADDRESS_BUS_WIDTH : NATURAL := 8    -- FIFO ADDRESS WIDTH
   );          
   PORT( 
      CLK      : IN STD_LOGIC;
      RST      : IN STD_LOGIC;
      FVAL_IN  : IN STD_LOGIC :='0';
      LVAL_IN  : IN STD_LOGIC :='0';
      D_IN     : IN UNSIGNED (N-1 DOWNTO 0);
   
      FVAL_OUT : OUT STD_LOGIC :='0';
      LVAL_OUT : OUT STD_LOGIC :='0';
      VERT_OUT : OUT UNSIGNED (7 DOWNTO 0);
      HORZ_OUT : OUT UNSIGNED (7 DOWNTO 0);
      SUM_OUT  : OUT UNSIGNED (7 DOWNTO 0)
   );
   END COMPONENT SOBEL;

   SIGNAL FVAL_SOBEL_OUT : STD_LOGIC;
   SIGNAL LVAL_SOBEL_OUT : STD_LOGIC;

   SIGNAL V_OUT_INT : UNSIGNED (N-1 DOWNTO 0);
   SIGNAL H_OUT_INT : UNSIGNED (N-1 DOWNTO 0);
   SIGNAL S_OUT_INT : UNSIGNED (N-1 DOWNTO 0);    
    
BEGIN

    SOBEL_TOP : SOBEL 
    GENERIC MAP(
      N                 => N, 
      LINE_WIDTH        => LINE_WIDTH, 
      ADDRESS_BUS_WIDTH => ADDRESS_BUS_WIDTH
   )
   PORT MAP(
      CLK      => CLK, 
      RST      => RST, 
      FVAL_IN  => FVAL_IN, 
      LVAL_IN  => LVAL_IN,
      FVAL_OUT => FVAL_SOBEL_OUT, 
      LVAL_OUT => LVAL_SOBEL_OUT, 
      D_IN     => UNSIGNED(DATA_IN), 
      VERT_OUT => V_OUT_INT, 
      HORZ_OUT => H_OUT_INT, 
      SUM_OUT  => S_OUT_INT
   );
    
    MUX2T1_FVAL: FVAL_OUT <= FVAL_IN WHEN SEL = "00" ELSE FVAL_SOBEL_OUT;
                 LVAL_OUT <= LVAL_IN WHEN SEL = "00" ELSE LVAL_SOBEL_OUT;   
                    
    MUX4T1: WITH SEL SELECT
        DATA_OUT <= STD_LOGIC_VECTOR(S_OUT_INT)   WHEN "01",
                    STD_LOGIC_VECTOR(V_OUT_INT)   WHEN "10",
                    STD_LOGIC_VECTOR(H_OUT_INT)   WHEN "11",
                                     DATA_IN      WHEN OTHERS;

END STRUCTURAL;