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
-- GENERIC UTILITIES PACKAGE
--------------------------------------------
-- REFERENCES
-- HTTP://WWW.EDABOARD.COM/THREAD186363.HTML
-- 
--------------------------------------------

PACKAGE GENERIC_UTILITIES IS

   -- LOG2 DECLARATION
   FUNCTION LOG2( I : NATURAL ) RETURN INTEGER;

END PACKAGE GENERIC_UTILITIES;

PACKAGE BODY GENERIC_UTILITIES IS

   ------------------------------------------------------------
   -- FUNCTION FOR PROVIDING THE LOG2
   -- REFERENCE: HTTP://WWW.EDABOARD.COM/THREAD186363.HTML
   ------------------------------------------------------------
   FUNCTION LOG2( I : NATURAL ) RETURN INTEGER IS
      VARIABLE TEMP    : INTEGER := I;
      VARIABLE RET_VAL : INTEGER := 0; 
   BEGIN              
      WHILE TEMP > 1 LOOP
         RET_VAL := RET_VAL + 1;
         TEMP    := TEMP / 2;     
      END LOOP;
   
      RETURN RET_VAL;
   END FUNCTION;

END PACKAGE BODY GENERIC_UTILITIES;

