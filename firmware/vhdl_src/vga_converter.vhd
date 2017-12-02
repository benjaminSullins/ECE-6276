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
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.GENERIC_UTILITIES.ALL;

ENTITY VIDEO_VGA_CONVERTER IS
  GENERIC(
           VIDEO_BITS : NATURAL := 8;
           VIDEO_VPIX : NATURAL := 320;
           VIDEO_VLIN : NATURAL := 240;
           VIDEO_IPIX : NATURAL := 16
         );
  PORT(
        CLK : IN STD_LOGIC;
        RST : IN STD_LOGIC;

        FVAL_IN       : IN STD_LOGIC;
        LVAL_IN       : IN STD_LOGIC;
        DATA_IN       : IN STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);

        VGA_CLK     : IN  STD_LOGIC;
        VGA_HS_O    : OUT STD_LOGIC;
        VGA_VS_O    : OUT STD_LOGIC;
        VGA_DATA    : OUT STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0)
      );
END VIDEO_VGA_CONVERTER;

ARCHITECTURE BEHAVIORAL OF VIDEO_VGA_CONVERTER IS

  COMPONENT VGA_BRAM 
    PORT (
           CLKA : IN STD_LOGIC;
           RSTA : IN STD_LOGIC;
           ENA  : IN STD_LOGIC;
           WEA  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
           ADDRA: IN STD_LOGIC_VECTOR(16 DOWNTO 0);
           DINA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
           DOUTA: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           CLKB : IN STD_LOGIC;
           RSTB : IN STD_LOGIC;
           ENB  : IN STD_LOGIC;
           WEB  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
           ADDRB: IN STD_LOGIC_VECTOR(16 DOWNTO 0);
           DINB : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
           DOUTB: OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
         );
  END COMPONENT;

  CONSTANT BRAM_SZ : NATURAL := 320*240;

  CONSTANT H_RES : NATURAL := 640; --Horizontal Resolution
  CONSTANT H_FP  : NATURAL := 16;  --Horizontal Front Porch
  CONSTANT H_BP  : NATURAL := 48;  --Horizontal Back Porch
  CONSTANT H_SY  : NATURAL := 96;  --Horizontal Sync Pulse
  CONSTANT H_TOT : NATURAL := H_FP + H_RES + H_BP + H_SY;
  CONSTANT V_RES : NATURAL := 480; --Vertical Resolution
  CONSTANT V_FP  : NATURAL := 10;  --Vertical Front Porch
  CONSTANT V_BP  : NATURAL := 33;  --Vertical Back Porch
  CONSTANT V_SY  : NATURAL := 2;   --Vertical Sync Pulse
  CONSTANT V_TOT : NATURAL := V_FP + V_RES + V_BP + V_SY;

  -- Upscale multiplier, need to replicate each pixel vertically and horizontally
  CONSTANT UPSCALE_FACTOR : NATURAL := H_RES / VIDEO_VPIX; -- 

  SIGNAL PXL_CLK          : STD_LOGIC; -- Pixel Clock (~25.175MHz)
  SIGNAL H_CNT            : STD_LOGIC_VECTOR(LOG2(H_TOT) DOWNTO 0) := (OTHERS => '0');
  SIGNAL V_CNT            : STD_LOGIC_VECTOR(LOG2(V_TOT) DOWNTO 0) := (OTHERS => '0');

  SIGNAL FVAL_IN_Z        : STD_LOGIC; -- FVAL register
  SIGNAL LVAL_IN_Z        : STD_LOGIC; -- LVAL register
  SIGNAL DATA_IN_Z        : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data input register

  SIGNAL PIX_OUT_REG      : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Output of BRAM
  
  SIGNAL ACTIVE           : STD_LOGIC;

  SIGNAL VGA_HS_REG       : STD_LOGIC; -- HSYNC Output Register
  SIGNAL VGA_VS_REG       : STD_LOGIC; -- VSYNC Output Register

  SIGNAL BRAM_IN_ADDR     : STD_LOGIC_VECTOR(16 DOWNTO 0) := (OTHERS => '0');
  SIGNAL BRAM_IN_WE       : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL BRAM_OUT_ADDR    : STD_LOGIC_VECTOR(16 + UPSCALE_FACTOR - 1 DOWNTO 0) := (OTHERS => '0');
  
  SIGNAL UPSCALE_CNT      : NATURAL := 0; -- Current upscale iteration
  SIGNAL PIX_CNT          : NATURAL := 0; -- Current pixel counter, to ensure we iterate over the same rows UPSCALE_FACTOR times.
  -- Could probably be replaced by H_CNT * UPSCALE_FACTOR

  CONSTANT ACTIVE_POLARITY : STD_LOGIC := '0';


