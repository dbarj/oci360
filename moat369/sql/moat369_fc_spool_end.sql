-- This module will prepare SQL*Plus when SPOOL ends
-- This module will turn term output off only if debug mode is not enabled.
COL c_spool_end NEW_V c_spool_end NOPRI
DEF c_spool_end = 'TERM OFF ECHO OFF FEED OFF VER OFF HEAD OFF'

SELECT 'TERM ON ECHO ON FEED ON VER ON HEAD ON' c_spool_end FROM DUAL WHERE UPPER(TRIM('&&DEBUG.')) = 'ON';
SET &&c_spool_end.

COL c_spool_end clear
UNDEF c_spool_end