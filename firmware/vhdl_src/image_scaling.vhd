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
   CLK             : IN STD_LOGIC;
   RST             : IN STD_LOGIC;

   COLORMAP_SELECT : IN STD_LOGIC;
   FVAL_IN         : IN STD_LOGIC;
   LVAL_IN         : IN STD_LOGIC;
   DATA_IN         : IN STD_LOGIC_VECTOR(VIDEO_IN_BITS - 1 DOWNTO 0);

   VGA_VS_O        : OUT STD_LOGIC;
   VGA_HS_O        : OUT STD_LOGIC;
   VGA_RED_O       : OUT STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0);
   VGA_BLUE_O      : OUT STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0);
   VGA_GREEN_O     : OUT STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0)

);
END IMAGE_SCALING;

ARCHITECTURE IMAGE_SCALING_ARCH OF IMAGE_SCALING IS

   -----------------------------------------------------------------
   -- SIGNALS
   -----------------------------------------------------------------
   SIGNAL FVAL_IN_R1 : STD_LOGIC;
   SIGNAL LVAL_IN_R1 : STD_LOGIC;
   SIGNAL DATA_IN_R1 : STD_LOGIC_VECTOR(VIDEO_IN_BITS  - 1 DOWNTO 0);
   SIGNAL VGA_RED    : STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0);
   SIGNAL VGA_BLUE   : STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0);
   SIGNAL VGA_GREEN  : STD_LOGIC_VECTOR(VIDEO_OUT_BITS - 1 DOWNTO 0);

   -----------------------------------------------------------------
   -- SCALING COEFFICIENTS
   -----------------------------------------------------------------
   CONSTANT BRAM_ADDR_BITS : NATURAL := LOG2(VIDEO_OUT_BITS) + 1;
   CONSTANT BRAM_DATA_BITS : NATURAL := VIDEO_OUT_BITS*3;

   COMPONENT IMAGE_SCALING_BRAM 
   PORT(
      CLKA : IN  STD_LOGIC;
      WEA  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      ADDRA: IN  STD_LOGIC_VECTOR(BRAM_ADDR_BITS     DOWNTO 0);
      DINA : IN  STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
      DOUTA: OUT STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0)
   );
   END COMPONENT;

   SIGNAL MEM_ADDR : STD_LOGIC_VECTOR(BRAM_ADDR_BITS     DOWNTO 0);
   SIGNAL MEM_DATA : STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);

   CONSTANT BYPASS : STD_LOGIC := '0';

BEGIN

   -----------------------------------------------------------------
   -- BRAM INSTANTIATION (LATENCY = 1)
   -----------------------------------------------------------------
   BRAM : IMAGE_SCALING_BRAM 
   PORT MAP(
      CLKA  => CLK,
      WEA   => (OTHERS => '0'),
      ADDRA => MEM_ADDR,
      DINA  => (OTHERS => '0'),
      DOUTA => MEM_DATA
   );

   MEM_ADDR    <= DATA_IN(VIDEO_IN_BITS - 1 DOWNTO VIDEO_IN_BITS - VIDEO_OUT_BITS);

   VIDEO: PROCESS(RST,CLK)
   BEGIN
      IF RST = '1' THEN
         VGA_RED     <= (OTHERS => '0');        -- CLEAR
         VGA_BLUE    <= (OTHERS => '0');        -- CLEAR
         VGA_GREEN   <= (OTHERS => '0');        -- CLEAR
         FVAL_IN_R1  <= '0';
         LVAL_IN_R1  <= '0';
      ELSIF RISING_EDGE(CLK) THEN
         
         CASE( COLORMAP_SELECT ) IS
            WHEN BYPASS =>
               VGA_RED   <= DATA_IN_R1(VIDEO_IN_BITS - 1 DOWNTO VIDEO_IN_BITS - VIDEO_OUT_BITS);
               VGA_BLUE  <= DATA_IN_R1(VIDEO_IN_BITS - 1 DOWNTO VIDEO_IN_BITS - VIDEO_OUT_BITS);
               VGA_GREEN <= DATA_IN_R1(VIDEO_IN_BITS - 1 DOWNTO VIDEO_IN_BITS - VIDEO_OUT_BITS);

            WHEN OTHERS => 
               VGA_RED   <= MEM_DATA(VIDEO_OUT_BITS*3 - 1 DOWNTO VIDEO_OUT_BITS*2);
               VGA_BLUE  <= MEM_DATA(VIDEO_OUT_BITS*2 - 1 DOWNTO VIDEO_OUT_BITS*1);
               VGA_GREEN <= MEM_DATA(VIDEO_OUT_BITS*1 - 1 DOWNTO VIDEO_OUT_BITS*0);
         END CASE;

      -- REGISTER TO DATA ALIGN
      FVAL_IN_R1  <= FVAL_IN;
      LVAL_IN_R1  <= LVAL_IN;
      DATA_IN_R1  <= DATA_IN;

      END IF;
   END PROCESS;

   -----------------------------------------------------------------
   -- OUTPUT SIGNALS
   -----------------------------------------------------------------
   VGA_VS_O    <= FVAL_IN_R1;
   VGA_HS_O    <= LVAL_IN_R1;
   VGA_RED_O   <= VGA_RED;
   VGA_BLUE_O  <= VGA_BLUE;
   VGA_GREEN_O <= VGA_GREEN;

END IMAGE_SCALING_ARCH;