BEGIN
  PXL_CLK <= VGA_CLK;

  BRAM : VGA_BRAM 
  PORT MAP(
    CLKA   => CLK,
    RSTA   => RST,
    ENA    => '1',
    WEA    => BRAM_IN_WE,
    ADDRA  => BRAM_IN_ADDR,
    DINA   => DATA_IN_Z,
    DOUTA  => OPEN,
    CLKB   => PXL_CLK,
    RSTB   => RST,
    ENB    => '1',
    WEB    => (OTHERS => '0'), -- never writing
    ADDRB  => BRAM_OUT_ADDR(16 + LOG2(UPSCALE_FACTOR) DOWNTO LOG2(UPSCALE_FACTOR)), -- ignore lowest bits so it will grab the same pixel multiple times for upscaling
    DINB   => (OTHERS => '0'),
    DOUTB  => PIX_OUT_REG
  );

  REG_INPUT : PROCESS(CLK)
  BEGIN
    IF RST = '1' THEN
      LVAL_IN_Z <= '0';
      FVAL_IN_Z <= '0';
      DATA_IN_Z <= (OTHERS => '0');
    ELSIF RISING_EDGE(CLK) THEN
      LVAL_IN_Z <= LVAL_IN;
      FVAL_IN_Z <= FVAL_IN;
      DATA_IN_Z <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(DATA_IN), 8));
    END IF;
  END PROCESS;

  H_COUNT : PROCESS(PXL_CLK)
  BEGIN
    IF RST = '1' THEN
      H_CNT <= (OTHERS => '0');
    ELSIF RISING_EDGE(PXL_CLK) THEN
      IF H_CNT = H_TOT - 1 THEN
        H_CNT <= (OTHERS => '0');
      ELSE
        H_CNT <= H_CNT + 1;
      END IF;
    END IF;
  END PROCESS;

  V_COUNT : PROCESS(PXL_CLK)
  BEGIN
    IF RST = '1' THEN
      V_CNT <= (OTHERS => '0');
    ELSIF RISING_EDGE(PXL_CLK) THEN
      IF (H_CNT = H_TOT - 1) AND (V_CNT = V_TOT - 1) THEN
        V_CNT <= (OTHERS => '0');
      ELSIF H_CNT = H_TOT - 1 THEN
        V_CNT <= V_CNT + 1;
      END IF;
    END IF;
  END PROCESS;

  H_SYNC : PROCESS(PXL_CLK)
  BEGIN
    IF RST = '1' THEN
      VGA_HS_REG <= '0';
    ELSIF RISING_EDGE(PXL_CLK) THEN
      IF (H_CNT >= H_FP + H_RES - 1) AND (H_CNT < H_FP + H_RES + H_SY - 1) THEN
        VGA_HS_REG <= NOT(ACTIVE_POLARITY);
      ELSE
        VGA_HS_REG <= ACTIVE_POLARITY;
      END IF;
    END IF;
  END PROCESS;

  V_SYNC : PROCESS(PXL_CLK)
  BEGIN
    IF RST = '1' THEN
      VGA_VS_REG <= '0';
    ELSIF RISING_EDGE(PXL_CLK) THEN
      IF (V_CNT >= V_FP + V_RES - 1) AND (V_CNT < V_FP + V_RES + V_SY - 1) THEN
        VGA_VS_REG <= NOT(ACTIVE_POLARITY);
      ELSE
        VGA_VS_REG <= ACTIVE_POLARITY;
      END IF;
    END IF;
  END PROCESS;

  BRAM_IN : PROCESS(CLK)
  BEGIN
    IF RST = '1' THEN
      BRAM_IN_ADDR <= (OTHERS => '0');
      BRAM_IN_WE   <= (OTHERS => '0');
    ELSIF RISING_EDGE(CLK) THEN
      IF FVAL_IN_Z = '1' AND LVAL_IN_Z = '1'THEN
        BRAM_IN_ADDR <= STD_LOGIC_VECTOR(UNSIGNED(BRAM_IN_ADDR)+1);
        BRAM_IN_WE   <= (OTHERS => '1');
      ELSIF FVAL_IN_Z = '1' THEN
        BRAM_IN_ADDR <= BRAM_IN_ADDR;
        BRAM_IN_WE   <= (OTHERS => '0');
      ELSE
        BRAM_IN_ADDR <= (OTHERS => '0');
        BRAM_IN_WE   <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  BRAM_OUT : PROCESS(PXL_CLK)
  BEGIN
    IF RST = '1' THEN
      BRAM_OUT_ADDR <= (OTHERS => '0');
    ELSIF RISING_EDGE(PXL_CLK) THEN
      IF V_CNT > V_RES THEN
        BRAM_OUT_ADDR <= (OTHERS => '0');
        UPSCALE_CNT   <= 0;
      ELSIF PIX_CNT = H_RES - 1 THEN
        PIX_CNT <= 0;
        IF UPSCALE_CNT < UPSCALE_FACTOR - 1 THEN
          -- increase upscale count, decrease addr to go back to beginning of row
          BRAM_OUT_ADDR <= STD_LOGIC_VECTOR(UNSIGNED(BRAM_OUT_ADDR)-(H_RES-1));
          UPSCALE_CNT   <= UPSCALE_CNT + 1;
        ELSE
          BRAM_OUT_ADDR <= BRAM_OUT_ADDR+1;
          UPSCALE_CNT   <= 0;
        END IF;
      ELSIF (H_CNT < H_RES) AND (V_CNT < V_RES) THEN
        BRAM_OUT_ADDR <= BRAM_OUT_ADDR+1;
        PIX_CNT       <= PIX_CNT + 1;
      END IF;
    END IF;
  END PROCESS;

  ACTIVE <= '1' WHEN ((H_CNT < H_RES) AND (V_CNT < V_RES)) ELSE 
            '0';

  VGA_HS_O    <= VGA_HS_REG;
  VGA_VS_O    <= VGA_VS_REG;
  VGA_DATA    <= PIX_OUT_REG(VIDEO_BITS - 1 DOWNTO 0) WHEN ACTIVE = '1' ELSE 
                 (OTHERS => '0');
END BEHAVIORAL;
