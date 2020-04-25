-- SETUP
SET VER OFF
SET FEED OFF
SET ECHO OFF
SELECT TO_CHAR(SYSDATE, '&&moat369_date_format.') moat369_time_stamp FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') hh_mm_ss FROM DUAL;
@@&&fc_clean_file_name. "title" "title_no_spaces"
SELECT '&&report_sequence._&&title_no_spaces.' spool_filename FROM DUAL;
SET HEA OFF
SET TERM ON

-- log
SPO &&moat369_log. APP
PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO &&hh_mm_ss. &&section_id. "&&section_name."
PRO &&hh_mm_ss. &&title.&&title_suffix.
PRO

-- Check if we will use sql_text or sql_text_cdb
BEGIN
  IF :sql_text_cdb IS NOT NULL AND '&&is_cdb.' = 'Y' then
    :sql_text := :sql_text_cdb;
  ELSE
    :sql_text := :sql_text; -- Do not remove this crazy thing.
  END IF;
END;
/

EXEC :sql_with_clause := TRIM(:sql_with_clause);
EXEC :sql_with_clause := TRIM(CHR(10) FROM :sql_with_clause);

BEGIN
  IF :sql_with_clause IS NOT NULL then
    :sql_with_clause := :sql_with_clause || CHR(10);
  END IF;
END;
/

-- When sql_show is NO, will print sql_text_display only if manually specified.
BEGIN
  IF '&&sql_show.' = 'N' then
    -- SP2-1504: Cannot print uninitialized LOB variable "SQL_TEXT_DISPLAY"
    :sql_text_display := :sql_text_display;
  ELSE
    :sql_text_display := :sql_with_clause || TRIM(CHR(10) FROM :sql_text);
  END IF;
END;
/

-- Workarounds required for sql-formatter.js limitations (enabled when sql_format='Y')
BEGIN
  -- Change Oracle double slash comments to comment blocks
  :sql_text_display := REGEXP_REPLACE(:sql_text_display, '--(.+?)'||CHR(10),'/* \1 */'||CHR(10));
END;
/

PRINT sql_text_display

-- Remove spaces before or after
EXEC :sql_text := TRIM(:sql_text);

-- count
--SELECT '0' row_num FROM DUAL;
PRO &&hh_mm_ss. &&section_id..&&report_sequence.
EXEC :sql_text_display := REPLACE(REPLACE(:sql_text_display || ';', '<', CHR(38)||'lt;'), '>', CHR(38)||'gt;');
--SET TIMI ON
--SET SERVEROUT ON

-- TODO COPY FROM EDB

--SET TIMI OFF
--SET SERVEROUT OFF
--PRO
SPO OFF
@@&&fc_set_term_off.
HOS zip -j &&moat369_zip_filename. &&moat369_log. >> &&moat369_log3.

-- spools query
@@&&fc_spool_start.
SPO &&moat369_query.
SELECT :sql_with_clause || 'SELECT TO_CHAR(ROWNUM) row_num, v0.* FROM /* &&section_id..&&report_sequence. */ (' ||
        REPLACE(CHR(10) || TRIM(CHR(10) FROM :sql_text) || CHR(10), CHR(10) || CHR(10), CHR(10)) ||
       ') v0 WHERE ROWNUM <= &&max_rows.'
FROM DUAL;
SPO OFF
@@&&fc_spool_end.
SET HEA ON

-- update main report
SPO &&moat369_main_report. APP
PRO <li title="&&main_table.">&&title.
SPO OFF
HOS zip -j &&moat369_zip_filename. &&moat369_main_report. >> &&moat369_log3.

-- Check SQL format and highlight
@@&&fc_set_value_var_decode. sql_hl     &&moat369_conf_sql_highlight. 'N' 'N' &&sql_hl.
@@&&fc_set_value_var_decode. sql_format &&moat369_conf_sql_format.    'N' 'N' &&sql_format.

-- Put standard values on skip
@@&&fc_set_value_var_nvl2. skip_html       '&&skip_html.'       '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_text       '&&skip_text.'       '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_csv        '&&skip_csv.'        '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_lch        '&&skip_lch.'        '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_pch        '&&skip_pch.'        '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_bch        '&&skip_bch.'        '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_graph      '&&skip_graph.'      '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_map        '&&skip_map.'        '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_treemap    '&&skip_treemap.'    '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_html_spool '&&skip_html_spool.' '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_text_file  '&&skip_text_file.'  '&&fc_skip_script.' ''
@@&&fc_set_value_var_nvl2. skip_html_file  '&&skip_html_file.'  '&&fc_skip_script.' ''

