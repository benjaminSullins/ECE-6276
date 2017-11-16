----------------------------------------------------------------------------------
-- Company: Georgia Tech
-- Engineer: Gregory H. Walls
-- 
-- Create Date: 11/11/2017
-- Design Name: video_transpose
-- Project Name: VGA Image Transpose and Edge Detection
----------------------------------------------------------------------------------

LIBRARY IEEE;
   USE IEEE.STD_LOGIC_1164.ALL;
   USE IEEE.STD_LOGIC_UNSIGNED.ALL;
   USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
   USE WORK.GENERIC_UTILITIES.ALL;

entity video_transpose is
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
   SWT      : IN STD_LOGIC; --select signals
    
   FVAL_IN  : IN STD_LOGIC;
   LVAL_IN  : IN STD_LOGIC;
   DATA_IN  : IN STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   
   FVAL_OUT : OUT STD_LOGIC;
   LVAL_OUT : OUT STD_LOGIC;
   DATA_OUT : OUT STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0)
);
end video_transpose;

architecture video_transpose_arch of video_transpose is

--VALID SIGNALS
SIGNAL BFF_VAL   : STD_LOGIC; --GOES HIGH WHEN THE FIRST FULL IMAGE HAS BEEN BUFFERED
SIGNAL FRNT_PRCH : STD_LOGIC; --GOES HIGH WHEN THE DESIGN SHOULD GO BACK TO THE FRONT PORCH (TRANSPOSE PROCESS)
SIGNAL FRNT_PRCH_BFF : STD_LOGIC; --GOES HIGH WHEN THE DESIGN SHOULD GO BACK TO THE FRONT PORCH (BUFFER PROCESS)

--COUNTER SIGNALS
SIGNAL VPIX_CNTR     : STD_LOGIC_VECTOR(LOG2(VIDEO_VPIX) DOWNTO 0);
SIGNAL VLIN_CNTR     : STD_LOGIC_VECTOR(LOG2(VIDEO_VLIN) DOWNTO 0);
SIGNAL IPIX_CNTR     : STD_LOGIC_VECTOR(LOG2(VIDEO_IPIX) DOWNTO 0);
SIGNAL INT_TIME_CNTR : STD_LOGIC_VECTOR(LOG2(VIDEO_INT_TIME) DOWNTO 0);

--BRAM SIGNALS
SIGNAL WEA   : STD_LOGIC_VECTOR(0 DOWNTO 0);
SIGNAL ADDRA : STD_LOGIC_VECTOR(16 DOWNTO 0);
SIGNAL DINA  : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL DOUTA : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL WEB   : STD_LOGIC_VECTOR(0 DOWNTO 0);
SIGNAL ADDRB : STD_LOGIC_VECTOR(16 DOWNTO 0);
SIGNAL DINB  : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL DOUTB : STD_LOGIC_VECTOR(7 DOWNTO 0);

component transpose_bram 
port (
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      clkb  : IN STD_LOGIC;
      web   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
      dinb  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
end component;

begin

transpose_bram_0 : transpose_bram 
port map (
          clka  => CLK,
          wea   => WEA,
          addra => ADDRA,
          dina  => DINA,
          douta => DOUTA,
          clkb  => CLK,
          web   => WEB,
          addrb => ADDRB,
          dinb  => DINB,
          doutb => DOUTB
          );

--PORT B IS READ ONLY
WEB <= "0";

------------------------
--BUFFER IMAGE INTO BRAM
------------------------
PROCESS (RST,CLK,FVAL_IN) BEGIN
IF RST='1' THEN
    FRNT_PRCH_BFF <= '1';
    BFF_VAL <= '0';
    WEA <= "0";
    ADDRA <= (OTHERS => '0');
    DINA <= (OTHERS => '0');
ELSIF RISING_EDGE(CLK) THEN
    IF FVAL_IN='1' AND LVAL_IN='1' AND FRNT_PRCH_BFF='1' THEN
      --FRONT PORCH
        WEA <= "1";
        DINA <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(DATA_IN),8));
        ADDRA <= (OTHERS => '0');
        FRNT_PRCH_BFF <= '0';
    ELSIF FVAL_IN='1' AND LVAL_IN='1' THEN
      --DATA VALID
        WEA <= "1";
        DINA <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(DATA_IN),8));
        ADDRA <= ADDRA + 1;
    ELSIF FVAL_IN='1' AND LVAL_IN='0' THEN
      --DATA INVALID
        WEA <= "0";
        DINA <= (OTHERS => '0');
    ELSIF FVAL_IN='0' THEN
      --END OF FRAME
        FRNT_PRCH_BFF <= '1';
        WEA <= "0";
        DINA <= (OTHERS => '0');
        ADDRA <= (OTHERS => '0');
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
PROCESS (RST,CLK) BEGIN
IF RST = '1' THEN
    FRNT_PRCH <= '1';
    FVAL_OUT <= '0';
    LVAL_OUT <= '0';
    ADDRB <= (OTHERS => '0');
    DATA_OUT <= (OTHERS => '0');
    VPIX_CNTR <= (OTHERS => '0');
    VLIN_CNTR <= (OTHERS => '0');
    IPIX_CNTR <= (OTHERS => '0');
    INT_TIME_CNTR <= (OTHERS => '0');
