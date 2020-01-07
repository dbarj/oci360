STORE SET original_settings REPLACE
@@moat369_0b_pre.sql
DEF section_id = '0a'
EXEC DBMS_APPLICATION_INFO.SET_MODULE('&&moat369_prefix.','&&section_id.')

@@&&fc_reset_defs.

DEF moat369_skip_check_file = ''
@@&&fc_check_file_exists. '&&moat369_sw_folder./&&moat369_sw_name._0a_pre.sql' 'moat369_skip_check_file' '' '&&fc_skip_script.'
@@&&moat369_skip_check_file.&&moat369_sw_folder./&&moat369_sw_name._0a_pre.sql
UNDEF moat369_skip_check_file

-- Report # of columns
VAR moat369_total_cols number
EXEC :moat369_total_cols := &&moat369_sw_rpt_cols.; 

@@&&fc_spool_start.
SPO &&moat369_main_report. APP
PRO <!--BEGIN_SENSITIVE_DATA-->
PRO <table><tr class="main">
SPO OFF
@@&&fc_spool_end.

@@&&fc_def_output_file. step_main_file_driver 'step_main_file_driver_header.sql'

SET SERVEROUT ON

@@&&fc_spool_start.
SPO &&step_main_file_driver.
BEGIN
FOR I IN 1 .. :moat369_total_cols
LOOP
    IF I = 1 THEN
	   DBMS_OUTPUT.PUT_LINE('PRO <td class="c">' || I || '/' || :moat369_total_cols || '</td>');
	ELSE
	   DBMS_OUTPUT.PUT_LINE('PRO <td class="c i' || I || '">' || I || '/' || :moat369_total_cols || '</td>');
	END IF;
END LOOP;
END;
/
SPO OFF

SPO &&moat369_main_report. APP
@&&step_main_file_driver.
SPO OFF
@@&&fc_spool_end.


@@&&fc_zip_driver_files. &&step_main_file_driver.
UNDEF step_main_file_driver

@@&&fc_spool_start.
SPO &&moat369_main_report. APP
PRO </tr><tr class="main"><td>
PRO <img src="&&moat369_sw_logo_file." alt="&&moat369_sw_name." height="228" width="auto"
PRO title="&&moat369_sw_logo_title_1.
PRO &&moat369_sw_logo_title_2.
PRO &&moat369_sw_logo_title_3.
PRO &&moat369_sw_logo_title_4.
PRO &&moat369_sw_logo_title_5.
PRO &&moat369_sw_logo_title_6.
PRO &&moat369_sw_logo_title_7.
PRO &&moat369_sw_logo_title_8.">
PRO <br>
SPO OFF
@@&&fc_spool_end.

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


@@&&fc_def_output_file. step_main_file_driver 'step_main_file_driver_columns.sql'

@@&&fc_spool_start.
SPO &&step_main_file_driver.
SET DEF OFF
DECLARE
  PROCEDURE put_line(p_line IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_line);
  END put_line;
BEGIN
FOR I IN 1 .. :moat369_total_cols
LOOP
	put_line('@@&&fc_load_column. ' || I);
	put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
	put_line('@@&&fc_spool_start.');
	put_line('SPO &&moat369_main_report. APP');
	put_line('PRO');
	IF I < :moat369_total_cols THEN
      put_line('PRO </td><td class="i' || TO_CHAR(I+1) || '">');
    ELSE
      put_line('PRO </td>');
    END IF;
	put_line('PRO');
	put_line('SPO OFF');
	put_line('@@&&fc_spool_end.');
END LOOP;
END;
/
SPO OFF
SET DEF ON

@&&step_main_file_driver.

@@&&fc_spool_end.


@@&&fc_zip_driver_files. &&step_main_file_driver.
UNDEF step_main_file_driver

-- main footer
@@&&fc_spool_start.
SPO &&moat369_main_report. APP;
PRO </tr></table>
PRO <!--END_SENSITIVE_DATA-->
SPO OFF;

-- log footer
SPO &&moat369_log. APP;
PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
DEF;
SHOW PARAMETERS;
PRO
PRO end log
SPO OFF;
@@&&fc_spool_end.

DEF section_id = '0c'
EXEC DBMS_APPLICATION_INFO.SET_MODULE('&&moat369_prefix.','&&section_id.')

-- Load custom post if exists
DEF moat369_skip_check_file = ''
@@&&fc_check_file_exists. '&&moat369_sw_folder./&&moat369_sw_name._0b_post.sql' 'moat369_skip_check_file' '' '&&fc_skip_script.'
@@&&moat369_skip_check_file.&&moat369_sw_folder./&&moat369_sw_name._0b_post.sql
UNDEF moat369_skip_check_file

@@moat369_0c_post.sql

EXEC DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);

@@&&fc_encrypt_output. &&moat369_zip_filename..zip

-- Restore Original SETs
@original_settings
HOS rm -f original_settings.sql

HOS if [ -f &&moat369_zip_filename..zip ]; then unzip -l &&moat369_zip_filename.; fi
PRO "End &&moat369_sw_name.. Output: &&moat369_zip_filename..zip"