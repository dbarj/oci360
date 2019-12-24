DEF oci360_in_comp_func = "&&1."
UNDEF 1

DEF oci360_comp_func_prev_table = "&&oci360_in_comp_func._PREV"

-- PAU
-- DEF DEBUG=ON
-- @@&&fc_spool_end.

-- First check if table from prev execution exists.
COL oci360_tab_to_count  NEW_V oci360_tab_to_count
SELECT DECODE(COUNT(*),0,'DUAL','&&oci360_comp_func_prev_table.') oci360_tab_to_count
FROM   ALL_TABLES
WHERE  OWNER      = '&&oci360_user_curschema.'
AND    TABLE_NAME = '&&oci360_comp_func_prev_table.';
COL oci360_tab_to_count clear

-- And if it exists, check if has any rows.
COL oci360_skip_if_empty NEW_V oci360_skip_if_empty
SELECT DECODE(COUNT(*),0,'&&fc_skip_script.','') oci360_skip_if_empty
FROM   &&oci360_tab_to_count
WHERE  '&&oci360_tab_to_count' != 'DUAL';
COL oci360_skip_if_empty clear

-- Define the output file for CSV result.
@@&&fc_def_output_file. oci360_csv_file 'compare_result.csv'

-- Compare both tables and place the result in the CSV file.
@@&&oci360_skip_if_empty.&&moat369_sw_folder./oci360_fc_compare_tables.sql "&&oci360_comp_func_prev_table." "&&oci360_in_comp_func." "&&oci360_csv_file."

-- Define the output file for HTML result.
@@&&fc_def_output_file. one_spool_html_file 'compare_result.html'

-- Convert the CSV into HTML.
HOS sh &&sh_csv_to_html_table. ',' &&oci360_csv_file. &&one_spool_html_file.
HOS rm -f &&oci360_csv_file.

UNDEF oci360_csv_file

-- Add tablefilter function into the HTML.
@@&&oci360_skip_if_empty.&&fc_add_tablefilter. &&one_spool_html_file.

DEF main_table = '&&oci360_in_comp_func.'
DEF skip_html = '--'
DEF skip_html_file = ''
DEF one_spool_html_desc_table = 'Y'
DEF sql_show = 'N'

@@&&oci360_skip_if_empty.&&9a_pre_one.
@@&&fc_reset_defs.

UNDEF oci360_skip_if_empty oci360_tab_to_count
UNDEF oci360_in_comp_func oci360_comp_func_prev_table

-- PAU
-- DEF DEBUG=OFF
-- @@&&fc_spool_end.