ELSIF RISING_EDGE(CLK) THEN
    IF BFF_VAL='1' AND FRNT_PRCH='1' THEN
      --FRONT PORCH
        IF UNSIGNED(IPIX_CNTR)<VIDEO_IPIX-1 THEN
            FVAL_OUT <= '1';
            IPIX_CNTR <= IPIX_CNTR + 1;
            IF SWT='1' THEN
                ADDRB <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(VPIX_CNTR),ADDRB'LENGTH));
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): SWT ISSUE IN FRONT PORCH";
            END IF;
        ELSIF UNSIGNED(IPIX_CNTR)>=VIDEO_IPIX-1 THEN
            FRNT_PRCH <= '0';
            IPIX_CNTR <= (OTHERS => '0');
            IF SWT='0' THEN
                ADDRB <= ADDRB + 1;
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): SWT ISSUE IN FRONT PORCH";
            END IF;
        ELSE
            REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR IPIX_CNTR";        
        END IF;
    ELSIF SWT='0' AND BFF_VAL='1' THEN
      --ORIGINAL IMAGE
        IF UNSIGNED(VLIN_CNTR)<VIDEO_VLIN-1 THEN
            IF UNSIGNED(VPIX_CNTR)<VIDEO_VPIX THEN
                LVAL_OUT <= '1';
                DATA_OUT <= DOUTB;
                VPIX_CNTR <= VPIX_CNTR + 1;
                IF UNSIGNED(VPIX_CNTR)<VIDEO_VPIX-1 THEN
                    ADDRB <= ADDRB + 1;
                ELSE
                    NULL;
                END IF;
            ELSIF UNSIGNED(VPIX_CNTR)>=VIDEO_VPIX THEN
                LVAL_OUT <= '0';
                FRNT_PRCH <= '1';
                DATA_OUT <= (OTHERS => '0');
                VLIN_CNTR <= VLIN_CNTR + 1;
                VPIX_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VPIX_CNTR";
            END IF;
        ELSIF UNSIGNED(VLIN_CNTR)>=VIDEO_VLIN-1 THEN
            IF UNSIGNED(INT_TIME_CNTR)<VIDEO_INT_TIME-1 THEN
                FVAL_OUT <= '0';
                LVAL_OUT <= '0';
                DATA_OUT <= (OTHERS => '0');
                INT_TIME_CNTR <= INT_TIME_CNTR + 1;
            ELSIF UNSIGNED(INT_TIME_CNTR)>=VIDEO_INT_TIME-1 THEN
                FRNT_PRCH <= '1';
                ADDRB <= (OTHERS => '0');
                VLIN_CNTR <= (OTHERS => '0');
                INT_TIME_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR INT_TIME_CNTR";
            END IF;
        ELSE
            REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VLIN_CNTR";
        END IF;   
    ELSIF SWT='1' AND BFF_VAL='1' THEN
      --TRANSPOSE IMAGE
        IF UNSIGNED(VPIX_CNTR)<VIDEO_VPIX THEN
            IF UNSIGNED(VLIN_CNTR)<VIDEO_VLIN THEN
                LVAL_OUT <= '1';
                DATA_OUT <= DOUTB;
                VLIN_CNTR <= VLIN_CNTR + 1;
                IF UNSIGNED(VLIN_CNTR)<VIDEO_VLIN-1 THEN
                    ADDRB <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED((VLIN_CNTR+1)*STD_LOGIC_VECTOR(TO_UNSIGNED(VIDEO_VPIX,VPIX_CNTR'LENGTH)) + VPIX_CNTR),ADDRB'LENGTH));
                END IF;
            ELSIF UNSIGNED(VLIN_CNTR)>=VIDEO_VLIN THEN
                LVAL_OUT <= '0';
                FRNT_PRCH <= '1';
                DATA_OUT <= (OTHERS => '0');
                VPIX_CNTR <= VPIX_CNTR + 1;
                VLIN_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VLIN_CNTR";
            END IF;
        ELSIF UNSIGNED(VPIX_CNTR)>=VIDEO_VPIX THEN
            IF UNSIGNED(INT_TIME_CNTR)<VIDEO_INT_TIME-1 THEN
                FVAL_OUT <= '0';
                LVAL_OUT <= '0';
                DATA_OUT <= (OTHERS => '0');
                INT_TIME_CNTR <= INT_TIME_CNTR + 1;
            ELSIF UNSIGNED(INT_TIME_CNTR)>=VIDEO_INT_TIME-1 THEN
                FRNT_PRCH <= '1';
                ADDRB <= (OTHERS => '0');
                VPIX_CNTR <= (OTHERS => '0');
                INT_TIME_CNTR <= (OTHERS => '0');
            ELSE
                REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR INT_TIME_CNTR";
            END IF;
        ELSE
            REPORT "ERROR(VIDEO_TRANSPOSE.VHD): INVALID VALUE FOR VPIX_CNTR";
        END IF;
    ELSE
        NULL;
    END IF;
ELSE
    NULL;
END IF;
END PROCESS;

end video_transpose_arch;
