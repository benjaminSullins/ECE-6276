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
   CLK         : IN  STD_LOGIC;
   RST         : IN  STD_LOGIC;
   SW          : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);

   LED         : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
   HSYNC       : OUT STD_LOGIC;
   VSYNC       : OUT STD_LOGIC;
   VGARED      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
   VGABLUE     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
   VGAGREEN    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
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
   CONSTANT VIDEO_VPIX     : NATURAL :=  160; -- VALID PIXELS PER LINE
   CONSTANT VIDEO_VLIN     : NATURAL :=  120; -- VALID LINES
   CONSTANT VIDEO_IPIX     : NATURAL :=   16; -- INVALID PIXELS PER LINE
   CONSTANT VIDEO_INT_TIME : NATURAL :=  500; -- INVALID PIXELS PER FRAME

   -----------------------------------------------------------------
   -- CLOCK GENERATOR SIGNALS
   -----------------------------------------------------------------
   COMPONENT CLOCK_GENERATOR
   PORT(
      CLK_IN1           : IN     STD_LOGIC;
      RESET             : IN     STD_LOGIC;
      LOCKED            : OUT    STD_LOGIC;
      CLK_OUT1          : OUT    STD_LOGIC;
      CLK_OUT2          : OUT    STD_LOGIC
   );
   END COMPONENT;

   SIGNAL LOCKED           : STD_LOGIC;

   -----------------------------------------------------------------
   -- FAKE CAMERA SIGNALS
   -----------------------------------------------------------------
   SIGNAL FAKE_CAMERA_CLK  : STD_LOGIC;
   SIGNAL FAKE_CAMERA_RST  : STD_LOGIC;
   SIGNAL FAKE_CAMERA_FVAL : STD_LOGIC;
   SIGNAL FAKE_CAMERA_LVAL : STD_LOGIC;
   SIGNAL FAKE_CAMERA_DATA : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   ALIAS  FAKE_CAMERA_SLCT : STD_LOGIC_VECTOR(1 DOWNTO 0) IS SW(1 DOWNTO 0);

   -----------------------------------------------------------------
   -- TRANSPOSE SIGNALS
   -----------------------------------------------------------------
   SIGNAL TRANSPOSE_FVAL   : STD_LOGIC;
   SIGNAL TRANSPOSE_LVAL   : STD_LOGIC;
   SIGNAL TRANSPOSE_DATA   : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   ALIAS  TRANSPOSE_SLCT   : STD_LOGIC IS SW(2);

   -----------------------------------------------------------------
   -- TRANSPOSE SIGNALS
   -----------------------------------------------------------------
   SIGNAL SOBEL_FVAL    : STD_LOGIC;
   SIGNAL SOBEL_LVAL    : STD_LOGIC;
   SIGNAL SOBEL_DATA    : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   ALIAS  SOBEL_SLCT    : STD_LOGIC_VECTOR(1 DOWNTO 0) IS SW(4 DOWNTO 3);

   -----------------------------------------------------------------
   -- TRANSPOSE SIGNALS
   -----------------------------------------------------------------
   CONSTANT VGA_BITS       : NATURAL := VGARED'LENGTH;
   SIGNAL IMG_SCALING_FVAL : STD_LOGIC;
   SIGNAL IMG_SCALING_LVAL : STD_LOGIC;
   SIGNAL IMG_SCALING_DATA : STD_LOGIC_VECTOR(VGA_BITS - 1 DOWNTO 0);

   -----------------------------------------------------------------
   -- VGA CONVERTER SIGNALS
   -----------------------------------------------------------------
   SIGNAL VGA_CLK       : STD_LOGIC;
   SIGNAL VGA_DATA      : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   SIGNAL VGA_VSYNC     : STD_LOGIC;
   SIGNAL VGA_HSYNC     : STD_LOGIC;

   -----------------------------------------------------------------
   -- IMAGE SCALING SIGNALS
   -----------------------------------------------------------------
   ALIAS  COLORMAP_SELECT : STD_LOGIC IS SW(5);

