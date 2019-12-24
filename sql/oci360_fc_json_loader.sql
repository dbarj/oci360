-- Required:
DEF oci360_in_loader_p1   = "&&1."
UNDEF 1

-- @@&&fc_def_output_file. step_pre_loader 'step_pre_loader.sql'
-- HOS &&cmd_awk. -F',' '$2 == "&&oci360_in_loader_p1." { print "DEF oci360_pre_loader_filename = \""$1"\""; }' &&oci360_tables. > &&step_pre_loader.
-- @@&&step_pre_loader.
-- @@&&fc_zip_driver_files. &&step_pre_loader.
-- UNDEF step_pre_loader

COL oci360_pre_loader_filename NEW_V oci360_pre_loader_filename
SELECT source oci360_pre_loader_filename
FROM   "&&oci360_obj_jsontabs."
WHERE  table_name = '&&oci360_in_loader_p1.';
COL oci360_pre_loader_filename clear

COL oci360_skip_if_loaded NEW_V oci360_skip_if_loaded

-- Don't load if source file not in zip or if is processed.
SELECT DECODE(COUNT(*),0,'','&&fc_skip_script.') oci360_skip_if_loaded -- Skip if find any rows
FROM   "&&oci360_obj_jsontabs."
WHERE  table_name = '&&oci360_in_loader_p1.'
AND    (in_zip = 0 or is_processed = 1);

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

HOS if [ -z "&&oci360_skip_if_loaded." ]; then unzip -o -d &&moat369_sw_output_fdr. &&oci360_json_zip. &&oci360_pre_loader_filename.; fi

COL oci360_skip_if_loaded clear

UPDATE "&&oci360_obj_jsontabs."
SET    is_processed = 1
WHERE  '&&oci360_skip_if_loaded.' IS NULL
AND    table_name = '&&oci360_in_loader_p1.';

COMMIT;

@@&&oci360_skip_if_loaded.&&moat369_sw_folder./oci360_fc_prevexec_save.sql "&&oci360_in_loader_p1."
@@&&oci360_skip_if_loaded.&&moat369_sw_folder./oci360_fc_json_converter.sql "&&oci360_in_loader_p1." "&&oci360_pre_loader_filename."

UNDEF oci360_skip_if_loaded
UNDEF oci360_in_loader_p1
UNDEF oci360_pre_loader_filename