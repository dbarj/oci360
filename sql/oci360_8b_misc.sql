-----------------------------------------

DEF title = 'Control - Failed Tables'
DEF main_table = '&&oci360_obj_jsontabs.'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   "&&oci360_obj_jsontabs." t1
WHERE  is_processed=1 and is_created=0
}';
END;
/

DEF foot = 'If you see any lines here, check file "&&oci360_log_json_nopath." (last section of the tool) for ORA- errors.<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Control - Json Tables'
DEF main_table = '&&oci360_obj_jsontabs.'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   "&&oci360_obj_jsontabs." t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Control - Json Columns'
DEF main_table = '&&oci360_obj_jsoncols.'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   "&&oci360_obj_jsoncols." t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'OCI360 Tables'
DEF main_table = 'all_tables'

BEGIN
  :sql_text := q'{
SELECT *
FROM   all_tables
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name like 'OCI360\_%' ESCAPE '\'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'OCI360 Columns'
DEF main_table = 'all_tab_columns'

BEGIN
  :sql_text := q'{
SELECT *
FROM   all_tab_columns
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name like 'OCI360\_%' ESCAPE '\'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'OCI360 User Segments'
DEF main_table = 'user_segments'

BEGIN
  :sql_text := q'{
SELECT   SEGMENT_NAME, SEGMENT_TYPE, TABLESPACE_NAME, sum(bytes)/power(1024,2) "MBs"
FROM     user_segments
WHERE    SEGMENT_NAME like 'OCI360\_%' ESCAPE '\'
GROUP BY SEGMENT_NAME, SEGMENT_TYPE, TABLESPACE_NAME
ORDER BY 4 DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'OCI360 Used Space'
DEF main_table = 'user_segments'

BEGIN
  :sql_text := q'{
SELECT   sum(bytes)/power(1024,2) "MBs"
FROM     user_segments
WHERE    SEGMENT_NAME like 'OCI360\_%' ESCAPE '\'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

@@&&fc_clean_file_name. "moat369_log" "moat369_log_nopath" "PATH"
DEF title = 'File: &&moat369_log_nopath.'
UNDEF moat369_log_nopath

DEF one_spool_text_file = '&&moat369_log.'
DEF one_spool_text_file_rename = 'N'
DEF skip_html = '--'
DEF skip_text_file = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&fc_clean_file_name. "moat369_log2" "moat369_log2_nopath" "PATH"
DEF title = 'File: &&moat369_log2_nopath.'
UNDEF moat369_log2_nopath

DEF one_spool_text_file = '&&moat369_log2.'
DEF one_spool_text_file_rename = 'N'
DEF skip_html = '--'
DEF skip_text_file = ''
@@&&9a_pre_one.

-----------------------------------------

@@&&fc_clean_file_name. "moat369_log3" "moat369_log3_nopath" "PATH"
DEF title = 'File: &&moat369_log3_nopath.'
UNDEF moat369_log3_nopath

DEF one_spool_text_file = '&&moat369_log3.'
DEF one_spool_text_file_rename = 'N'
DEF skip_html = '--'
DEF skip_text_file = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'File: &&oci360_log_json_nopath.'

DEF one_spool_text_file = '&&oci360_log_json.'
DEF one_spool_text_file_rename = 'N'
DEF skip_html = '--'
DEF skip_text_file = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'File: &&oci360_log_csv_nopath.'

DEF one_spool_text_file = '&&oci360_log_csv.'
DEF one_spool_text_file_rename = 'N'
DEF skip_html = '--'
DEF skip_text_file = ''
@@&&9a_pre_one.

-----------------------------------------