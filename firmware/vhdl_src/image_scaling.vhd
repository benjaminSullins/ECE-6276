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
-- IMAGE SCALING
--------------------------------------------
-- REFERENCES
-- ----
--------------------------------------------

LIBRARY IEEE;
   USE IEEE.STD_LOGIC_1164.ALL;
   USE IEEE.STD_LOGIC_UNSIGNED.ALL;
   USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
   USE WORK.GENERIC_UTILITIES.ALL;

ENTITY IMAGE_SCALING IS
GENERIC(
   VIDEO_IN_BITS  : NATURAL := 8;    -- VIDEO DYNAMIC RANGE
   VIDEO_OUT_BITS : NATURAL := 4     -- VALID PIXELS PER LINE
);
PORT(
   CLK            : IN STD_LOGIC;
   RST            : IN STD_LOGIC;

   FVAL_IN        : IN STD_LOGIC;
   LVAL_IN        : IN STD_LOGIC;
   DATA_IN        : IN STD_LOGIC_VECTOR(VIDEO_IN_BITS - 1 DOWNTO 0);

   FVAL_OUT       : OUT STD_LOGIC;
   LVAL_OUT       : OUT STD_LOGIC;
   DATA_OUT       : OUT STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0)

);
END IMAGE_SCALING;

ARCHITECTURE IMAGE_SCALING_ARCH OF IMAGE_SCALING IS

   -----------------------------------------------------------------
   -- SIGNALS
   -----------------------------------------------------------------

BEGIN

   -----------------------------------------------------------------
   -- STATE MACHINE
   -----------------------------------------------------------------
   FVAL_OUT <= FVAL_IN;
   LVAL_OUT <= LVAL_IN;
   DATA_OUT <= DATA_IN(VIDEO_IN_BITS - 1 DOWNTO VIDEO_IN_BITS - VIDEO_OUT_BITS);

END IMAGE_SCALING_ARCH;
