-- Run the following lines from 1 to 9 and from a to j
-- COL moat369_1a NEW_V moat369_1a
-- SELECT CASE WHEN '1a' BETWEEN :moat369_sec_from AND :moat369_sec_to THEN '' ELSE '&&fc_skip_script.' END moat369_1a FROM DUAL;

@@&&fc_def_output_file. step_file 'step_file.sql';
HOS &&cmd_awk. 'BEGIN { for (i=1; i<10; i++) for (j=97; j<108; j++) printf("COL c_section_variables NEW_V &&moat369_sw_name._%d%c nopri\nSELECT CASE WHEN '\''%d%c'\'' BETWEEN :moat369_sec_from AND :moat369_sec_to THEN '\'\'' ELSE '\'\&\&'fc_skip_script.'\'' END c_section_variables FROM DUAL;\nCOL c_section_variables clear\n", i, j, i, j) }' > &&step_file.
@&&step_file.
@@&&fc_zip_driver_files. &&step_file.
UNDEF step_file