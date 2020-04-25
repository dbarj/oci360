-- Reset variables and defs used by each item.
EXEC :sql_text := NULL;
EXEC :sql_text_cdb := NULL;
EXEC :sql_text_display := NULL;
EXEC :sql_with_clause := NULL;
DEF row_num    = '-1'
DEF row_num_dif = 0
DEF abstract   = ''
DEF abstract2  = ''
DEF main_table = ''
DEF foot       = ''
DEF max_rows   = '&&moat369_def_sql_maxrows.'
DEF sql_hl     = '&&moat369_def_sql_highlight.'
DEF sql_format = '&&moat369_def_sql_format.'
DEF sql_show   = '&&moat369_def_sql_show.'
--
DEF skip_html       = '&&moat369_def_skip_html.'
DEF skip_text       = '&&moat369_def_skip_text.'
DEF skip_csv        = '&&moat369_def_skip_csv.'
DEF skip_lch        = '&&moat369_def_skip_line.'
DEF skip_pch        = '&&moat369_def_skip_pie.'
DEF skip_bch        = '&&moat369_def_skip_bar.'
DEF skip_graph      = '&&moat369_def_skip_graph.'
DEF skip_map        = '&&moat369_def_skip_map.'
DEF skip_treemap    = '&&moat369_def_skip_treemap.'
DEF skip_html_spool = '&&fc_skip_script.'
DEF skip_text_file  = '&&fc_skip_script.'
DEF skip_html_file  = '&&fc_skip_script.'
DEF d3_graph = ''
--
DEF title_suffix = ''
DEF haxis = '&&db_version. &&cores_threads_hosts.'
--
-- needed reset after eventual sqlmon
SET HEA ON
SET LIN 32767
SET NEWP NONE
SET PAGES &&moat369_def_sql_maxrows.
SET LONG 32000000
SET LONGC 4000
SET WRA ON
SET TRIMS ON
SET TRIM ON
SET TI OFF
SET TIMI OFF
SET ARRAY 1000
SET NUM 20
SET SQLBL ON
SET BLO .
SET RECSEP OFF
--