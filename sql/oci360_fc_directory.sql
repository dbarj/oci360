SET TERM ON SERVEROUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

DEF oci360_obj_dir_path = '&&moat369_sw_output_fdr_fpath.'
-- @@&&fc_set_value_var_decode. 'oci360_obj_dir_path' '&&oci360_adb_skip.' '' 'oci360'            '&&moat369_sw_output_fdr_fpath.'
-- @@&&fc_set_value_var_decode. 'oci360_obj_dir'      '&&oci360_adb_skip.' '' '&&oci360_adb_flr.' '&&oci360_obj_dir.'

-- Create file where the next block will write into.
-- This was done because oracle can be running with umask that will not allow this program to read it later.
@@&&fc_def_output_file. oci360_change_obj_dir 'directory.sql'
HOS touch &&oci360_change_obj_dir.
HOS chgrp dba &&oci360_change_obj_dir.
HOS chmod g+w &&oci360_change_obj_dir.

-- TODO: When running as SYS for another user, must give READ/WRITE/EXECUTE permissions on the folder.
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
  DBMS_OUTPUT.PUT_LINE('Trying to create directory  "&&oci360_obj_dir." on ''&&oci360_obj_dir_path.''.');
  BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY "&&oci360_obj_dir." AS ''&&oci360_obj_dir_path.''';
    DBMS_OUTPUT.PUT_LINE('Directory created and will be dropped on the end of OCI360 execution.');
    IF '&&oci360_user_curschema.' != '&&oci360_user_session.' THEN
      EXECUTE IMMEDIATE 'GRANT READ,WRITE,EXECUTE on DIRECTORY "&&oci360_obj_dir." TO &&oci360_user_curschema.';
      DBMS_OUTPUT.PUT_LINE('Directory granted to &&oci360_user_curschema..');
    END IF;
    RETURN;
  EXCEPTION
    WHEN INSUFFICIENT_PRIVS THEN
      DBMS_OUTPUT.PUT_LINE('User has no privilege to create directory. Checking existing directories on output path..');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXCEPTION: SQLCODE=' || SQLCODE || '  SQLERRM=' || SQLERRM);
  END;
  FOR DIR IN (select directory_name
              from   all_directories
              where  regexp_replace(directory_path || '/','[/]+','/') = regexp_replace('&&oci360_obj_dir_path.' || '/','[/]+','/')
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
   RAISE_APPLICATION_ERROR(-20000, 'You have no permissions to create directory or use any on "&&oci360_obj_dir_path." path.' || CHR(10) ||
   'Please either grant CREATE ANY DIRECTORY to "&&oci360_user_session." or create the directory as DBA and give READ/WRITE/EXECUTE permissions to "&&oci360_user_session.".');
  END IF;
  FHANDLE := SYS.UTL_FILE.FOPEN(V_DIRECTORY, 'directory.sql', 'w');
  SYS.UTL_FILE.PUT_LINE(FHANDLE, 'DEF oci360_obj_dir = '''|| V_DIRECTORY ||'''');
  SYS.UTL_FILE.PUT_LINE(FHANDLE, 'DEF oci360_obj_dir_del = ''N''');
  SYS.UTL_FILE.FCLOSE(FHANDLE);
END;
/

WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

-- Define directory
@&&oci360_change_obj_dir.
HOS rm -f &&oci360_change_obj_dir.

UNDEF oci360_change_obj_dir oci360_obj_dir_path