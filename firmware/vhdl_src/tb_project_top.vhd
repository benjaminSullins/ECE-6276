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
      CLK        : IN STD_LOGIC;
      RST        : IN STD_LOGIC
   );
   END COMPONENT;

   SIGNAL   CLK      : STD_LOGIC;
   SIGNAL   RST      : STD_LOGIC := '1';

   CONSTANT T        : TIME := 200 NS;

BEGIN

   -----------------------------------------------------------------
   -- CLOCK INPUT
   -----------------------------------------------------------------
   -- NOTES: THIS WILL EVENTUALLY BE REPLACED BY A CLOCK 
   --        GENERATOR (DCM).
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
    -- NOTES: THIS WILL COME FROM THE DCM AS WELL
    -----------------------------------------------------------------
    RST <= '1', '0' AFTER 1000 NS;

   -----------------------------------------------------------------
   -- DUT INSTANTIATION
   -----------------------------------------------------------------
   DUT : PROJECT_TOP
   PORT MAP(
      CLK     => CLK,     
      RST     => RST
   );

END TB_FILTER_ARCH;
