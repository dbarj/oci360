-- This code will generate a temporary file name to be used by the code.
-- Param 1 = Variable name
-- Param 2 = Optionally file name prefix
-- Param 3 = Optionally file name extension
def c_param1 = '&&1.'
@@&&fc_def_empty_var. 2
@@&&fc_def_empty_var. 3

def c_param2 = '&&2.'
def c_param3 = '&&3.'
undef 1 2 3

EXEC :temp_seq := :temp_seq + 1;

col c1 new_v &&c_param1. NOPRI
SELECT '&&moat369_sw_output_fdr./' || NVL('&&c_param2','step_file') || '_' || LPAD(:temp_seq, 5, '0') || '.' || NVL('&&c_param3','sql') c1 from dual;
col c1 clear

undef c_param1 c_param2