DEF oci360_obj_dir       = 'OCI360_DIR'
-- DEF oci360_obj_exttab    = 'OCI360_EXTTAB'  - Moved to json_converter
DEF oci360_obj_jsoncols  = 'OCI360_JSONCOLS'
DEF oci360_obj_jsontabs  = 'OCI360_JSONTABS'
DEF oci360_obj_metadata  = 'OCI360_METADATA'
DEF oci360_obj_pricing   = 'OCI360_PRICING'
DEF oci360_obj_location  = 'OCI360_LOCATION'
DEF oci360_obj_shape     = 'OCI360_SHAPE_SPECS'

@@&&fc_def_empty_var.     oci360_pre_obj_schema
@@&&fc_set_value_var_nvl. 'oci360_obj_schema' '&&oci360_pre_obj_schema.' 'SYSTEM'

DECLARE
 v_session_user   VARCHAR2(30);
 v_current_schema VARCHAR2(30);
BEGIN
  select sys_context('userenv','current_schema'),
         sys_context('userenv','session_user')
  into v_current_schema, v_session_user
  from dual;
  IF (v_session_user = 'SYS' and v_current_schema = 'SYS')
  THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA=&&oci360_obj_schema.';
  END IF;
END;
/

COL oci360_user_curschema NEW_V oci360_user_curschema nopri
COL oci360_user_session   NEW_V oci360_user_session   nopri

select sys_context('userenv','current_schema') oci360_user_curschema,
       sys_context('userenv','session_user')   oci360_user_session
from dual;

COL oci360_user_curschema CLEAR
COL oci360_user_session   CLEAR

DEF oci360_obj_dir = '&&oci360_obj_dir._&&oci360_user_curschema.'
DEF oci360_obj_dir_del = 'Y'

SET TERM ON SERVEROUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  FHANDLE    SYS.UTL_FILE.FILE_TYPE;
  INSUFFICIENT_PRIVS EXCEPTION;
  PRAGMA EXCEPTION_INIT(INSUFFICIENT_PRIVS, -1031);
  V_FOUND     NUMBER := 0;
  V_FILE      VARCHAR2(30) := 'test.txt';
  V_CONTENT   VARCHAR2(30) := 'test content';
  V_READ      VARCHAR2(30);
  V_DIRECTORY VARCHAR2(30);
BEGIN
  DBMS_OUTPUT.ENABLE();
  DBMS_OUTPUT.PUT_LINE('Trying to create directory  "&&oci360_obj_dir." on ''&&moat369_sw_output_fdr_fpath.''.');
  BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY "&&oci360_obj_dir." AS ''&&moat369_sw_output_fdr_fpath.''';
    DBMS_OUTPUT.PUT_LINE('Directory created and will be dropped on the end of OCI360 execution.');
    RETURN;
  EXCEPTION
    WHEN INSUFFICIENT_PRIVS THEN
      DBMS_OUTPUT.PUT_LINE('User has no privilege to create directory. Checking existing directories on output path..');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXCEPTION: SQLCODE=' || SQLCODE || '  SQLERRM=' || SQLERRM);
  END;
  FOR DIR IN (select directory_name
              from   all_directories
              where  regexp_replace(directory_path || '/','[/]+','/') = regexp_replace('&&moat369_sw_output_fdr_fpath.' || '/','[/]+','/')
             ) LOOP
    V_DIRECTORY := DIR.DIRECTORY_NAME;
    DBMS_OUTPUT.PUT_LINE('Found "' || V_DIRECTORY || '". Checking read/write permissions..');
    BEGIN
      FHANDLE := SYS.UTL_FILE.FOPEN(V_DIRECTORY, V_FILE, 'w');
      SYS.UTL_FILE.PUT(FHANDLE, V_CONTENT);
      SYS.UTL_FILE.FCLOSE(FHANDLE);
      FHANDLE := SYS.UTL_FILE.FOPEN(V_DIRECTORY, V_FILE, 'r');
      SYS.UTL_FILE.GET_LINE(FHANDLE,V_READ);
      SYS.UTL_FILE.FREMOVE(V_DIRECTORY, V_FILE);
      IF V_CONTENT = V_READ THEN
        DBMS_OUTPUT.PUT_LINE('Directory "' || V_DIRECTORY || '" will be used.');
        V_FOUND := 1;
        EXIT;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION: SQLCODE=' || SQLCODE || '  SQLERRM=' || SQLERRM);
    END;
  END LOOP;
  IF V_FOUND = 0 THEN
   RAISE_APPLICATION_ERROR(-20000, 'You have no permissions to create directory or use any on "&&moat369_sw_output_fdr_fpath." path.' || CHR(10) ||
   'Please either grant CREATE ANY DIRECTORY to "&&oci360_user_session." or create one as DBA and give READ/WRITE permissions to "&&oci360_user_session.".');
  END IF;
  FHANDLE := SYS.UTL_FILE.FOPEN(V_DIRECTORY, 'directory.sql', 'w');
  SYS.UTL_FILE.PUT_LINE(FHANDLE, 'DEF oci360_obj_dir = '''|| V_DIRECTORY ||'''');
  SYS.UTL_FILE.PUT_LINE(FHANDLE, 'DEF oci360_obj_dir_del = ''N''');
  SYS.UTL_FILE.FCLOSE(FHANDLE);
