DEF oci360_obj_dir       = 'OCI360_DIR'
DEF oci360_obj_jsoncols  = 'OCI360_JSONCOLS'
DEF oci360_obj_jsontabs  = 'OCI360_JSONTABS'
DEF oci360_obj_metadata  = 'OCI360_METADATA'
DEF oci360_obj_pricing   = 'OCI360_PRICING'
DEF oci360_obj_location  = 'OCI360_LOCATION'
DEF oci360_obj_shape     = 'OCI360_SHAPE_SPECS'

@@&&fc_def_empty_var.     oci360_pre_obj_schema
@@&&fc_set_value_var_nvl. 'oci360_obj_schema' '&&oci360_pre_obj_schema.' 'SYSTEM'

-- Only when running as SYS, the code will change the current schema to another user defined by oci360_pre_obj_schema (SYSTEM user if null)
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

COL oci360_user_curschema  NEW_V oci360_user_curschema  nopri
COL oci360_user_session    NEW_V oci360_user_session    nopri
COL oci360_temp_tablespace NEW_V oci360_temp_tablespace nopri

select sys_context('userenv','current_schema') oci360_user_curschema,
       sys_context('userenv','session_user')   oci360_user_session
from dual;

-- Temporary tablespace to load JSON files when running as SYS
select decode(SEGMENT_SPACE_MANAGEMENT,'MANUAL','SYSAUX',DEFAULT_TABLESPACE) oci360_temp_tablespace 
from user_users, user_tablespaces
where DEFAULT_TABLESPACE = TABLESPACE_NAME;

COL oci360_user_curschema  CLEAR
COL oci360_user_session    CLEAR
COL oci360_temp_tablespace CLEAR


DEF oci360_obj_dir = '&&oci360_obj_dir._&&oci360_user_curschema.'
DEF oci360_obj_dir_del = 'Y'

SET TERM ON SERVEROUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Check if session user is either SYS or is the same as current schema.
BEGIN
  IF '&&oci360_user_curschema.' != '&&oci360_user_session.' AND '&&oci360_user_session.'!='SYS' THEN
    RAISE_APPLICATION_ERROR(-20000, 'To use oci360_pre_obj_schema, you must be connected as SYS.');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

@@&&oci360_loc_skip.&&moat369_sw_folder./oci360_fc_directory.sql

------------------------------------------
-- "&&oci360_obj_jsoncols."
------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_jsoncols." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_jsoncols."
(
  source       VARCHAR2(100),
  jpath        VARCHAR2(200),
  type         VARCHAR2(10),
  new_col_name VARCHAR2(100),
  CONSTRAINT "&&oci360_obj_jsoncols._PK" PRIMARY KEY (source,jpath),
  CONSTRAINT "&&oci360_obj_jsoncols._UK" UNIQUE (source,new_col_name)
)
COMPRESS NOPARALLEL NOMONITORING;

@@&&fc_def_output_file. oci360_step_file 'oci360_load_jsoncols.sql'
HOS cat &&oci360_columns. | sort -u | while read line || [ -n "$line" ]; do echo "INSERT INTO \"&&oci360_obj_jsoncols.\" VALUES ('$(&&cmd_awk. -F',' '{print $1}' <<< "$line")','$(&&cmd_awk. -F',' '{print $2}' <<< "$line")','$(&&cmd_awk. -F',' '{print $3}' <<< "$line")','$(&&cmd_awk. -F',' '{print $4}' <<< "$line")');"; done >> &&oci360_step_file.
HOS echo 'COMMIT;' >> &&oci360_step_file.
@&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

------------------------------------------
-- "&&oci360_obj_jsontabs."
------------------------------------------

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_obj_jsontabs." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_obj_jsontabs."
(
  source       VARCHAR2(100 CHAR),
  table_name   VARCHAR2(100 CHAR),
  description  VARCHAR2(100 CHAR),
  in_zip       NUMBER(1) DEFAULT 0, -- Tables that are inside the exported ZIP file
  in_col_csv   NUMBER(1) DEFAULT 0, -- Tables that are inside the oci_cols_json.csv
  is_processed NUMBER(1) DEFAULT 0,
  is_created   NUMBER(1) DEFAULT 0,
  table_type   VARCHAR2(4 CHAR),
  CONSTRAINT "&&oci360_obj_jsontabs._PK" PRIMARY KEY (source),
  CONSTRAINT "&&oci360_obj_jsontabs._UK" UNIQUE (table_name),
  CONSTRAINT "&&oci360_obj_jsontabs._CK1" CHECK (table_type in ('JSON','CSV')),
  CONSTRAINT "&&oci360_obj_jsontabs._CK2" CHECK (in_zip in (0,1) and in_col_csv in (0,1) and is_processed in (0,1) and is_created in (0,1))
)
COMPRESS NOPARALLEL NOMONITORING;