-- execute one sql
@@&&skip_html.&&moat369_skip_html.moat369_9b_one_html.sql
@@&&skip_text.&&moat369_skip_text.moat369_9c_one_text.sql
@@&&skip_csv.&&moat369_skip_csv.moat369_9d_one_csv.sql
@@&&skip_lch.&&moat369_skip_line.moat369_gc_line_chart.sql
@@&&skip_pch.&&moat369_skip_pie.moat369_gc_pie_chart.sql
@@&&skip_bch.&&moat369_skip_bar.moat369_gc_bar_chart.sql
@@&&skip_graph.&&moat369_skip_graph.moat369_gc_graphviz_chart.sql
@@&&skip_map.&&moat369_skip_map.moat369_gc_map_chart.sql
@@&&skip_treemap.&&moat369_skip_treemap.moat369_gc_treemap_chart.sql
@@&&skip_html_spool.&&moat369_skip_html.moat369_9e_one_html_spool.sql
@@&&skip_text_file.&&moat369_skip_file.moat369_9f_one_text_file.sql
@@&&skip_html_file.&&moat369_skip_html.moat369_9g_one_html_file.sql

-- Check D3 Graphs
DEF moat369_d3_graph_valid_opts='|circle_packing|'
@@&&fc_def_empty_var. moat369_d3_graph_skip
@@&&fc_def_empty_var. d3_graph

COL skip_moat369_d3_graph NEW_V skip_moat369_d3_graph NOPRI
SELECT '&&fc_skip_script.' skip_moat369_d3_graph
FROM   DUAL
WHERE '&&d3_graph.' IS NULL
OR    '&&moat369_d3_graph_skip.' LIKE '%|&&d3_graph.|%'
OR    '&&moat369_d3_graph_valid_opts.' NOT LIKE '%|&&d3_graph.|%';
COL skip_moat369_d3_graph CLEAR
@@&&skip_moat369_d3_graph.moat369_d3_&&d3_graph..sql
UNDEF skip_moat369_d3_graph
--
HOS zip -j &&moat369_zip_filename. &&moat369_log2. >> &&moat369_log3.
HOS zip -j &&moat369_zip_filename. &&moat369_log3. > /dev/null

-- sql monitor long executions of sql from moat369
-- COL moat369_tuning_pack_for_sqlmon NEW_V moat369_tuning_pack_for_sqlmon;
-- COL skip_sqlmon_exec NEW_V skip_sqlmon_exec;
-- COL moat369_sql_text_100 NEW_V moat369_sql_text_100;
-- SELECT 'N' moat369_tuning_pack_for_sqlmon, '--' skip_sqlmon_exec FROM DUAL
-- /
-- SELECT '&&tuning_pack.' moat369_tuning_pack_for_sqlmon, NULL skip_sqlmon_exec, SUBSTR(sql_text, 1, 100) moat369_sql_text_100, elapsed_time FROM v$sql
-- WHERE sql_id = '&&moat369_prev_sql_id.' AND elapsed_time / 1e6 > 60 /* seconds */
-- /
-- @@&&skip_tuning.&&skip_sqlmon_exec.sqlmon.sql &&moat369_tuning_pack_for_sqlmon. &&moat369_prev_sql_id.
-- HOS zip -m &&moat369_zip_filename. sqlmon_&&moat369_prev_sql_id._&&current_time..zip >> &&moat369_log3.

-- If row_num is 0, return 0, otherwise subtract row_num_dif giving nothing less than a -1 result.
select trim(decode(&&row_num.,0,0,greatest(&&row_num.+(&&row_num_dif.),-1))) row_num from dual;

SET TERM ON
SPO &&moat369_log. APP
PRO
PRO &&row_num. rows selected.
SPO OFF
@@&&fc_set_term_off.

-- update main report
@@&&fc_spool_start.
SPO &&moat369_main_report. APP
PRO <small><em> (&&row_num.)</em></small>
PRO </li>
SPO OFF
@@&&fc_spool_end.
HOS zip -j &&moat369_zip_filename. &&moat369_main_report. >> &&moat369_log3.

-- cleanup
@@&&fc_reset_defs.
HOS rm -f &&moat369_query.

--
DEF moat369_column_print = 'YES'

-- report sequence
EXEC :repo_seq := :repo_seq + 1;
SELECT TO_CHAR(:repo_seq) report_sequence FROM DUAL;