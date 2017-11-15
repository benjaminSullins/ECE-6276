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
-- FAKE CAMERA SIMULATOR
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

ENTITY FAKE_CAMERA IS
GENERIC(
   VIDEO_BITS     : NATURAL :=   8;    -- VIDEO DYNAMIC RANGE
   VIDEO_VPIX     : NATURAL := 320;    -- VALID PIXELS PER LINE
   VIDEO_VLIN     : NATURAL := 240;    -- VALID LINES
   VIDEO_IPIX     : NATURAL :=  16;    -- INVALID PIXELS PER LINE
   VIDEO_INT_TIME : NATURAL := 100     -- INVALID PIXELS PER FRAME
);
PORT(
   CLK            : IN STD_LOGIC;
   RST            : IN STD_LOGIC;

   VID_SELECT     : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
   FVAL_OUT       : OUT STD_LOGIC;
   LVAL_OUT       : OUT STD_LOGIC;
   DATA_OUT       : OUT STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0)

);
END FAKE_CAMERA;

ARCHITECTURE FAKE_CAMERA_ARCH OF FAKE_CAMERA IS

   -----------------------------------------------------------------
   -- STATE MACHINE
   -----------------------------------------------------------------
   -- FRAME_INVALID - NO FRAME BEING SENT
   -- FRONT_PORCH   - I LIKE TO ADD A FRONT PORCH TO ALLOW SETTLING
   --                 TIME FOR DOWNSTREAM LOGIC
   -- LINE_VALID    - VALID LINE DATA
   -- LINE_INVALID  - INVALID LINE DATA
   -----------------------------------------------------------------
   TYPE STATE_MACHINE IS (FRAME_INVALID, FRONT_PORCH, LINE_VALID, LINE_INVALID);
   SIGNAL SM : STATE_MACHINE := FRAME_INVALID;

   SIGNAL VLIN_CNTR     : STD_LOGIC_VECTOR(LOG2(VIDEO_VLIN) DOWNTO 0);

   -----------------------------------------------------------------
   -- COUNTER CONTROLLER
   -----------------------------------------------------------------
   SIGNAL INT_TIME_CNTR : STD_LOGIC_VECTOR(LOG2(VIDEO_INT_TIME) DOWNTO 0);
   SIGNAL VPIX_CNTR     : STD_LOGIC_VECTOR(LOG2(VIDEO_VPIX)     DOWNTO 0);
   SIGNAL IPIX_CNTR     : STD_LOGIC_VECTOR(LOG2(VIDEO_IPIX)     DOWNTO 0);

   -----------------------------------------------------------------
   -- OUTPUT REGISTERS
   -----------------------------------------------------------------
   SIGNAL FVAL_REG      : STD_LOGIC;
   SIGNAL FVAL_REG1     : STD_LOGIC;
   SIGNAL LVAL_REG      : STD_LOGIC;
   SIGNAL LVAL_REG1     : STD_LOGIC;
   SIGNAL DATA_REG      : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);
   SIGNAL DATA_REG1     : STD_LOGIC_VECTOR(VIDEO_BITS - 1 DOWNTO 0);

   -- OUTPUT SELECTIONS
   CONSTANT HORIZ_TP    : STD_LOGIC_VECTOR(VID_SELECT'RANGE) := "00";
   CONSTANT VERTI_TP    : STD_LOGIC_VECTOR(VID_SELECT'RANGE) := "01";
   CONSTANT IMAGE_TP    : STD_LOGIC_VECTOR(VID_SELECT'RANGE) := "10";

   -----------------------------------------------------------------
   -- PRE-LOADED IMAGE
   -----------------------------------------------------------------
   CONSTANT BRAM_ADDR_BITS : NATURAL := LOG2(VIDEO_VPIX*VIDEO_VLIN);
   CONSTANT BRAM_DATA_BITS : NATURAL := 8;

   COMPONENT FAKE_CAMERA_BRAM 
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

BEGIN

   -----------------------------------------------------------------
   -- STATE MACHINE
   -----------------------------------------------------------------
   -- NOTES:
   -- THIS STATE MACHINE CONTROLS THE FLOW FOR THE FRAME GENERATION.
   -----------------------------------------------------------------
   STATE_MACHINE_PROC: PROCESS(RST, CLK)
   BEGIN
      IF RST = '1' THEN
         SM        <= FRAME_INVALID;                     -- MODE TO FRAME_INVALID
         VLIN_CNTR <= (OTHERS => '0');                   -- AND CLEAR LINE COUNTER
      ELSIF RISING_EDGE(CLK) THEN

         CASE( SM ) IS

            WHEN FRAME_INVALID =>                              -- FRAME INVALID STATE
               IF( INT_TIME_CNTR >= VIDEO_INT_TIME - 1 ) THEN  -- IF WE HAVE REACHED THE INTEGRATION TIME
                  SM <= FRONT_PORCH;                           -- MOVE TO FRONT_PORCH
               ELSE                                            -- OTHERWISE
                  SM <= FRAME_INVALID;                         -- STAY IN FRAME_INVALID STATE
               END IF;

            WHEN FRONT_PORCH =>                                -- FRONT_PORCH STATE
               IF( IPIX_CNTR >= VIDEO_IPIX - 1 ) THEN          -- IF WE HAVE REACHED IPIX COUNT
                  SM        <= LINE_VALID;                     -- MOVE TO LINE_VALID
               ELSE                                            -- OTHERWISE
                  SM        <= FRONT_PORCH;                    -- STAY IN FRONT_PORCH STATE
               END IF;

            WHEN LINE_VALID =>                                 -- LINE_VALID STATE
               IF( VPIX_CNTR >= VIDEO_VPIX - 1 ) THEN          -- IF WE HAVE REACHED VPIX COUNT
                  SM        <= LINE_INVALID;                   -- MOVE TO LINE_INVALID
               ELSE                                            -- OTHERWISE
                  SM        <= LINE_VALID;                     -- STAY IN LINE_VALID STATE
               END IF;

            WHEN LINE_INVALID =>                               -- LINE_INVALID
               IF( IPIX_CNTR >= VIDEO_IPIX - 1 ) THEN          -- IF WE HAVE REACHED VPIX COUNT
                  IF( VLIN_CNTR >= VIDEO_VLIN - 1 ) THEN       -- CHECK FOR END OF FRAME
                     SM        <= FRAME_INVALID;               -- MODE TO FRAME_INVALID
                     VLIN_CNTR <= (OTHERS => '0');             -- AND CLEAR LINE COUNTER
                  ELSE                                         -- OTHERWISE
                     SM        <= LINE_VALID;                  -- MOVE TO LINE_VALID
                     VLIN_CNTR <= VLIN_CNTR + 1;               -- AND INCREMENT LINE COUNTER
                  END IF;
               ELSE                                            -- OTHERWISE
                  SM        <= LINE_INVALID;                   -- STAY IN LINE_VALID STATE
                  VLIN_CNTR <= VLIN_CNTR;                      -- AND DONT INCREMENT LINE COUNTER
               END IF;
               
            WHEN OTHERS =>                                     -- UNKNOWN STATE
               SM        <= FRAME_INVALID;                     -- MODE TO FRAME_INVALID
               VLIN_CNTR <= (OTHERS => '0');                   -- AND CLEAR LINE COUNTER

         END CASE;
      END IF;
   END PROCESS;

   -----------------------------------------------------------------
   -- COUNTER CONTROLLER
   -----------------------------------------------------------------
   -- NOTES:
   -- THIS PROCESS CONTROLLS THE COUNTERS USED FOR HANDLING THE
   -- STATE MACHINE LOGIC.
   -----------------------------------------------------------------
   COUNTER_PROC: PROCESS(RST,CLK)
   BEGIN
      IF RST = '1' THEN
         INT_TIME_CNTR  <= (OTHERS => '0');        -- CLEAR THE COUNTERS
         VPIX_CNTR      <= (OTHERS => '0');        -- CLEAR THE COUNTERS
         IPIX_CNTR      <= (OTHERS => '0');        -- CLEAR THE COUNTERS
      ELSIF RISING_EDGE(CLK) THEN
         
         CASE( SM ) IS

            WHEN FRAME_INVALID =>  
               INT_TIME_CNTR  <= INT_TIME_CNTR + 1;
               VPIX_CNTR      <= (OTHERS => '0');
               IPIX_CNTR      <= (OTHERS => '0');

            WHEN FRONT_PORCH =>                                -- FRONT_PORCH
               INT_TIME_CNTR  <= (OTHERS => '0');
               VPIX_CNTR      <= (OTHERS => '0');
               IPIX_CNTR      <= IPIX_CNTR + 1;

            WHEN LINE_VALID =>                                 -- LINE_VALID STATE
               INT_TIME_CNTR  <= (OTHERS => '0');
               VPIX_CNTR      <= VPIX_CNTR + 1;
               IPIX_CNTR      <= (OTHERS => '0');

            WHEN LINE_INVALID =>                               -- LINE_INVALID
               INT_TIME_CNTR  <= (OTHERS => '0');
               VPIX_CNTR      <= (OTHERS => '0');
               IPIX_CNTR      <= IPIX_CNTR + 1;
                  
            WHEN OTHERS =>                                     -- UNKNOWN STATE
               INT_TIME_CNTR  <= (OTHERS => '0');
               VPIX_CNTR      <= (OTHERS => '0');
               IPIX_CNTR      <= (OTHERS => '0');

         END CASE;
      END IF;
   END PROCESS;

   -----------------------------------------------------------------
   -- OUTPUT REGISTERS
   -----------------------------------------------------------------
   -- NOTES:
   -- THIS PROCESS HANDLES THE OUTPUT SIGNALS AND ALSO THE DATA
   -- GENERATION.
   -----------------------------------------------------------------
   OUTPUT_REGS: PROCESS(RST,CLK)
   BEGIN
      IF RST = '1' THEN
         FVAL_REG  <= '0';                 -- CLEAR THE OUTPUTS
         LVAL_REG  <= '0';                 -- CLEAR THE OUTPUTS
         FVAL_REG1 <= '0';                 -- CLEAR THE OUTPUTS
         LVAL_REG1 <= '0';                 -- CLEAR THE OUTPUTS
         DATA_REG  <= (OTHERS => '0');     -- CLEAR THE OUTPUTS
         DATA_REG1 <= (OTHERS => '0');     -- CLEAR THE OUTPUTS
         MEM_ADDR  <= (OTHERS => '0');
      ELSIF RISING_EDGE(CLK) THEN
         
         CASE( SM ) IS

            WHEN FRAME_INVALID =>  
               FVAL_REG  <= '0';            
               LVAL_REG  <= '0';            
               DATA_REG1 <= (OTHERS => '0');
               MEM_ADDR  <= (OTHERS => '0');

            WHEN FRONT_PORCH =>                                -- FRONT_PORCH
               FVAL_REG  <= '1';            
               LVAL_REG  <= '0';            
               DATA_REG1 <= (OTHERS => '0');
               MEM_ADDR  <= (OTHERS => '0');

            WHEN LINE_VALID =>                                 -- LINE_VALID STATE
               FVAL_REG  <= '1';            
               LVAL_REG  <= '1';            
               DATA_REG1 <= DATA_REG;
               MEM_ADDR  <= MEM_ADDR + 1;

            WHEN LINE_INVALID =>                               -- LINE_INVALID
               FVAL_REG  <= '1';            
               LVAL_REG  <= '0';            
               DATA_REG1 <= (OTHERS => '0');
               MEM_ADDR  <= MEM_ADDR;
                  
            WHEN OTHERS =>                                     -- UNKNOWN STATE
               FVAL_REG  <= '0';            
               LVAL_REG  <= '0';            
               DATA_REG1 <= (OTHERS => '0');
               MEM_ADDR  <= (OTHERS => '0');

         END CASE;

         CASE( VID_SELECT ) IS
            WHEN HORIZ_TP => DATA_REG <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(VPIX_CNTR), VIDEO_BITS));
            WHEN VERTI_TP => DATA_REG <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(VLIN_CNTR), VIDEO_BITS));
            WHEN IMAGE_TP => DATA_REG <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(MEM_DATA),  VIDEO_BITS));
            WHEN OTHERS   => DATA_REG <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(MEM_DATA),  VIDEO_BITS));
         END CASE;

         -- REGISTER FVAL/LVAL TO ALIGN WITH DATA
         FVAL_REG1 <= FVAL_REG;
         LVAL_REG1 <= LVAL_REG;

      END IF;
   END PROCESS;

   -- BRAM INSTANTIATION (LATENCY = 1)
   BRAM : FAKE_CAMERA_BRAM 
   PORT MAP(
      CLKA  => CLK,
      WEA   => (OTHERS => '0'),
      ADDRA => MEM_ADDR,
      DINA  => (OTHERS => '0'),
      DOUTA => MEM_DATA
   );

   -- CONNECT REGISTERS TO OUTPUTS
   FVAL_OUT <= FVAL_REG;
   LVAL_OUT <= LVAL_REG;
   DATA_OUT <= DATA_REG;

END FAKE_CAMERA_ARCH;
