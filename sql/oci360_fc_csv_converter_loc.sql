-- Required:
DEF oci360_in_csvconv_p1   = "&&1."
DEF oci360_in_csvconv_p2   = "&&2."
UNDEF 1 2

DEF oci360_csv_tablename   = '&&oci360_in_csvconv_p1.'
DEF oci360_csv_fileprefx   = '&&oci360_in_csvconv_p2.'
DEF oci360_temp_colcontrol = 'OCI360_COL_CONTROL'
DEF oci360_temp_exttab     = 'OCI360_EXTTAB'
DEF oci360_temp_view       = 'OCI360_EXTVIEW'

DEF fc_csv_converter_loop  = '&&moat369_sw_folder./oci360_fc_csv_converter_loc_loop.sql'

@@&&fc_def_output_file. oci360_temp_preproc 'preproc.sh'
@@&&fc_clean_file_name. oci360_temp_preproc oci360_temp_preproc_nopath "PATH"

DECLARE 
  FHANDLE  UTL_FILE.FILE_TYPE;
BEGIN
  FHANDLE := UTL_FILE.FOPEN('&&oci360_obj_dir.', '&&oci360_temp_preproc_nopath.', 'w');
  UTL_FILE.PUT_LINE(FHANDLE, 'v_file=$(/usr/bin/basename "$1")');
  UTL_FILE.PUT_LINE(FHANDLE, '/usr/bin/unzip -p &&oci360_csv_report_zip. "$v_file" | /usr/bin/gunzip');
  UTL_FILE.FCLOSE(FHANDLE);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('EXCEPTION: SQLCODE=' || SQLCODE || '  SQLERRM=' || SQLERRM);
    RAISE;
END;
/

HOS chmod +x &&oci360_temp_preproc.

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_temp_colcontrol." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_temp_colcontrol."
(
    CSV_COL_NAME VARCHAR2(200),
    TAB_COL_NAME VARCHAR2(200),
    CONSTRAINT "&&oci360_temp_colcontrol._PK" PRIMARY KEY (CSV_COL_NAME),
    CONSTRAINT "&&oci360_temp_colcontrol._UK" UNIQUE (TAB_COL_NAME)
) COMPRESS NOPARALLEL NOMONITORING;

INSERT INTO "&&oci360_temp_colcontrol." VALUES ('lineItem/referenceNo','lineItem/referenceNo');
COMMIT;

BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_csv_tablename." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE "&&oci360_csv_tablename."
(
  "lineItem/referenceNo" VARCHAR2(4000)
  -- ,CONSTRAINT "&&oci360_csv_tablename._PK" PRIMARY KEY ("lineItem/referenceNo")
) COMPRESS NOPARALLEL NOMONITORING;

-- Drop External Table
BEGIN EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_temp_exttab." PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- External table must be created with CONNECT account - same as directory owner
CREATE TABLE "&&oci360_temp_exttab."
(
  C1  VARCHAR2(4000), C2  VARCHAR2(4000), C3  VARCHAR2(4000), C4  VARCHAR2(4000), C5  VARCHAR2(4000), C6  VARCHAR2(4000), C7  VARCHAR2(4000), C8  VARCHAR2(4000), C9  VARCHAR2(4000), C10 VARCHAR2(4000),
  C11 VARCHAR2(4000), C12 VARCHAR2(4000), C13 VARCHAR2(4000), C14 VARCHAR2(4000), C15 VARCHAR2(4000), C16 VARCHAR2(4000), C17 VARCHAR2(4000), C18 VARCHAR2(4000), C19 VARCHAR2(4000), C20 VARCHAR2(4000),
  C21 VARCHAR2(4000), C22 VARCHAR2(4000), C23 VARCHAR2(4000), C24 VARCHAR2(4000), C25 VARCHAR2(4000), C26 VARCHAR2(4000), C27 VARCHAR2(4000), C28 VARCHAR2(4000), C29 VARCHAR2(4000), C30 VARCHAR2(4000),
  C31 VARCHAR2(4000), C32 VARCHAR2(4000), C33 VARCHAR2(4000), C34 VARCHAR2(4000), C35 VARCHAR2(4000), C36 VARCHAR2(4000), C37 VARCHAR2(4000), C38 VARCHAR2(4000), C39 VARCHAR2(4000), C40 VARCHAR2(4000),
  C41 VARCHAR2(4000), C42 VARCHAR2(4000), C43 VARCHAR2(4000), C44 VARCHAR2(4000), C45 VARCHAR2(4000), C46 VARCHAR2(4000), C47 VARCHAR2(4000), C48 VARCHAR2(4000), C49 VARCHAR2(4000), C50 VARCHAR2(4000),
  C51 VARCHAR2(4000), C52 VARCHAR2(4000), C53 VARCHAR2(4000), C54 VARCHAR2(4000), C55 VARCHAR2(4000), C56 VARCHAR2(4000), C57 VARCHAR2(4000), C58 VARCHAR2(4000), C59 VARCHAR2(4000), C60 VARCHAR2(4000),
  C61 VARCHAR2(4000), C62 VARCHAR2(4000), C63 VARCHAR2(4000), C64 VARCHAR2(4000), C65 VARCHAR2(4000), C66 VARCHAR2(4000), C67 VARCHAR2(4000), C68 VARCHAR2(4000), C69 VARCHAR2(4000), C70 VARCHAR2(4000)
)
ORGANIZATION EXTERNAL
(  DEFAULT DIRECTORY "&&oci360_obj_dir."
   ACCESS PARAMETERS 
     (records delimited BY newline
      preprocessor "&&oci360_obj_dir.":'&&oci360_temp_preproc_nopath.'
      nologfile nobadfile nodiscardfile
      fields
          terminated BY ','
          optionally enclosed BY '"'
          notrim
          missing field VALUES are NULL
    )
   LOCATION ('xxx') -- Location will be dinamically changed during fc_csv_converter_loop calls.
)
REJECT LIMIT 0
NOPARALLEL
NOMONITORING
;

@@&&fc_def_output_file. step_csv_full_loader 'step_csv_full_loader.sql'
HOS cat "&&oci360_csv_files." | &&cmd_grep. '&&oci360_csv_fileprefx.' | &&cmd_awk. '{print("@@&&fc_csv_converter_loop. &&oci360_csv_tablename. "$1)}' > &&step_csv_full_loader.
@@&&step_csv_full_loader.

@@&&fc_zip_driver_files. &&step_csv_full_loader.
UNDEF step_csv_full_loader

DROP TABLE "&&oci360_temp_exttab." PURGE;
DROP TABLE "&&oci360_temp_colcontrol." PURGE;
DROP VIEW "&&oci360_temp_view.";

@@&&fc_zip_driver_files. &&oci360_temp_preproc.

UNDEF oci360_in_csvconv_p1
UNDEF oci360_in_csvconv_p2

UNDEF oci360_csv_tablename
UNDEF oci360_csv_fileprefx
UNDEF oci360_temp_colcontrol
UNDEF oci360_temp_exttab
UNDEF oci360_temp_view

UNDEF oci360_temp_preproc
UNDEF oci360_temp_preproc_nopath
UNDEF fc_csv_converter_loop