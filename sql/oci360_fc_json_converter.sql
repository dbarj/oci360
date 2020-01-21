-- Required:
DEF oci360_in_target_table   = "&&1."
DEF oci360_in_source_file    = "&&2."

UNDEF 1 2

DEF oci360_temp_obj_prefix = "OCI360_TMP_&&oci360_user_curschema."
DEF oci360_temp_table = "&&oci360_temp_obj_prefix._TABLE"
DEF oci360_temp_clob  = "&&oci360_temp_obj_prefix._CLOB"
DEF oci360_temp_check = "&&oci360_temp_obj_prefix._CHECK"
DEF oci360_temp_view  = "&&oci360_temp_obj_prefix._VIEW"
DEF oci360_temp_index = "&&oci360_temp_obj_prefix._INDEX"
DEF oci360_temp_exttab = 'OCI360_EXTTAB'
DEF oci360_temp_extout = 'file.txt'

-- Creating Table Message
SET TERM ON
PRO Creating table &&oci360_in_target_table.
@@&&fc_set_term_off.

-- Start SPOOL to log file
@@&&fc_spool_start.
SET ECHO OFF FEED ON VER ON HEAD ON SERVEROUT ON
SPO &&oci360_log. APP;

PRO ----------------------------------------------------------------------------

PRO Converting "&&oci360_in_source_file." to "&&oci360_in_target_table.".

PRO ----------------------------------------------------------------------------

SET ECHO ON TIMING ON

-- DBMS_JSON can't run for another user. Go back to Current User:
ALTER SESSION SET CURRENT_SCHEMA=&&oci360_user_session.;

DECLARE 
  FHANDLE  UTL_FILE.FILE_TYPE;
BEGIN
  FHANDLE := UTL_FILE.FOPEN('&&oci360_obj_dir.', '&&oci360_temp_extout.', 'w');
  UTL_FILE.PUT(FHANDLE, '&&oci360_in_source_file.');
  UTL_FILE.FCLOSE(FHANDLE);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('EXCEPTION: SQLCODE=' || SQLCODE || '  SQLERRM=' || SQLERRM);
    RAISE;
END;
/

-- Drop External Table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE &&oci360_user_curschema.."&&oci360_temp_exttab." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create External Table with CLOB contents
CREATE TABLE &&oci360_user_curschema.."&&oci360_temp_exttab."
(
  json_document CLOB
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
          (
            json_filename CHAR(100)
          )
          COLUMN TRANSFORMS (json_document FROM LOBFILE (json_filename) FROM ("&&oci360_obj_dir.") CLOB)
    )
   LOCATION ('&&oci360_temp_extout.')
)
REJECT LIMIT 0
NOPARALLEL
NOMONITORING
;

-- Drop table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_temp_table." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create table
CREATE TABLE "&&oci360_temp_table." (
  "&&oci360_temp_clob." CLOB,
  CONSTRAINT "&&oci360_temp_check." CHECK ("&&oci360_temp_clob." IS JSON)
)
NOCOMPRESS NOPARALLEL NOMONITORING;

INSERT /*+ APPEND */ INTO "&&oci360_temp_table."
SELECT json_document
FROM   &&oci360_user_curschema.."&&oci360_temp_exttab.";
-- WHERE  json_filename = '&&oci360_in_source_file.';

COMMIT;

-- Drop index
BEGIN EXECUTE IMMEDIATE 'DROP INDEX "&&oci360_temp_index."'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create index
CREATE SEARCH INDEX "&&oci360_temp_index."
ON "&&oci360_temp_table." ("&&oci360_temp_clob.") FOR JSON
PARAMETERS ('SEARCH_ON NONE DATAGUIDE ON');

EXEC DBMS_STATS.GATHER_INDEX_STATS(USER, '&&oci360_temp_index.', estimate_percent => 99);

INSERT /*+ APPEND */ INTO &&oci360_user_curschema.."&&oci360_obj_metadata."
  (source, jpath, type, tlength, pref_col_name, frequency, low_value, high_value, num_nulls, last_analyzed)
