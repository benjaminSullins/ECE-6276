----------------------------------------------------------------------------------
-- COMPANY: GEORGIA TECH
-- ENGINEER: GREGORY H. WALLS
-- 
-- CREATE DATE: 11/11/2017
-- DESIGN NAME: VIDEO_TRANSPOSE
-- PROJECT NAME: VGA IMAGE TRANSPOSE AND EDGE DETECTION
----------------------------------------------------------------------------------

LIBRARY IEEE;
   USE IEEE.STD_LOGIC_1164.ALL;
   USE IEEE.STD_LOGIC_UNSIGNED.ALL;
   USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
   USE WORK.GENERIC_UTILITIES.ALL;

ENTITY VIDEO_TRANSPOSE IS
GENERIC(
   VIDEO_BITS     : NATURAL :=   8;    -- VIDEO DYNAMIC RANGE
   VIDEO_VPIX     : NATURAL := 320;    -- VALID PIXELS PER LINE
   VIDEO_VLIN     : NATURAL := 240;    -- VALID LINES
   VIDEO_IPIX     : NATURAL :=  16;    -- INVALID PIXELS PER LINE
   VIDEO_INT_TIME : NATURAL := 100     -- INTEGRATION TIME
);
PORT(
   CLK      : IN STD_LOGIC;
   RST      : IN STD_LOGIC;
   SWT      : IN STD_LOGIC; --SELECT SIGNALS
    
   FVAL_IN  : IN STD_LOGIC;
   LVAL_IN  : IN STD_LOGIC;
   DATA_IN  : IN STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   
   FVAL_OUT : OUT STD_LOGIC;
   LVAL_OUT : OUT STD_LOGIC;
   DATA_OUT : OUT STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0)
);
END VIDEO_TRANSPOSE;

ARCHITECTURE VIDEO_TRANSPOSE_ARCH OF VIDEO_TRANSPOSE IS

  --VALID SIGNALS
  SIGNAL BFF_VAL          : STD_LOGIC; --GOES HIGH WHEN THE FIRST FULL IMAGE HAS BEEN BUFFERED
  SIGNAL FRNT_PRCH        : STD_LOGIC; --GOES HIGH WHEN THE DESIGN SHOULD GO BACK TO THE FRONT PORCH (TRANSPOSE PROCESS)
  SIGNAL FRNT_PRCH_BFF    : STD_LOGIC; --GOES HIGH WHEN THE DESIGN SHOULD GO BACK TO THE FRONT PORCH (BUFFER PROCESS)

  --COUNTER SIGNALS
  SIGNAL VPIX_CNTR        : STD_LOGIC_VECTOR(LOG2(VIDEO_VPIX)     DOWNTO 0);
  SIGNAL VLIN_CNTR        : STD_LOGIC_VECTOR(LOG2(VIDEO_VLIN)     DOWNTO 0);
  SIGNAL IPIX_CNTR        : STD_LOGIC_VECTOR(LOG2(VIDEO_IPIX)     DOWNTO 0);
  SIGNAL INT_TIME_CNTR    : STD_LOGIC_VECTOR(LOG2(VIDEO_INT_TIME) DOWNTO 0);

  --BRAM SIGNALS
  CONSTANT BRAM_ADDR_BITS : NATURAL := LOG2(VIDEO_VPIX*VIDEO_VLIN);
  CONSTANT BRAM_DATA_BITS : NATURAL := VIDEO_BITS;

  SIGNAL WEA   : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL ADDRA : STD_LOGIC_VECTOR(BRAM_ADDR_BITS     DOWNTO 0);
  SIGNAL DINA  : STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
  SIGNAL DOUTA : STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
  SIGNAL WEB   : STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL ADDRB : STD_LOGIC_VECTOR(BRAM_ADDR_BITS     DOWNTO 0);
  SIGNAL DINB  : STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
  SIGNAL DOUTB : STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);

  COMPONENT TRANSPOSE_BRAM 
  PORT(
    CLKA  : IN  STD_LOGIC;
    WEA   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    ADDRA : IN  STD_LOGIC_VECTOR(BRAM_ADDR_BITS     DOWNTO 0);
    DINA  : IN  STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
    DOUTA : OUT STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
    CLKB  : IN  STD_LOGIC;
    WEB   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    ADDRB : IN  STD_LOGIC_VECTOR(BRAM_ADDR_BITS     DOWNTO 0);
    DINB  : IN  STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0);
    DOUTB : OUT STD_LOGIC_VECTOR(BRAM_DATA_BITS - 1 DOWNTO 0)
    );
  END COMPONENT;

