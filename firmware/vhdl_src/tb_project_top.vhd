--------------------------------------------
-- ECE-6276-Q : DSP HARDWARE SYSTEMS
--------------------------------------------
-- DISTANCE LEARNING STUDENTS
--    GREGORY WALLS
--    BRYCE WILLIAMS
--    ZACHARY BOE
--    BENJAMIN SULLINS - GTID: 903232988
--------------------------------------------
-- SCHOOL OF ELECTRICAL AND COMPUTER ENGINEERING 
-- GEORGIA INSTIUTE OF TECHNOLOGY 
--------------------------------------------
-- FINAL PROJECT - TESTBENCH
--------------------------------------------
-- REFERENCES
-- ----
--------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;
  USE IEEE.MATH_REAL.ALL;
  USE STD.ENV.ALL;
  USE STD.TEXTIO.ALL;
  USE IEEE.STD_LOGIC_TEXTIO.ALL;

ENTITY TB_FILTER IS
END TB_FILTER;

ARCHITECTURE TB_FILTER_ARCH OF TB_FILTER IS

   COMPONENT PROJECT_TOP IS
   PORT(
      CLK         : IN STD_LOGIC;
      RST         : IN STD_LOGIC;
      SW          : IN STD_LOGIC_VECTOR(5 DOWNTO 0);

      LED         : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
      HSYNC       : OUT STD_LOGIC;
      VSYNC       : OUT STD_LOGIC;
      VGARED      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      VGABLUE     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      VGAGREEN    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
   );
   END COMPONENT;

   SIGNAL CLK      : STD_LOGIC;
   SIGNAL RST      : STD_LOGIC := '1';
   SIGNAL SW       : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";

   SIGNAL LED      : STD_LOGIC_VECTOR(5 DOWNTO 0);
   SIGNAL HSYNC    : STD_LOGIC;
   SIGNAL VSYNC    : STD_LOGIC;
   SIGNAL VGARED   : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL VGABLUE  : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL VGAGREEN : STD_LOGIC_VECTOR(3 DOWNTO 0);

   CONSTANT T        : TIME := 10 NS;

BEGIN

   -----------------------------------------------------------------
   -- CLOCK INPUT
   -----------------------------------------------------------------
   -- NOTES: THIS IS THE ONBOARD CLOCK
   -----------------------------------------------------------------
   PROCESS 
    BEGIN
        CLK <= '0';
        WAIT FOR T/2;
        CLK <= '1';
        WAIT FOR T/2;
    END PROCESS;

    -----------------------------------------------------------------
    -- RESET
    -----------------------------------------------------------------
    -- NOTES: THIS WILL COME FROM A BUTTON
    -----------------------------------------------------------------
    RST <= '1', '0' AFTER 1000 NS;

   -----------------------------------------------------------------
   -- DUT INSTANTIATION
   -----------------------------------------------------------------
   DUT : PROJECT_TOP
   PORT MAP(
      CLK      => CLK,     
      RST      => RST,
      SW       => SW,

      LED      => LED,
      HSYNC    => HSYNC,
      VSYNC    => VSYNC,
      VGARED   => VGARED,
      VGABLUE  => VGABLUE,
      VGAGREEN => VGAGREEN

   );

END TB_FILTER_ARCH;
