-- Required:
DEF oci360_in_target_table = "&&1."
DEF oci360_in_source_file  = "&&2."

UNDEF 1 2

DEF oci360_temp_exttab     = 'OCI360_EXTTAB'

-- Creating Table Message
SET TERM ON
PRO Loading "&&oci360_in_source_file." in "&&oci360_in_target_table.".
@@&&fc_set_term_off.

-- Start SPOOL to log file
@@&&fc_spool_start.
SET ECHO OFF FEED ON VER ON HEAD ON SERVEROUT ON
SPO &&oci360_log_csv. APP;

PRO ----------------------------------------------------------------------------

PRO Loading "&&oci360_in_source_file." in "&&oci360_in_target_table.".

PRO ----------------------------------------------------------------------------

SET ECHO ON TIMING ON

-- Drop External Table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_temp_exttab." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN  
   DBMS_CLOUD.CREATE_EXTERNAL_TABLE(   
      table_name =>'&&oci360_temp_exttab.',   
      credential_name =>'&&oci360_adb_cred.',   
      file_uri_list =>'&&oci360_adb_uri.&&oci360_in_source_file.',
      format => json_object('type' value 'csv', 'delimiter' value ',', 'blankasnull' value 'true', 'compression' value 'gzip', 'ignoremissingcolumns' value 'true'),
      column_list => 'C1  VARCHAR2(4000), C2  VARCHAR2(4000), C3  VARCHAR2(4000), C4  VARCHAR2(4000), C5  VARCHAR2(4000), C6  VARCHAR2(4000), C7  VARCHAR2(4000), C8  VARCHAR2(4000), C9  VARCHAR2(4000), C10 VARCHAR2(4000),
                      C11 VARCHAR2(4000), C12 VARCHAR2(4000), C13 VARCHAR2(4000), C14 VARCHAR2(4000), C15 VARCHAR2(4000), C16 VARCHAR2(4000), C17 VARCHAR2(4000), C18 VARCHAR2(4000), C19 VARCHAR2(4000), C20 VARCHAR2(4000),
                      C21 VARCHAR2(4000), C22 VARCHAR2(4000), C23 VARCHAR2(4000), C24 VARCHAR2(4000), C25 VARCHAR2(4000), C26 VARCHAR2(4000), C27 VARCHAR2(4000), C28 VARCHAR2(4000), C29 VARCHAR2(4000), C30 VARCHAR2(4000),
                      C31 VARCHAR2(4000), C32 VARCHAR2(4000), C33 VARCHAR2(4000), C34 VARCHAR2(4000), C35 VARCHAR2(4000), C36 VARCHAR2(4000), C37 VARCHAR2(4000), C38 VARCHAR2(4000), C39 VARCHAR2(4000), C40 VARCHAR2(4000),
                      C41 VARCHAR2(4000), C42 VARCHAR2(4000), C43 VARCHAR2(4000), C44 VARCHAR2(4000), C45 VARCHAR2(4000), C46 VARCHAR2(4000), C47 VARCHAR2(4000), C48 VARCHAR2(4000), C49 VARCHAR2(4000), C50 VARCHAR2(4000),
                      C51 VARCHAR2(4000), C52 VARCHAR2(4000), C53 VARCHAR2(4000), C54 VARCHAR2(4000), C55 VARCHAR2(4000), C56 VARCHAR2(4000), C57 VARCHAR2(4000), C58 VARCHAR2(4000), C59 VARCHAR2(4000), C60 VARCHAR2(4000),
                      C61 VARCHAR2(4000), C62 VARCHAR2(4000), C63 VARCHAR2(4000), C64 VARCHAR2(4000), C65 VARCHAR2(4000), C66 VARCHAR2(4000), C67 VARCHAR2(4000), C68 VARCHAR2(4000), C69 VARCHAR2(4000), C70 VARCHAR2(4000)'
   );
   END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_temp_exttab._NO_HEADER" PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN  
   DBMS_CLOUD.CREATE_EXTERNAL_TABLE(   
      table_name =>'&&oci360_temp_exttab._NO_HEADER',   
      credential_name =>'&&oci360_adb_cred.',   
      file_uri_list =>'&&oci360_adb_uri.&&oci360_in_source_file.',
      format => json_object('type' value 'csv', 'delimiter' value ',', 'blankasnull' value 'true', 'compression' value 'gzip', 'ignoremissingcolumns' value 'true', 'skipheaders' value '1'),
      column_list => 'C1  VARCHAR2(4000), C2  VARCHAR2(4000), C3  VARCHAR2(4000), C4  VARCHAR2(4000), C5  VARCHAR2(4000), C6  VARCHAR2(4000), C7  VARCHAR2(4000), C8  VARCHAR2(4000), C9  VARCHAR2(4000), C10 VARCHAR2(4000),
                      C11 VARCHAR2(4000), C12 VARCHAR2(4000), C13 VARCHAR2(4000), C14 VARCHAR2(4000), C15 VARCHAR2(4000), C16 VARCHAR2(4000), C17 VARCHAR2(4000), C18 VARCHAR2(4000), C19 VARCHAR2(4000), C20 VARCHAR2(4000),
                      C21 VARCHAR2(4000), C22 VARCHAR2(4000), C23 VARCHAR2(4000), C24 VARCHAR2(4000), C25 VARCHAR2(4000), C26 VARCHAR2(4000), C27 VARCHAR2(4000), C28 VARCHAR2(4000), C29 VARCHAR2(4000), C30 VARCHAR2(4000),
                      C31 VARCHAR2(4000), C32 VARCHAR2(4000), C33 VARCHAR2(4000), C34 VARCHAR2(4000), C35 VARCHAR2(4000), C36 VARCHAR2(4000), C37 VARCHAR2(4000), C38 VARCHAR2(4000), C39 VARCHAR2(4000), C40 VARCHAR2(4000),
                      C41 VARCHAR2(4000), C42 VARCHAR2(4000), C43 VARCHAR2(4000), C44 VARCHAR2(4000), C45 VARCHAR2(4000), C46 VARCHAR2(4000), C47 VARCHAR2(4000), C48 VARCHAR2(4000), C49 VARCHAR2(4000), C50 VARCHAR2(4000),
                      C51 VARCHAR2(4000), C52 VARCHAR2(4000), C53 VARCHAR2(4000), C54 VARCHAR2(4000), C55 VARCHAR2(4000), C56 VARCHAR2(4000), C57 VARCHAR2(4000), C58 VARCHAR2(4000), C59 VARCHAR2(4000), C60 VARCHAR2(4000),
                      C61 VARCHAR2(4000), C62 VARCHAR2(4000), C63 VARCHAR2(4000), C64 VARCHAR2(4000), C65 VARCHAR2(4000), C66 VARCHAR2(4000), C67 VARCHAR2(4000), C68 VARCHAR2(4000), C69 VARCHAR2(4000), C70 VARCHAR2(4000)'
   );
   END;