WITH dg_t AS (
  SELECT DBMS_JSON.get_index_dataguide(
         '&&oci360_temp_table.',
         '&&oci360_temp_clob.',
         DBMS_JSON.format_flat) AS dg_doc
  FROM   dual
)
SELECT '&&oci360_in_source_file.' source, jt.*
FROM   dg_t,
       json_table(dg_doc, '$[*]'
         COLUMNS
           jpath         VARCHAR2(200) PATH '$."o:path"',
           type          VARCHAR2(10)  PATH '$."type"',
           tlength       NUMBER        PATH '$."o:length"',
           pref_col_name VARCHAR2(100) PATH '$."o:preferred_column_name"',
           frequency     NUMBER        PATH '$."o:frequency"',
           low_value     VARCHAR2(25)  PATH '$."o:low_value"',
           high_value    VARCHAR2(25)  PATH '$."o:high_value"',
           num_nulls     NUMBER        PATH '$."o:num_nulls"',
           last_analyzed VARCHAR2(20)  PATH '$."o:last_analyzed"') jt
ORDER BY jt.jpath;

COMMIT;

-- Rename Columns
DECLARE
  V_NEW_COLNAME VARCHAR2(1000);
  V_COL_TYPE NUMBER(2);
BEGIN
  -- Type 'object' and 'array' are renamed after cause they will probably not appear in final view and could be renamed before a important type.
  FOR I IN (select jpath, type, count(*) over (partition by UPPER(jpath),source,type) tot
            from   &&oci360_user_curschema.."&&oci360_obj_metadata."
            where  source = '&&oci360_in_source_file.'
            order by decode(type,'null',4,'object',3,'array',2,1)
            )
  LOOP
    CASE i.type
      WHEN 'array'   THEN V_COL_TYPE := DBMS_JSON.TYPE_ARRAY;
      WHEN 'boolean' THEN V_COL_TYPE := DBMS_JSON.TYPE_BOOLEAN;
      WHEN 'object'  THEN V_COL_TYPE := DBMS_JSON.TYPE_OBJECT;
      WHEN 'null'    THEN V_COL_TYPE := DBMS_JSON.TYPE_NULL;
      WHEN 'number'  THEN V_COL_TYPE := DBMS_JSON.TYPE_NUMBER;
      WHEN 'string'  THEN V_COL_TYPE := DBMS_JSON.TYPE_STRING;
      ELSE V_COL_TYPE:=0;
    END CASE;
    V_NEW_COLNAME := i.jpath;
    V_NEW_COLNAME := REGEXP_REPLACE(V_NEW_COLNAME,'^\$\.data','');
    V_NEW_COLNAME := REGEXP_REPLACE(V_NEW_COLNAME,'^\.','');
    V_NEW_COLNAME := REPLACE(V_NEW_COLNAME,'-','_');
    V_NEW_COLNAME := REPLACE(V_NEW_COLNAME,'.','$');
    V_NEW_COLNAME := REPLACE(V_NEW_COLNAME,'[*]','');
    V_NEW_COLNAME := REPLACE(V_NEW_COLNAME,'"','');
    V_NEW_COLNAME := NVL(V_NEW_COLNAME,'root$data');
    IF i.tot = 1 THEN V_NEW_COLNAME := UPPER(V_NEW_COLNAME); END IF;
    --DBMS_OUTPUT.PUT_LINE('DBMS_JSON.RENAME_COLUMN(''&&oci360_temp_table.'', ''&&oci360_temp_clob.'', ''' || i.jpath || ''', ' || V_COL_TYPE || ', ''' || V_NEW_COLNAME || ''')');
    BEGIN
      -- Json accepts columns with same name and different types. Only first rename will work.
      DBMS_JSON.RENAME_COLUMN('&&oci360_temp_table.', '&&oci360_temp_clob.', i.jpath, V_COL_TYPE, V_NEW_COLNAME);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: DBMS_JSON.RENAME_COLUMN(''&&oci360_temp_table.'', ''&&oci360_temp_clob.'', ''' || i.jpath || ''', ' || V_COL_TYPE || ', ''' || V_NEW_COLNAME || ''')');
    END;
  END LOOP;
END;
/

-- Update Metadata Table
MERGE INTO &&oci360_user_curschema.."&&oci360_obj_metadata." t1
USING (
  WITH dg_t AS (
    SELECT DBMS_JSON.get_index_dataguide(
           '&&oci360_temp_table.',
           '&&oci360_temp_clob.',
           DBMS_JSON.format_flat) AS dg_doc
    FROM   dual
  )
  SELECT jt.jpath, jt.type, jt.pref_col_name
  FROM   dg_t,
         json_table(dg_doc, '$[*]'
           COLUMNS
             jpath         VARCHAR2(200) PATH '$."o:path"',
             type          VARCHAR2(10)  PATH '$."type"',
             pref_col_name VARCHAR2(100) PATH '$."o:preferred_column_name"') jt
) t2
ON (t1.jpath=t2.jpath and t1.type=t2.type and t1.source='&&oci360_in_source_file.')
WHEN MATCHED THEN
UPDATE SET new_col_name = t2.pref_col_name;

COMMIT;

-- Drop view
BEGIN EXECUTE IMMEDIATE 'DROP VIEW "&&oci360_temp_view."'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create view.
DECLARE
   empty_data_guide EXCEPTION;
   PRAGMA EXCEPTION_INIT(empty_data_guide , -40591);
BEGIN
  DBMS_JSON.CREATE_VIEW_ON_PATH(
    viewname  => '&&oci360_temp_view.',
    tablename => '&&oci360_temp_table.',
    jcolname  => '&&oci360_temp_clob.',
    path =>      '$.data',
    frequency =>  0);
EXCEPTION
  WHEN empty_data_guide THEN
    DBMS_OUTPUT.PUT_LINE('Empty JSON.'); -- handle the error
END;
/

-- Just to print the code on log file for troubleshooting.
SET PAGES 0
SET LONG 2000000000
SELECT DBMS_METADATA.GET_DDL('VIEW','&&oci360_temp_view.') VIEW_CODE
FROM DUAL
WHERE EXISTS (SELECT 1
              FROM   USER_VIEWS
              WHERE  VIEW_NAME = '&&oci360_temp_view.');
SET PAGES &&moat369_def_sql_maxrows.

ALTER SESSION SET CURRENT_SCHEMA=&&oci360_user_curschema.;

-- Drop Target Table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_in_target_table." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_in_target_table."
COMPRESS NOPARALLEL NOMONITORING
AS
SELECT *
FROM   &&oci360_user_session.."&&oci360_temp_view.";

-- Add mandatory columns that may not be mapped when resource is not being used.
DECLARE
  V_COL_TYPE VARCHAR2(30);
  V_EXISTS NUMBER := 0;
  V_SQL VARCHAR2(500);
BEGIN
  FOR I IN (SELECT t1.source,
                   t1.jpath,
                   t1.type,
                   t1.new_col_name,
                   (select table_name
                    from   all_tables
                    where  owner = SYS_CONTEXT('userenv','current_schema')
                    and    table_name = '&&oci360_in_target_table.') table_name,
                   rank() over (partition by t1.source order by t1.jpath) ord_cols,
                   count(1) over (partition by t1.source) tot_cols
            FROM   "&&oci360_obj_jsoncols." t1
            WHERE  t1.source = '&&oci360_in_source_file.'
            AND    NOT EXISTS (SELECT 1
                               FROM   "&&oci360_obj_metadata." t2
                               WHERE  t1.source = t2.source
                               AND    t1.jpath = t2.jpath
                               AND    t1.type = t2.type
                               )
            AND    NOT EXISTS (SELECT 1
                               FROM   "&&oci360_obj_metadata." t2
                               WHERE  t1.source = t2.source
                               AND    t1.new_col_name = t2.new_col_name
                               )
            ORDER BY t1.source,t1.jpath
           )
  LOOP
    IF I.TABLE_NAME IS NULL AND I.ord_cols=1 THEN
      BEGIN
        V_SQL := 'CREATE TABLE "&&oci360_in_target_table." AS SELECT 1 "DUMMY" FROM DUAL WHERE 1=2';
        EXECUTE IMMEDIATE V_SQL;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR: ' || V_SQL);
      END;
    END IF;
    BEGIN
      CASE i.type
        WHEN 'number'  THEN V_COL_TYPE := 'NUMBER(1)';
        WHEN 'string'  THEN V_COL_TYPE := 'VARCHAR2(1)';
        WHEN 'boolean' THEN V_COL_TYPE := 'VARCHAR2(1)';
        ELSE V_COL_TYPE:=0;
      END CASE;
      INSERT INTO "&&oci360_obj_metadata." (source,jpath,type,new_col_name) values (i.source,i.jpath,i.type,i.new_col_name);
      V_SQL := 'alter table "&&oci360_in_target_table." add "' || i.new_col_name || '" ' || V_COL_TYPE;
      EXECUTE IMMEDIATE V_SQL;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || V_SQL);
    END;
    IF I.TABLE_NAME IS NULL AND I.ord_cols=I.tot_cols THEN
      BEGIN
        V_SQL := 'ALTER TABLE "&&oci360_in_target_table." DROP COLUMN "DUMMY"';
        EXECUTE IMMEDIATE V_SQL;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR: ' || V_SQL);
      END;
    END IF;
  END LOOP;
END;
/

-- Mark created columns on Metadata
UPDATE &&oci360_user_curschema.."&&oci360_obj_metadata." t1
SET created_on_table = 'Y'
WHERE EXISTS
(SELECT 1
   FROM all_tab_columns t2
  WHERE t1.source = '&&oci360_in_source_file.'
    AND t2.owner = '&&oci360_user_curschema.'
    AND t2.table_name = '&&oci360_in_target_table.'
    AND t1.new_col_name = t2.column_name);

-- Remove null columns that are mapped to another type.
BEGIN
  FOR I IN (SELECT t1.new_col_name
            FROM   "&&oci360_obj_metadata." t1
            WHERE  t1.source='&&oci360_in_source_file.'
            AND    t1.type='null'
            AND    EXISTS (SELECT 1
                           FROM   "&&oci360_obj_metadata." t2
                           WHERE  t2.source = t1.source
                           AND    NOT( t2.jpath = t1.jpath AND t2.type = t1.type )
                           AND    t2.jpath like t1.jpath || '%'
                          )
           )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE 'alter table "&&oci360_in_target_table." set unused ("' || I.NEW_COL_NAME || '")';
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: alter table "&&oci360_in_target_table." set unused ("' || I.NEW_COL_NAME || '")');
    END;
  END LOOP;
END;
/

-- Clean

EXEC UTL_FILE.FREMOVE ('&&oci360_obj_dir.', '&&oci360_temp_extout.');

BEGIN EXECUTE IMMEDIATE 'DROP VIEW &&oci360_user_session.."&&oci360_temp_view."'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
DROP TABLE &&oci360_user_session.."&&oci360_temp_table." PURGE;

DROP TABLE &&oci360_user_curschema.."&&oci360_temp_exttab." PURGE;

-- Close SPOOL to log file
SPO OFF;
@@&&fc_spool_end.

SET TIMING OFF

UNDEF oci360_temp_obj_prefix
UNDEF oci360_temp_table
UNDEF oci360_temp_clob
UNDEF oci360_temp_check
UNDEF oci360_temp_view
UNDEF oci360_temp_index
UNDEF oci360_temp_exttab

UNDEF oci360_in_source_file
UNDEF oci360_in_target_table