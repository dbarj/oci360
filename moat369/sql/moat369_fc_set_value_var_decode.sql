-- Works as DECODE function: param1 = DECODE(param2,param3,param4,param5)
-- Define variable in 1st parameter as 4th parameter if param2=param3. Else set as param5.

def c_param1 = '&&1.'

col c1 new_v &&c_param1. NOPRI
select decode(q'[&&2.]',q'[&&3.]',q'[&&4.]',q'[&&5.]') "c1" from dual;
col c1 clear

undef c_param1
undef 1 2 3 4 5