/

DECLARE
   V_CSV_COL VARCHAR2(200);
   V_TAB_COL VARCHAR2(200);
   V_QRY CLOB;
   V_INS_SQL CLOB;
   V_SEL_SQL CLOB;
BEGIN
  for i in (select column_name from all_tab_columns where owner=SYS_CONTEXT('userenv','current_schema') and table_name='&&oci360_temp_exttab.' order by column_id)
  loop
    V_QRY := 'select ' || i.column_name || ' from "&&oci360_temp_exttab." where rownum=1';
    execute immediate V_QRY into V_CSV_COL;
    BEGIN
      select TAB_COL_NAME into V_TAB_COL from "&&oci360_temp_colcontrol." where CSV_COL_NAME=V_CSV_COL;
    EXCEPTION WHEN NO_DATA_FOUND then V_TAB_COL := null;
    end;
    if V_CSV_COL is not null then
      if V_TAB_COL is null then
        -- V_COL_NAME := REPLACE(V_CSV_COL,'/','_');
        V_TAB_COL := V_CSV_COL;
        INSERT INTO "&&oci360_temp_colcontrol." (CSV_COL_NAME,TAB_COL_NAME) values (V_CSV_COL,V_TAB_COL);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Adding column ' || dbms_assert.enquote_name(V_CSV_COL,FALSE) || ' on &&oci360_in_target_table..');
        EXECUTE IMMEDIATE 'alter table &&oci360_in_target_table. add ' || dbms_assert.enquote_name(V_CSV_COL,FALSE) || ' varchar2(4000)';
      end if;
      V_INS_SQL := V_INS_SQL || ',' || dbms_assert.enquote_name(V_TAB_COL,FALSE);
      V_SEL_SQL := V_SEL_SQL || ',' || dbms_assert.enquote_name(i.column_name,FALSE);
    end if;
  end loop;
  V_INS_SQL := substr(V_INS_SQL,2);
  V_SEL_SQL := substr(V_SEL_SQL,2);
  V_QRY := 'insert /*+ append */ into &&oci360_in_target_table. (' || V_INS_SQL || ') select ' || V_SEL_SQL || ' from "&&oci360_temp_exttab._NO_HEADER"';
  DBMS_OUTPUT.PUT_LINE(V_QRY);
  EXECUTE IMMEDIATE V_QRY;
  COMMIT;
END;
/

DROP TABLE "&&oci360_temp_exttab." PURGE;
DROP TABLE "&&oci360_temp_exttab._NO_HEADER" PURGE;

-- Close SPOOL to log file
SPO OFF;
@@&&fc_spool_end.

SET TIMING OFF

UNDEF oci360_temp_exttab
UNDEF oci360_in_target_table
UNDEF oci360_in_source_file