@@&&fc_def_output_file. oci360_step_file 'oci360_load_jsontabs.sql'
HOS cat &&oci360_tables. | sort -u | while read line || [ -n "$line" ]; do echo "INSERT INTO \"&&oci360_obj_jsontabs.\" (source,table_name,description,table_type) VALUES ('$(&&cmd_awk. -F',' '{print $1}' <<< "$line")','$(&&cmd_awk. -F',' '{print $2}' <<< "$line")','$(&&cmd_awk. -F',' '{print $3}' <<< "$line")','JSON');"; done >> &&oci360_step_file.
HOS echo 'COMMIT;' >> &&oci360_step_file.
@&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

INSERT INTO "&&oci360_obj_jsontabs." (source,table_name,table_type)
VALUES ('reports_usage-', 'OCI360_REPORTS_USAGE','CSV');

-- Commented while not yet implemented.
-- INSERT INTO "&&oci360_obj_jsontabs." (source,table_name,table_type)
-- VALUES ('reports_cost-', 'OCI360_REPORTS_COST','CSV');

COMMIT;

------------------------------------------

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
  CONSTRAINT "&&oci360_obj_location._PK" PRIMARY KEY (ID)
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

-- Check if json file is gzip and update file name
@@&&fc_def_output_file. oci360_step_file 'oci360_check_json_zip.sql'
HOS cat &&oci360_json_files. | while read line || [ -n "$line" ]; do echo "UPDATE \"&&oci360_obj_jsontabs.\" SET source = source || '.gz' WHERE source || '.gz'='$line';"; echo "UPDATE \"&&oci360_obj_jsoncols.\" SET source = source || '.gz' WHERE source || '.gz'='$line';"; done > &&oci360_step_file.
HOS echo 'COMMIT;' >> &&oci360_step_file.
@&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

-- Check table in json zip
@@&&fc_def_output_file. oci360_step_file 'oci360_check_json_zip.sql'
HOS cat &&oci360_json_files. | while read line || [ -n "$line" ]; do echo "UPDATE \"&&oci360_obj_jsontabs.\" SET in_zip=1 WHERE source='$line';"; done > &&oci360_step_file.
HOS echo 'COMMIT;' >> &&oci360_step_file.
@&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

-- Check table in json csv
@@&&fc_def_output_file. oci360_step_file 'oci360_check_json_csv.sql'
HOS cat &&oci360_columns. | &&cmd_awk. -F',' '{print $1}' | sort -u | while read line || [ -n "$line" ]; do echo "UPDATE \"&&oci360_obj_jsontabs.\" SET in_col_csv=1 WHERE source='$line';"; done > &&oci360_step_file.
HOS echo 'COMMIT;' >> &&oci360_step_file.
@&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

-- Check table in csv zip - report tables
@@&&fc_def_output_file. oci360_step_file 'oci360_check_csv_zip.sql'
HOS cat &&oci360_csv_files. | &&cmd_grep. -o -E '^.*-' | sort -u | while read line || [ -n "$line" ]; do echo "UPDATE \"&&oci360_obj_jsontabs.\" SET in_zip=1 WHERE source='$line';"; done > &&oci360_step_file.
HOS echo 'COMMIT;' >> &&oci360_step_file.
@&&oci360_step_file.
@@&&fc_zip_driver_files. &&oci360_step_file.
UNDEF oci360_step_file

--------------------------------------------------
-- Check if tables are pre-loaded or on-demand. --
--------------------------------------------------

@@&&fc_def_output_file. step_json_full_loader 'step_json_full_loader.sql'

-- Convert JSON and CSV into tables
@@&&fc_spool_start.
SPO &&step_json_full_loader.
SELECT '@@&&fc_json_loader. ' || table_name
FROM "&&oci360_obj_jsontabs."
WHERE (in_zip=1 or in_col_csv=1) and table_type='JSON'
ORDER BY 1;
SELECT '@@&&fc_json_loader. ' || table_name
FROM "&&oci360_obj_jsontabs."
WHERE in_zip=1 and table_type='CSV'
ORDER BY 1;
SPO OFF
@@&&fc_spool_end.

-- HOS &&cmd_awk. -F',' '{print("@@&&fc_json_loader. "$2)}' &&oci360_tables. > &&step_json_full_loader.

COL skip_json_full_loader NEW_V skip_json_full_loader
SELECT DECODE('&&oci360_load_mode.','PRE_LOAD','','&&fc_skip_script.') skip_json_full_loader FROM DUAL;
COL skip_json_full_loader clear

@@&&skip_json_full_loader.&&step_json_full_loader.

-- Disable fc_json_loader / fc_csv_loader if did a full PRE_LOAD or if it is OFF
COL fc_json_loader NEW_V fc_json_loader
COL fc_csv_loader  NEW_V fc_csv_loader
SELECT '&&fc_skip_script.' fc_json_loader,
       '&&fc_skip_script.' fc_csv_loader
FROM DUAL WHERE '&&oci360_load_mode.' != 'ON_DEMAND';
COL fc_json_loader clear
COL fc_csv_loader  clear

@@&&fc_zip_driver_files. &&step_json_full_loader.
UNDEF step_json_full_loader skip_json_full_loader