-- This code will generate a default "SELECT * FROM" query based on table of parameter 1 and put this query into parameter 2 variable.
-- If parameter 3 is defined, it will order by this parameter. If param1 is a CDB view, con_id will be the first order by clause.
DEF in_table    = '&1.'
DEF in_variable = '&2.'

UNDEF 1 2

@@&&fc_def_empty_var. 3
def in_order_by = '&&3.'
undef 3

@@&&fc_set_value_var_nvl. in_order_by '&&in_order_by.' '1, 2'

DEF def_sel_star_qry = ''
COL def_sel_star_qry NEW_V def_sel_star_qry

DEF order_by_cdb_flag = ''
COL order_by_cdb_flag NEW_V order_by_cdb_flag
SELECT DECODE(REGEXP_REPLACE(UPPER('&&in_table.'),'^CDB_'),UPPER('&&in_table.'),'','CON_ID, ') order_by_cdb_flag
FROM DUAL;

DEF in_order_by = '&&order_by_cdb_flag.&&in_order_by.'

SELECT
'SELECT /*+ &&top_level_hints. */ /* &&section_id..&&report_sequence. */' || CHR(10) ||
'       *' || CHR(10) ||
'  FROM &&in_table.' || CHR(10) ||
' ORDER BY ' || CHR(10) ||
'       &&in_order_by.' def_sel_star_qry
FROM DUAL;

COL def_sel_star_qry clear
COL order_by_cdb_flag clear

EXEC :&&in_variable. := '&&def_sel_star_qry.';

UNDEF in_table in_variable in_order_by
UNDEF def_sel_star_qry order_by_cdb_flag