BEGIN

   ------------------------------------------------------------------------------
   --  OUTPUT     OUTPUT      PHASE    DUTY CYCLE   PK-TO-PK     PHASE
   --   CLOCK     FREQ (MHZ)  (DEGREES)    (%)     JITTER (PS)  ERROR (PS)
   ------------------------------------------------------------------------------
   -- CLK_OUT1____50.000______0.000______50.0______197.491____160.491
   -- CLK_OUT2____25.174______0.000______50.0______228.649____160.491
   --
   ------------------------------------------------------------------------------
   -- INPUT CLOCK   FREQ (MHZ)    INPUT JITTER (UI)
   ------------------------------------------------------------------------------
   -- __PRIMARY_________100.000____________0.010
   ------------------------------------------------------------------------------
   CLOCK_GEN : CLOCK_GENERATOR
   PORT MAP( 
      CLK_IN1  => CLK, 
      RESET    => RST,
      LOCKED   => LOCKED,
      CLK_OUT1 => FAKE_CAMERA_CLK,
      CLK_OUT2 => VGA_CLK
   );

   -----------------------------------------------------------------
   -- INSTANTIATION OF THE FAKE CAMERA
   -----------------------------------------------------------------
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

      VID_SELECT  => FAKE_CAMERA_SLCT,
      FVAL_OUT    => FAKE_CAMERA_FVAL,
      LVAL_OUT    => FAKE_CAMERA_LVAL,
      DATA_OUT    => FAKE_CAMERA_DATA
   );

   FAKE_CAMERA_RST <= NOT(LOCKED);

   -----------------------------------------------------------------
   -- INSTANTIATION OF THE VIDEO TRANSPOSE
   -----------------------------------------------------------------
   TRANSPOSE: ENTITY WORK.VIDEO_TRANSPOSE
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

      FVAL_IN     => FAKE_CAMERA_FVAL,
      LVAL_IN     => FAKE_CAMERA_LVAL,
      DATA_IN     => FAKE_CAMERA_DATA,
      
      SWT         => TRANSPOSE_SLCT,
      FVAL_OUT    => TRANSPOSE_FVAL,
      LVAL_OUT    => TRANSPOSE_LVAL,
      DATA_OUT    => TRANSPOSE_DATA
   );

   -----------------------------------------------------------------
   --INSTANTIATION OF THE SOBEL FILTER
   -----------------------------------------------------------------
   EDGE_DETECTION: ENTITY WORK.SOBEL_WRAPPER
   GENERIC MAP(
      N                 => VIDEO_BITS,
      LINE_WIDTH        => VIDEO_VPIX + VIDEO_IPIX,
      ADDRESS_BUS_WIDTH => LOG2(VIDEO_VPIX + VIDEO_IPIX)+1
   )
   PORT MAP(
      CLK         => FAKE_CAMERA_CLK,
      RST         => FAKE_CAMERA_RST,

      FVAL_IN     => TRANSPOSE_FVAL, 
      LVAL_IN     => TRANSPOSE_LVAL,
      DATA_IN     => TRANSPOSE_DATA,

      SEL         => SOBEL_SLCT,
      FVAL_OUT    => SOBEL_FVAL,
      LVAL_OUT    => SOBEL_LVAL,
      DATA_OUT    => SOBEL_DATA
   );

   -----------------------------------------------------------------
   -- INSTANTIATION OF THE VGA CONVERTER
   -----------------------------------------------------------------
   VGA_OUTPUT: ENTITY WORK.VIDEO_VGA_CONVERTER
   GENERIC MAP(
      VIDEO_BITS     => VIDEO_BITS,
      VIDEO_VPIX     => VIDEO_VPIX,
      VIDEO_VLIN     => VIDEO_VLIN,
      VIDEO_IPIX     => VIDEO_IPIX
   )
   PORT MAP(
      CLK            => FAKE_CAMERA_CLK,
      RST            => FAKE_CAMERA_RST,

      FVAL_IN        => SOBEL_FVAL, -- FAKE_CAMERA_FVAL, -- TRANSPOSE_FVAL, -- 
      LVAL_IN        => SOBEL_LVAL, -- FAKE_CAMERA_LVAL, -- TRANSPOSE_LVAL, -- 
      DATA_IN        => SOBEL_DATA, -- FAKE_CAMERA_DATA, -- TRANSPOSE_DATA, -- 

      VGA_CLK        => VGA_CLK,
      VGA_HS_O       => VGA_HSYNC,
      VGA_VS_O       => VGA_VSYNC,
      VGA_DATA       => VGA_DATA
   );

   -----------------------------------------------------------------
   -- IMAGE SCALAR
   -----------------------------------------------------------------
   IMG_SCALING: ENTITY WORK.IMAGE_SCALING
   GENERIC MAP(
      VIDEO_IN_BITS  => VIDEO_BITS, 
      VIDEO_OUT_BITS => VGA_BITS
   )
   PORT MAP(
      CLK             => VGA_CLK,
      RST             => FAKE_CAMERA_RST,

      COLORMAP_SELECT => COLORMAP_SELECT,
      FVAL_IN         => VGA_VSYNC,   
      LVAL_IN         => VGA_HSYNC,   
      DATA_IN         => VGA_DATA,

      VGA_VS_O        => VSYNC,
      VGA_HS_O        => HSYNC,
      VGA_RED_O       => VGARED,
      VGA_BLUE_O      => VGABLUE,
      VGA_GREEN_O     => VGAGREEN
   );

   -----------------------------------------------------------------
   -- LED DRIVERS
   -----------------------------------------------------------------
   LED <= SW;

END PROJECT_TOP_ARCH;
