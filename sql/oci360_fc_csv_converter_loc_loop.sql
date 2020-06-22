-- Required:
DEF oci360_in_target_table = "&&1."
DEF oci360_in_source_file  = "&&2."

UNDEF 1 2

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

-- File is touched just for EXTERNAL TABLE location checker.
HOS touch &&moat369_sw_output_fdr_fpath./&&oci360_in_source_file.

CREATE OR REPLACE VIEW &&oci360_user_curschema.."&&oci360_temp_view."
AS
SELECT * from "&&oci360_temp_exttab."
EXTERNAL MODIFY ( LOCATION ('&&oci360_in_source_file.') );

DECLARE
   V_CSV_COL VARCHAR2(200);
   V_TAB_COL VARCHAR2(200);
   V_QRY CLOB;
   V_INS_SQL CLOB;
   V_SEL_SQL CLOB;
BEGIN
  for i in (select column_name from all_tab_columns where owner=SYS_CONTEXT('userenv','current_schema') and table_name='&&oci360_temp_exttab.' order by column_id)
  loop
    V_QRY := 'select ' || i.column_name || ' from "&&oci360_temp_view." where rownum=1';
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
  V_QRY := 'insert /*+ append */ into &&oci360_in_target_table. (' || V_INS_SQL || ') select ' || V_SEL_SQL || ' from "&&oci360_temp_view." minus select ' || V_SEL_SQL || ' from "&&oci360_temp_view." where rownum=1';
  DBMS_OUTPUT.PUT_LINE(V_QRY);
  EXECUTE IMMEDIATE V_QRY;
  COMMIT;
END;
/

HOS rm -f &&moat369_sw_output_fdr_fpath./&&oci360_in_source_file.

-- Close SPOOL to log file
SPO OFF;
@@&&fc_spool_end.

SET TIMING OFF

UNDEF oci360_in_target_table
UNDEF oci360_in_source_file