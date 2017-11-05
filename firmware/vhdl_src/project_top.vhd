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
-- FINAL PROJECT - VGA TRANSPOSE AND EDGE DETECTION
--------------------------------------------
-- REFERENCES
-- ----
--------------------------------------------

LIBRARY IEEE;
   USE IEEE.STD_LOGIC_1164.ALL;
   USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
   USE WORK.GENERIC_UTILITIES.ALL;

ENTITY PROJECT_TOP IS
PORT(
   CLK          : IN STD_LOGIC;
   RST          : IN STD_LOGIC
);
END PROJECT_TOP;

ARCHITECTURE PROJECT_TOP_ARCH OF PROJECT_TOP IS

   -----------------------------------------------------------------
   -- FAKE CAMERA CONFIGURATION
   -----------------------------------------------------------------
   -- NOTES: I'VE SET THE INTEGRATION TIME TO BE SOMETHING VERY SMALL.
   --        THIS WOULD TRANSLATE TO A VERY HIGH FRAME RATE, BUT FOR
   --        SIMULATION SAKE, IT'S KEEP SMALL.
   -----------------------------------------------------------------
   CONSTANT VIDEO_BITS     : NATURAL :=    8; -- VIDEO DYNAMIC RANGE
   CONSTANT VIDEO_VPIX     : NATURAL :=  320; -- VALID PIXELS PER LINE
   CONSTANT VIDEO_VLIN     : NATURAL :=  240; -- VALID LINES
   CONSTANT VIDEO_IPIX     : NATURAL :=   16; -- INVALID PIXELS PER LINE
   CONSTANT VIDEO_INT_TIME : NATURAL := 1000; -- INVALID PIXELS PER FRAME

   -----------------------------------------------------------------
   -- FAKE CAMERA SIGNALS
   -----------------------------------------------------------------
   SIGNAL FAKE_CAMERA_CLK  : STD_LOGIC;
   SIGNAL FAKE_CAMERA_RST  : STD_LOGIC;
   SIGNAL FAKE_CAMERA_FVAL : STD_LOGIC;
   SIGNAL FAKE_CAMERA_LVAL : STD_LOGIC;
   SIGNAL FAKE_CAMERA_DATA : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);

BEGIN

   --INSTANTIATION OF THE 
   TP_GENERATOR: ENTITY WORK.FAKE_CAMERA
   GENERIC MAP(
      VIDEO_BITS     => VIDEO_BITS,       
      VIDEO_VPIX     => VIDEO_VPIX,       
      VIDEO_VLIN     => VIDEO_VLIN,       
      VIDEO_IPIX     => VIDEO_IPIX,       
      VIDEO_INT_TIME => VIDEO_INT_TIME    
   )
   PORT MAP(
      CLK         => FAKE_CAMERA_CLK,
      RST         => FAKE_CAMERA_RST,
      FVAL_OUT    => FAKE_CAMERA_FVAL,
      LVAL_OUT    => FAKE_CAMERA_LVAL,
      DATA_OUT    => FAKE_CAMERA_DATA
   );

   FAKE_CAMERA_CLK <= CLK;
   FAKE_CAMERA_RST <= RST;

   --INSTANTIATION OF THE 
   -- TRANSPOSE: ENTITY WORK.VIDEO_TRANSPOSE
   -- GENERIC MAP(
   --    VIDEO_VPIX  => VIDEO_VPIX,
   --    VIDEO_VLIN  => VIDEO_VLIN,
   --    VIDEO_IPIX  => VIDEO_IPIX
   -- )
   -- PORT MAP(
   --    CLK         => CLK,
   --    RST         => RST
   -- );

   --INSTANTIATION OF THE 
   -- EDGE_DETECTION: ENTITY WORK.VIDEO_EDGE_DETECTION
   -- GENERIC MAP(
   --    VIDEO_VPIX  => VIDEO_VPIX,
   --    VIDEO_VLIN  => VIDEO_VLIN,
   --    VIDEO_IPIX  => VIDEO_IPIX
   -- )
   -- PORT MAP(
   --    CLK         => CLK,
   --    RST         => RST
   -- );

   --INSTANTIATION OF THE 
   -- VGA_OUTPUT: ENTITY WORK.VIDEO_VGA_CONVERTER
   -- GENERIC MAP(
   --    VIDEO_VPIX  => VIDEO_VPIX,
   --    VIDEO_VLIN  => VIDEO_VLIN,
   --    VIDEO_IPIX  => VIDEO_IPIX
   -- )
   -- PORT MAP(
   --    CLK         => CLK,
   --    RST         => RST
   -- );

END PROJECT_TOP_ARCH;
