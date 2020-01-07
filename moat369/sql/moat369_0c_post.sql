 -- End Time
VAR moat369_main_time1 NUMBER;
EXEC :moat369_main_time1 := DBMS_UTILITY.GET_TIME;

COL total_hours NEW_V total_hours;
SELECT 'Tool execution hours: '||TO_CHAR(ROUND((:moat369_main_time1 - :moat369_main_time0) / 100 / 3600, 3), '990.000')||'.' total_hours FROM DUAL;
COL total_hours clear

@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
@@moat369_0e_html_footer.sql
SPO OFF;
@@&&fc_spool_end.

@@&&fc_encode_html. &&moat369_main_report. 'INDEX'

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- turing trace off
ALTER SESSION SET SQL_TRACE = FALSE;
@@&&skip_tkprof.moat369_0g_tkprof.sql

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


@@&&fc_spool_start.
-- readme
SPO &&moat369_readme.
PRO 1. Unzip &&moat369_zip_filename_nopath..zip into a directory
PRO 2. Review &&moat369_main_report_nopath.
SPO OFF;
@@&&fc_spool_end.

-- Alert log (3 methods)
COL db_name_upper NEW_V db_name_upper
COL db_name_lower NEW_V db_name_lower
COL background_dump_dest NEW_V background_dump_dest
SELECT UPPER(SYS_CONTEXT('USERENV', 'DB_NAME')) db_name_upper FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'DB_NAME')) db_name_lower FROM DUAL;
SELECT value background_dump_dest FROM v$parameter WHERE name = 'background_dump_dest';
COL db_name_upper clear
COL db_name_lower clear
COL background_dump_dest clear
HOS cp &&background_dump_dest./alert_&&db_name_upper.*.log &&moat369_sw_output_fdr./ >> &&moat369_log3. 2> &&moat369_log3.
HOS cp &&background_dump_dest./alert_&&db_name_lower.*.log &&moat369_sw_output_fdr./ >> &&moat369_log3. 2> &&moat369_log3.
HOS cp &&background_dump_dest./alert_&&_connect_identifier..log &&moat369_sw_output_fdr./ >> &&moat369_log3. 2> &&moat369_log3.
-- Altered to be compatible with SunOS:
-- HOS rename alert_ &&moat369_alert._ alert_*.log >> &&moat369_log3.
HOS ls -1 &&moat369_sw_output_fdr./alert_*.log 2> &&moat369_log3. | while read line || [ -n "$line" ]; do mv $line &&moat369_alert._$(basename "$line"); done >> &&moat369_log3.

-- encrypt final files
--@&&fc_convert_txt_to_html. moat369_log
--@&&fc_encode_html. &&moat369_log.
--@&&fc_convert_txt_to_html. moat369_log2
--@&&fc_encode_html. &&moat369_log2.

-- zip
@@&&fc_def_empty_var. moat369_d3_usage
HOS if [ '&&moat369_d3_usage.' == 'Y' ]; then zip -j &&moat369_zip_filename. &&moat369_fdr_js./d3.min.js >> &&moat369_log3.; fi

@@&&fc_def_empty_var. moat369_tf_usage
@@&&fc_clean_file_name. "moat369_log3" "moat369_log3_nopath" "PATH"
--HOS if [ '&&moat369_tf_usage.' == 'Y' ]; then cp -av &&moat369_fdr_js./tablefilter/ &&moat369_sw_output_fdr./ >> &&moat369_log3.; cd &&moat369_sw_output_fdr./; zip -rm &&moat369_zip_filename_nopath. tablefilter/ >> &&moat369_log3_nopath.; fi 
HOS if [ '&&moat369_tf_usage.' == 'Y' ]; then v_zipfdr=$(dirname "&&moat369_zip_filename."); cp -av &&moat369_fdr_js./tablefilter/ &&moat369_sw_output_fdr./ >> &&moat369_log3.; cd &&moat369_sw_output_fdr./; zip -rm $(cd - >/dev/null; cd "${v_zipfdr}"; pwd)/&&moat369_zip_filename_nopath. tablefilter/ >> &&moat369_log3_nopath.; fi 
-- Fix above cmd as cur folder can be RO

HOS if [ -z '&&moat369_pre_sw_key_file.' ]; then rm -f &&enc_key_file.; fi
HOS zip -mj &&moat369_zip_filename. &&moat369_alert.*.log >> &&moat369_log3.
HOS if [ '&&moat369_conf_incl_opatch.' == 'Y' ]; then zip -j &&moat369_opatch. $ORACLE_HOME/cfgtoollogs/opatch/opatch* >> &&moat369_log3.; fi
HOS if [ -f &&moat369_opatch. ]; then zip -mj &&moat369_zip_filename. &&moat369_opatch. >> &&moat369_log3.; fi
HOS zip -mj &&moat369_zip_filename. &&moat369_driver.           >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_log2.             >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_tkprof._sort.txt  >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_log.              >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_main_report.      >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_readme.           >> &&moat369_log3.
HOS unzip -l &&moat369_zip_filename.                            >> &&moat369_log3.
HOS zip -mj &&moat369_zip_filename. &&moat369_log3.             > /dev/null
SET TERM ON;
