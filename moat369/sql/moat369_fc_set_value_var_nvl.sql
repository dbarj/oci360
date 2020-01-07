-- 3 parameters are given, works as NVL function: param1 = NVL(param2,param3)
-- Define variable in 1st parameter as 3rd parameter if 2nd parameter is NULL. Else return the 2nd.

def c_param1 = '&&1.'

COL c1 NEW_V &&c_param1. NOPRI
select nvl(q'[&&2.]',q'[&&3.]') "c1" from dual;
col c1 clear

undef c_param1
undef 1 2 3