BEGIN

TRANSPOSE_BRAM_0 : TRANSPOSE_BRAM 
PORT MAP(
  CLKA  => CLK,
  WEA   => WEA,
  ADDRA => ADDRA,
  DINA  => DINA,
  DOUTA => DOUTA,
  CLKB  => CLK,
  WEB   => WEB,
  ADDRB => ADDRB,
  DINB  => DINB,
  DOUTB => DOUTB
);

--PORT B IS READ ONLY
WEB <= (OTHERS => '0');

------------------------
--BUFFER IMAGE INTO BRAM
------------------------
PROCESS (RST, CLK, FVAL_IN) BEGIN
IF RST = '1' THEN
    FRNT_PRCH_BFF <= '1';
    BFF_VAL       <= '0';
    WEA           <= (OTHERS => '0');
    ADDRA         <= (OTHERS => '0');
    DINA          <= (OTHERS => '0');
ELSIF RISING_EDGE(CLK) THEN
    IF FVAL_IN       = '1' AND 
       LVAL_IN       = '1' AND 
       FRNT_PRCH_BFF = '1' THEN
      --FRONT PORCH
        WEA           <= (OTHERS => '1');
        DINA          <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(DATA_IN), BRAM_DATA_BITS));
        ADDRA         <= (OTHERS => '0');
        FRNT_PRCH_BFF <= '0';
    ELSIF FVAL_IN = '1' AND 
          LVAL_IN = '1' THEN
      --DATA VALID
        WEA   <= (OTHERS => '1');
        DINA  <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(DATA_IN), BRAM_DATA_BITS)); 
        ADDRA <= ADDRA + 1;
    ELSIF FVAL_IN = '1' AND 
          LVAL_IN = '0' THEN
      --DATA INVALID
        WEA   <= (OTHERS => '0');
        DINA  <= (OTHERS => '0');
    ELSIF FVAL_IN = '0' THEN
      --END OF FRAME
        FRNT_PRCH_BFF <= '1';
        WEA           <= (OTHERS => '0');
        DINA          <= (OTHERS => '0');
        ADDRA         <= (OTHERS => '0');
    ELSE
        REPORT "ERROR(VIDEO_TRANSPOSE.VHD): FVAL_IN AND/OR LVAL_IN UNDEFINED";
    END IF;
ELSE
    NULL;
END IF;
IF FALLING_EDGE(FVAL_IN) THEN
  --FIRST FULL FRAME IS BUFFERED
    BFF_VAL <= '1';
ELSE
    NULL;
END IF;
END PROCESS;

---------------------------------
--OUTPUT ORIGINAL/TRANSPOSE IMAGE
---------------------------------
PROCESS (RST, CLK) BEGIN
IF RST = '1' THEN
    FRNT_PRCH     <= '1';
    FVAL_OUT      <= '0';
    LVAL_OUT      <= '0';
    ADDRB         <= (OTHERS => '0');
    DATA_OUT      <= (OTHERS => '0');
    VPIX_CNTR     <= (OTHERS => '0');
    VLIN_CNTR     <= (OTHERS => '0');
    IPIX_CNTR     <= (OTHERS => '0');
    INT_TIME_CNTR <= (OTHERS => '0');