END;
/

WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

-- Check table in json zip
@@&&fc_def_output_file. oci360_change_obj_dir 'oci360_change_obj_dir.sql'
HOS touch &&oci360_change_obj_dir.
HOS if [ -f "&&moat369_sw_output_fdr./directory.sql" ]; then echo "@&&moat369_sw_output_fdr./directory.sql"; fi >> &&oci360_change_obj_dir.
HOS if [ -f "&&moat369_sw_output_fdr./directory.sql" ]; then echo "! rm -f &&moat369_sw_output_fdr./directory.sql"; fi >> &&oci360_change_obj_dir.
@&&oci360_change_obj_dir.
HOS rm -f &&oci360_change_obj_dir.

-- BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_exttab." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
-- /
-- 
-- CREATE TABLE "&&oci360_obj_exttab."
-- (
--   json_filename varchar2(100),
--   json_document CLOB
-- )
-- ORGANIZATION EXTERNAL
-- (  DEFAULT DIRECTORY "&&oci360_obj_dir."
--    ACCESS PARAMETERS
--      (records delimited BY newline
--       nologfile nobadfile nodiscardfile
--       fields
--           terminated BY ','
--           optionally enclosed BY '"'
--           notrim
--           missing field VALUES are NULL
--           (
--             json_filename CHAR(100)
--           )
--           COLUMN TRANSFORMS (json_document FROM LOBFILE (json_filename) FROM ("&&oci360_obj_dir.") CLOB)
--     )
--    LOCATION ('&&oci360_json_files_nopath.')
-- )
-- REJECT LIMIT 0
-- NOPARALLEL
-- NOMONITORING
-- ;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_jsoncols." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_jsoncols."
(
  source       VARCHAR2(100),
  jpath        VARCHAR2(200),
  type         VARCHAR2(10),
  new_col_name VARCHAR2(100)
)
ORGANIZATION EXTERNAL
(  DEFAULT DIRECTORY "&&oci360_obj_dir."
   ACCESS PARAMETERS 
     (records delimited BY newline
      nologfile nobadfile nodiscardfile
      fields
          terminated BY ','
          optionally enclosed BY '"'
          notrim
          missing field VALUES are NULL
    )
   LOCATION ('&&oci360_jsoncol_file_nopath.')
)
REJECT LIMIT 0
NOPARALLEL
NOMONITORING
;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_jsontabs._2" PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_jsontabs._2"
(
  source       VARCHAR2(100),
  table_name   VARCHAR2(100),
  description  VARCHAR2(100)
)
ORGANIZATION EXTERNAL
(  DEFAULT DIRECTORY "&&oci360_obj_dir."
   ACCESS PARAMETERS 
     (records delimited BY newline
      nologfile nobadfile nodiscardfile
      fields
          terminated BY ','
          optionally enclosed BY '"'
          notrim
          missing field VALUES are NULL
    )
   LOCATION ('&&oci360_jsontab_file_nopath.')
)
REJECT LIMIT 0
NOPARALLEL
NOMONITORING
;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_jsontabs." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_jsontabs."
(
  source,
  table_name,
  description,
  in_zip, -- Tables that are inside the exported JSON ZIP file
  in_csv, -- Tables that are inside the oci_cols_json.csv
  is_processed,
  CONSTRAINT "&&oci360_obj_jsontabs._PK" PRIMARY KEY (source),
  CONSTRAINT "&&oci360_obj_jsontabs._UK" UNIQUE (table_name)
)
COMPRESS NOPARALLEL NOMONITORING
AS SELECT source,
          table_name,
          description,
          0,
          0,
          0
