-- If parameter 1 is 'T' or 'Y' (True or Yes), it will define main_table variable as parameter 2, otherwise as parameter 3.

-- Param 1 = Any variable
-- Param 2 = Value to put in main_table if param1 is T or F
-- Param 3 = Value to put in main_table if param1 isn't T or F

DEF main_table = ''
COL main_table NEW_V main_table nopri
-- TODO Improve it
SELECT /*+ result_cache */ CASE WHEN '&1' IN ('T','Y') THEN '&2' ELSE '&3' end main_table
FROM dual;
COL main_table clear

UNDEF 1 2 3