-- moat369 configuration file. for those cases where you must change moat369 functionality

/*********************** software configuration (do not remove ) ************************/
@@00_software

/*************************** ok to modify (if really needed) ****************************/

-- report column, or section, or range of columns or range of sections i.e. 3, 3-4, 3a, 3a-4c, 3-4c, 3c-4 / null means all (default)
DEF moat369_sections = '';

-- history days (default 31)
DEF moat369_conf_days = '2';

-- range of dates below superceed history days when values are other than YYYY-MM-DD
DEF moat369_conf_date_from = 'YYYY-MM-DD';
DEF moat369_conf_date_to   = 'YYYY-MM-DD';

-- working hours are defined between these two HH24MM values (i.e. 7:30AM and 7:30PM)
DEF moat369_conf_work_time_from = '0730';
DEF moat369_conf_work_time_to   = '1930';

-- working days are defined between 1 (Sunday) and 7 (Saturday)
DEF moat369_conf_work_day_from = '2';
DEF moat369_conf_work_day_to   = '6';

-- defines if the output will be encrypted using provided AEG certificate
DEF moat369_conf_encrypt_output = 'OFF';
DEF moat369_conf_encrypt_html   = 'OFF';
DEF moat369_conf_compress_html  = 'OFF';

-- Defines OCI360 execution mode. Options are (FULL or REPORT_ONLY)
-- FULL        = Call OCI-CLI exporter (generates json) and generate oci360 report. -> NOT IMPLEMENTED YET
-- REPORT_ONLY = Generate oci360 report only. Must have ZIP file with all jsons inside execution folder.
DEF oci360_exec_mode = 'REPORT_ONLY';

-- Defines OCI360 converter mode. Options are (ON_DEMAND, PRE_LOAD or OFF)
-- PRE_LOAD  = Convert all jsons inside tables in the beggining. (Recommended and default if omitted)
-- ON_DEMAND = Convert tables from jsons on-demand, as they are used in each section. Good for running specific sections only. eg: @oci360 1a
-- OFF       = Don't convert json into tables. Tables must exist from a prior execution (combine this with oci360_clean_on_exit = OFF).
-- DEF oci360_load_mode = 'PRE_LOAD';

-- Defines OCI360 clean mode. Options are (ON or OFF)
-- ON  = Remove all loaded tables in the end. (Recommended and default if omitted)
-- OFF = Keep all loaded tables in the end. Good if you plan to run the oci360 again later or check contents. In next execution, run with oci360_load_mode = OFF.
-- DEF oci360_clean_on_exit = 'OFF';

/**************************** not recommended to modify *********************************/

-- excluding report types reduce usability while providing marginal performance gain
DEF moat369_conf_incl_html  = 'Y';
DEF moat369_conf_incl_text  = 'N';
DEF moat369_conf_incl_csv   = 'Y';
DEF moat369_conf_incl_line  = 'Y';
DEF moat369_conf_incl_pie   = 'Y';
DEF moat369_conf_incl_bar   = 'Y';
DEF moat369_conf_incl_graph = 'Y';
DEF moat369_conf_incl_file  = 'Y';

-- Default values skip_xxx for each type. Usually you enable HTML and control the others inside sections with "skip_" variables.
DEF moat369_conf_def_html  = 'Y';
DEF moat369_conf_def_text  = 'N';
DEF moat369_conf_def_csv   = 'N';
DEF moat369_conf_def_line  = 'N';
DEF moat369_conf_def_pie   = 'N';
DEF moat369_conf_def_bar   = 'N';
DEF moat369_conf_def_graph = 'N';
DEF moat369_conf_def_file  = 'N';

-- excluding some features from the reports substantially reduces usability with minimal performance gain
DEF moat369_conf_incl_tkprof   = 'N';
DEF moat369_conf_incl_wr_data  = 'N';
DEF moat369_conf_incl_res      = 'N';
DEF moat369_conf_incl_esp      = 'N';
DEF moat369_conf_incl_opatch   = 'N';
DEF moat369_conf_incl_driver   = 'Y';
DEF moat369_conf_ask_license   = 'N';
DEF moat369_conf_sql_format    = 'Y';
DEF moat369_conf_sql_highlight = 'Y';

DEF moat369_def_sql_format     = 'N';
DEF moat369_def_sql_highlight  = 'Y';

/**************************** enter your modifications here *****************************/

--DEF moat369_conf_date_from = '2015-03-01';
--DEF moat369_conf_date_to   = '2015-03-10';

--DEF moat369_conf_incl_text = 'N';
--DEF moat369_conf_incl_csv = 'N';

--DEF moat369_sections = '6d-6e'
--DEF moat369_conf_encrypt_html   = 'OFF';

--DEF DEBUG      = 'ON'
--DEF moat369_pre_sw_output_fdr = 'temp'