FROM "&&oci360_obj_jsontabs._2";

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_jsontabs._2" PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Don't drop metadata table if LOAD is disabled.
BEGIN IF '&&oci360_load_mode.' != 'OFF' THEN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_metadata." PURGE'; END IF; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_metadata."
(
  source        VARCHAR2(100),
  jpath         VARCHAR2(200),
  type          VARCHAR2(10),
  tlength       NUMBER,
  pref_col_name VARCHAR2(100),
  new_col_name  VARCHAR2(100),
  frequency     NUMBER,
  low_value     VARCHAR2(25),
  high_value    VARCHAR2(25),
  num_nulls     NUMBER,
  created_on_table VARCHAR2(1),
  last_analyzed VARCHAR2(20),
  CONSTRAINT "&&oci360_obj_metadata._PK" PRIMARY KEY (source,jpath,type)
)
COMPRESS NOPARALLEL NOMONITORING;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_pricing." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_pricing."
(
  SUBJECT        VARCHAR2(100),
  LIC_TYPE       VARCHAR2(100),
  INST_TYPE      VARCHAR2(100),
  PAYG           NUMBER(7,4),
  MF             NUMBER(7,4),
  GSI_PRODUCT_ID VARCHAR2(10),
  CONSTRAINT "&&oci360_obj_pricing._UK" UNIQUE (SUBJECT,LIC_TYPE,INST_TYPE)
)
COMPRESS NOPARALLEL NOMONITORING;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_location." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_location."
(
  NAME           VARCHAR2(100),
  TOTAL_ADS      NUMBER,
  LATITUDE       NUMBER(9,7),
  LONGITUDE      NUMBER(10,7),
  ID             VARCHAR2(100),
  DESCRIPTION    VARCHAR2(100),
  CONSTRAINT "&&oci360_obj_location._PK" PRIMARY KEY (NAME)
)
COMPRESS NOPARALLEL NOMONITORING;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_shape." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_shape."
(
  SHAPE          VARCHAR2(100),
  OCPU           NUMBER(3),
  MEMORY_GB      NUMBER(3),
  LOCAL_DISK_TB  NUMBER(4,2),
  NETWORK_GBPS   NUMBER(5,2),
  GPU            NUMBER(1),
  GSI_PRODUCT_ID VARCHAR2(10),
  CONSTRAINT "&&oci360_obj_shape._PK" PRIMARY KEY (SHAPE)
)
COMPRESS NOPARALLEL NOMONITORING;

-- Load extra tables
@@&&moat369_sw_folder./oci360_fc_oci_costs.sql
@@&&moat369_sw_folder./oci360_fc_oci_extra_tables.sql

-- Check table in json zip
@@&&fc_def_output_file. oci360_check_json_zip 'oci360_check_json_zip.sql'
HOS cat &&oci360_json_files. | while read line || [ -n "$line" ]; do echo "UPDATE \"&&oci360_obj_jsontabs.\" SET in_zip=1 WHERE source='$line';"; done > &&oci360_check_json_zip.
HOS echo 'COMMIT;' >> &&oci360_check_json_zip.
@&&oci360_check_json_zip.
@@&&fc_zip_driver_files. &&oci360_check_json_zip.
UNDEF oci360_check_json_zip

-- Check table in json csv
@@&&fc_def_output_file. oci360_check_json_csv 'oci360_check_json_csv.sql'
HOS cat &&oci360_jsoncol_file. | &&cmd_awk. -F',' '{print $1}' | sort -u | while read line || [ -n "$line" ]; do echo "UPDATE \"&&oci360_obj_jsontabs.\" SET in_csv=1 WHERE source='$line';"; done > &&oci360_check_json_csv.
HOS echo 'COMMIT;' >> &&oci360_check_json_csv.
@&&oci360_check_json_csv.
@@&&fc_zip_driver_files. &&oci360_check_json_csv.
UNDEF oci360_check_json_csv

--------------------------------------------------
-- Check if tables are pre-loaded or on-demand. --
--------------------------------------------------

@@&&fc_def_output_file. step_json_full_loader 'step_json_full_loader.sql'

-- Load Json into tables
@@&&fc_spool_start.
SPO &&step_json_full_loader.
SELECT '@@&&fc_json_loader. ' || table_name FROM "&&oci360_obj_jsontabs." WHERE in_zip=1 or in_csv=1;
SPO OFF
@@&&fc_spool_end.

-- HOS &&cmd_awk. -F',' '{print("@@&&fc_json_loader. "$2)}' &&oci360_tables. > &&step_json_full_loader.

COL skip_json_full_loader NEW_V skip_json_full_loader
SELECT DECODE('&&oci360_load_mode.','PRE_LOAD','','&&fc_skip_script.') skip_json_full_loader FROM DUAL;
COL skip_json_full_loader clear

@@&&skip_json_full_loader.&&step_json_full_loader.

-- Disable fc_json_loader if did a full PRE_LOAD or if it is OFF
COL fc_json_loader NEW_V fc_json_loader
SELECT '&&fc_skip_script.' fc_json_loader
FROM DUAL WHERE '&&oci360_load_mode.' != 'ON_DEMAND';
COL fc_json_loader clear

@@&&fc_zip_driver_files. &&step_json_full_loader.
UNDEF step_json_full_loader skip_json_full_loader