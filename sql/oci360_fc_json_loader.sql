-- Required:
DEF oci360_in_loader_p1   = "&&1."
UNDEF 1

COL oci360_pre_loader_filename NEW_V oci360_pre_loader_filename
COL oci360_pre_loader_tab_type NEW_V oci360_pre_loader_tab_type
COL oci360_pre_loader_function NEW_V oci360_pre_loader_function
COL oci360_pre_loader_inzip    NEW_V oci360_pre_loader_inzip

SELECT source                  oci360_pre_loader_filename,
       in_zip                  oci360_pre_loader_inzip,
       trim(lower(table_type)) oci360_pre_loader_tab_type,
       decode(trim(table_type),'JSON','oci360_fc_json_converter.sql','CSV',decode('&&oci360_loc_skip.','','oci360_fc_csv_converter_loc.sql','oci360_fc_csv_converter_adb.sql'),'') oci360_pre_loader_function
FROM   "&&oci360_obj_jsontabs."
WHERE  table_name = '&&oci360_in_loader_p1.';

COL oci360_pre_loader_filename clear
COL oci360_pre_loader_tab_type clear
COL oci360_pre_loader_function clear
COL oci360_pre_loader_inzip    clear

COL oci360_skip_if_loaded NEW_V oci360_skip_if_loaded

-- Don't load if source file not in zip or if is processed.
SELECT DECODE(COUNT(*),0,'','&&fc_skip_script.') oci360_skip_if_loaded -- Skip if find any rows
FROM   "&&oci360_obj_jsontabs."
WHERE  table_name = '&&oci360_in_loader_p1.'
AND    (in_zip + in_csv = 0 or is_processed = 1);

-- Don't load if oci360_pre_loader_filename is null.
SELECT DECODE('&&oci360_pre_loader_filename.',NULL,'&&fc_skip_script.','&&oci360_skip_if_loaded.') oci360_skip_if_loaded FROM DUAL;

-- -- Don't load if table already loaded in this session.
-- SELECT DECODE(COUNT(*),0,'','&&fc_skip_script.') oci360_skip_if_loaded
-- FROM   "&&oci360_obj_metadata."
-- WHERE  source = '&&oci360_pre_loader_filename.';

-- -- Don't load if oci360_load_mode is OFF.
-- SELECT DECODE('&&oci360_load_mode.','OFF','&&fc_skip_script.','') oci360_skip_if_loaded
-- FROM   DUAL
-- WHERE  '&&oci360_skip_if_loaded.' IS NULL;

HOS if [ -z "&&oci360_skip_if_loaded." -a '&&oci360_pre_loader_tab_type.' == 'json' -a '&&oci360_pre_loader_inzip.' -eq 1 -a -z "&&oci360_loc_skip." ]; then unzip -o -d &&moat369_sw_output_fdr. &&oci360_json_zip. &&oci360_pre_loader_filename.; fi

COL oci360_skip_if_loaded clear

UPDATE "&&oci360_obj_jsontabs."
SET    is_processed = 1
WHERE  '&&oci360_skip_if_loaded.' IS NULL
AND    table_name = '&&oci360_in_loader_p1.';

COMMIT;

@@&&oci360_skip_if_loaded.&&moat369_sw_folder./oci360_fc_prevexec_save.sql "&&oci360_in_loader_p1."
@@&&oci360_skip_if_loaded.&&moat369_sw_folder./&&oci360_pre_loader_function. "&&oci360_in_loader_p1." "&&oci360_pre_loader_filename."

UNDEF oci360_skip_if_loaded
UNDEF oci360_in_loader_p1
UNDEF oci360_pre_loader_filename
UNDEF oci360_pre_loader_tab_type
UNDEF oci360_pre_loader_function