ELSIF RISING_EDGE(CLK) THEN
    IF BFF_VAL    = '1' AND 
       FRNT_PRCH  = '1' THEN
      --FRONT PORCH
        IF UNSIGNED(IPIX_CNTR) < VIDEO_IPIX - 1 THEN
            
            FVAL_OUT  <= '1';
            IPIX_CNTR <= IPIX_CNTR + 1;

            IF SWT = '1' THEN
                ADDRB <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(VLIN_CNTR),ADDRB'LENGTH));
            ELSE
                NULL;
            END IF;

        ELSIF UNSIGNED(IPIX_CNTR) >= VIDEO_IPIX - 1 THEN
            
            FRNT_PRCH <= '0';
            IPIX_CNTR <= (OTHERS => '0');

            IF SWT='0'                          AND
               UNSIGNED(VLIN_CNTR) < VIDEO_VLIN THEN
                ADDRB <= ADDRB + 1;
            ELSE
                NULL;
            END IF;

        ELSE
            REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR IPIX_CNTR";        
        END IF;

    ELSIF SWT     = '0' AND 
          BFF_VAL = '1' THEN

      --ORIGINAL IMAGE
        IF UNSIGNED(VLIN_CNTR) < VIDEO_VLIN THEN
            IF UNSIGNED(VPIX_CNTR) < VIDEO_VPIX THEN
                LVAL_OUT  <= '1';
                DATA_OUT  <= DOUTB;
                VPIX_CNTR <= VPIX_CNTR + 1;
                
                IF UNSIGNED(VLIN_CNTR) < VIDEO_VLIN - 1 THEN
                    IF UNSIGNED(VPIX_CNTR) < VIDEO_VPIX - 1 THEN
                        ADDRB <= ADDRB + 1;
                    ELSE 
                        NULL;
                    END IF;
                ELSIF UNSIGNED(VLIN_CNTR) >= VIDEO_VLIN - 1 THEN
                    IF UNSIGNED(VPIX_CNTR) < VIDEO_VPIX - 2 THEN
                        ADDRB <= ADDRB + 1;
                    ELSE 
                        NULL;
                    END IF;
                END IF;
                
            ELSIF UNSIGNED(VPIX_CNTR) >= VIDEO_VPIX THEN
                LVAL_OUT  <= '0';
                FRNT_PRCH <= '1';
                DATA_OUT  <= (OTHERS => '0');
                VLIN_CNTR <= VLIN_CNTR + 1;
                VPIX_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VPIX_CNTR";
            END IF;
        ELSIF UNSIGNED(VLIN_CNTR) >= VIDEO_VLIN THEN
            IF UNSIGNED(INT_TIME_CNTR) < VIDEO_INT_TIME - 1 THEN
                FVAL_OUT      <= '0';
                LVAL_OUT      <= '0';
                ADDRB         <= (OTHERS => '0');
                DATA_OUT      <= (OTHERS => '0');
                INT_TIME_CNTR <= INT_TIME_CNTR + 1;
            ELSIF UNSIGNED(INT_TIME_CNTR) >= VIDEO_INT_TIME - 1 THEN
                FRNT_PRCH     <= '1';                                                        
                VLIN_CNTR     <= (OTHERS => '0');
                INT_TIME_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR INT_TIME_CNTR";
            END IF;
        ELSE
            REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VLIN_CNTR";
        END IF;   
    ELSIF SWT     = '1' AND 
          BFF_VAL = '1' THEN
      --TRANSPOSE IMAGE
        IF UNSIGNED(VLIN_CNTR) < VIDEO_VLIN THEN
            IF UNSIGNED(VPIX_CNTR) < VIDEO_VPIX THEN
                LVAL_OUT  <= '1';
                VPIX_CNTR <= VPIX_CNTR + 1;
                IF UNSIGNED(VPIX_CNTR) < VIDEO_VLIN-1 THEN
                    DATA_OUT  <= DOUTB;
                    ADDRB <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED((VPIX_CNTR+1)*STD_LOGIC_VECTOR(TO_UNSIGNED(VIDEO_VPIX,VPIX_CNTR'LENGTH)) + VLIN_CNTR),ADDRB'LENGTH));
                ELSIF UNSIGNED(VPIX_CNTR) = VIDEO_VLIN-1 THEN
                    DATA_OUT  <= DOUTB;
                    ADDRB <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(VLIN_CNTR) + 1,ADDRB'LENGTH));
                ELSIF UNSIGNED(VPIX_CNTR) < VIDEO_VPIX THEN
                    DATA_OUT <= (OTHERS => '0');
                END IF;
            ELSIF UNSIGNED(VPIX_CNTR) >= VIDEO_VPIX THEN
                LVAL_OUT  <= '0';
                FRNT_PRCH <= '1';
                DATA_OUT  <= (OTHERS => '0');
                VLIN_CNTR <= VLIN_CNTR + 1;
                VPIX_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VPIX_CNTR";
            END IF;
        ELSIF UNSIGNED(VLIN_CNTR) >= VIDEO_VLIN THEN
            IF UNSIGNED(INT_TIME_CNTR) < VIDEO_INT_TIME - 1 THEN
                FVAL_OUT      <= '0';
                LVAL_OUT      <= '0';
                DATA_OUT      <= (OTHERS => '0');
                INT_TIME_CNTR <= INT_TIME_CNTR + 1;
            ELSIF UNSIGNED(INT_TIME_CNTR) >= VIDEO_INT_TIME - 1 THEN
                FRNT_PRCH     <= '1';
                ADDRB         <= (OTHERS => '0');
                VLIN_CNTR     <= (OTHERS => '0');
                INT_TIME_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR INT_TIME_CNTR";
            END IF;
        ELSE
            REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VLIN_CNTR";
        END IF;
    ELSE
        NULL;
    END IF;
ELSE
    NULL;
END IF;
END PROCESS;

END VIDEO_TRANSPOSE_ARCH;
