-- Check for mandatory variables and put their default values if unset or stop the code.

-- moat369_sw_output_fdr must be the first as it is used in fc_validate_variable -> step_file
@@&&fc_def_empty_var. moat369_pre_sw_output_fdr
@@&&fc_def_empty_var. moat369_sw_output_fdr
@@&&fc_set_value_var_nvl. 'moat369_sw_output_fdr' '&&moat369_pre_sw_output_fdr.' '.'
@@&&fc_exit_no_folder_perms.

-- DEBUG must be the second as it is used in fc_validate_variable -> fc_set_term_off
@@&&fc_def_empty_var. DEBUG
@@&&fc_set_value_var_nvl. 'DEBUG'  '&&DEBUG.'  'OFF'

@@&&fc_validate_variable. DEBUG ON_OFF

-- Some software parameters are mandatory:

@@&&fc_def_empty_var. moat369_sw_name
@@&&fc_def_empty_var. moat369_sw_logo_file
@@&&fc_def_empty_var. moat369_sw_icon_file
@@&&fc_def_empty_var. moat369_sw_cert_file
@@&&fc_def_empty_var. moat369_sw_title_desc
@@&&fc_def_empty_var. moat369_sw_url
@@&&fc_def_empty_var. moat369_sw_rpt_cols
@@&&fc_def_empty_var. moat369_sw_misc_fdr
@@&&fc_def_empty_var. moat369_sw_logo_title_1
@@&&fc_def_empty_var. moat369_sw_logo_title_2
@@&&fc_def_empty_var. moat369_sw_logo_title_3
@@&&fc_def_empty_var. moat369_sw_logo_title_4
@@&&fc_def_empty_var. moat369_sw_logo_title_5
@@&&fc_def_empty_var. moat369_sw_logo_title_6
@@&&fc_def_empty_var. moat369_sw_logo_title_7
@@&&fc_def_empty_var. moat369_sw_logo_title_8
@@&&fc_def_empty_var. moat369_sw_vYYNN
@@&&fc_def_empty_var. moat369_sw_vrsn
@@&&fc_def_empty_var. moat369_sw_copyright
@@&&fc_def_empty_var. moat369_sw_author
@@&&fc_def_empty_var. moat369_sw_email
@@&&fc_def_empty_var. moat369_sw_dbtool
@@&&fc_def_empty_var. moat369_sw_enc_sql
@@&&fc_def_empty_var. moat369_sw_gchart_path

@@&&fc_set_value_var_nvl. 'moat369_sw_misc_fdr'   '&&moat369_sw_misc_fdr.' 'js'
@@&&fc_set_value_var_nvl. 'moat369_sw_rpt_cols'   '&&moat369_sw_rpt_cols.' '7'

@@&&fc_validate_variable. moat369_sw_name       NOT_NULL
@@&&fc_validate_variable. moat369_sw_name       LOWER_CASE
@@&&fc_validate_variable. moat369_sw_title_desc NOT_NULL
@@&&fc_validate_variable. moat369_sw_vYYNN      NOT_NULL
@@&&fc_validate_variable. moat369_sw_vrsn       NOT_NULL
@@&&fc_validate_variable. moat369_sw_rpt_cols   IS_NUMBER

@@&&fc_set_value_var_nvl. 'moat369_sw_copyright' '&&moat369_sw_copyright.' '&&moat369_sw_name. (c) &&moat369_fw_vYYYY., All rights reserved.'
@@&&fc_set_value_var_nvl. 'moat369_sw_email'     '&&moat369_sw_email.'     'unknown@example.com'

@@&&fc_validate_variable. moat369_sw_email      LOWER_CASE
@@&&fc_validate_variable. moat369_sw_author     NOT_NULL

-- moat369_sw_dbtool defines if the API is being used primarily for a database or is just a interface to other calls.
@@&&fc_set_value_var_nvl. 'moat369_sw_dbtool'  '&&moat369_sw_dbtool.'    'Y'
@@&&fc_validate_variable. moat369_sw_dbtool    Y_N

@@&&fc_set_value_var_nvl. 'moat369_sw_enc_sql'  '&&moat369_sw_enc_sql.'  'N'
@@&&fc_validate_variable. moat369_sw_enc_sql    Y_N

@@&&fc_set_value_var_nvl. 'moat369_sw_gchart_path'  '&&moat369_sw_gchart_path.'  'https://www.gstatic.com/charts/loader.js'

---------------------------

@@&&fc_def_empty_var. moat369_sw_param1
@@&&fc_def_empty_var. moat369_sw_param2
@@&&fc_def_empty_var. moat369_sw_param3
@@&&fc_def_empty_var. moat369_sw_param4
@@&&fc_def_empty_var. moat369_sw_param5

@@&&fc_def_empty_var. moat369_sw_param1_var
@@&&fc_def_empty_var. moat369_sw_param2_var
@@&&fc_def_empty_var. moat369_sw_param3_var
@@&&fc_def_empty_var. moat369_sw_param4_var
@@&&fc_def_empty_var. moat369_sw_param5_var

@@&&fc_set_value_var_nvl. 'moat369_sw_param1' '&&moat369_sw_param1.' 'section'
@@&&fc_set_value_var_nvl. 'moat369_sw_param2' '&&moat369_sw_param2.' 'null'
@@&&fc_set_value_var_nvl. 'moat369_sw_param3' '&&moat369_sw_param3.' 'null'
@@&&fc_set_value_var_nvl. 'moat369_sw_param4' '&&moat369_sw_param4.' 'null'
@@&&fc_set_value_var_nvl. 'moat369_sw_param5' '&&moat369_sw_param5.' 'null'

@@&&fc_validate_variable. moat369_sw_param1 RANGE 'license,section,custom,null'
@@&&fc_validate_variable. moat369_sw_param2 RANGE 'license,section,custom,null'
@@&&fc_validate_variable. moat369_sw_param3 RANGE 'license,section,custom,null'
@@&&fc_validate_variable. moat369_sw_param4 RANGE 'license,section,custom,null'
@@&&fc_validate_variable. moat369_sw_param5 RANGE 'license,section,custom,null'

---------------------------

@@&&fc_def_empty_var. moat369_pre_encrypt_output
@@&&fc_def_empty_var. moat369_pre_encrypt_html
@@&&fc_def_empty_var. moat369_pre_compress_html

@@&&fc_def_empty_var. moat369_conf_encrypt_output
@@&&fc_def_empty_var. moat369_conf_encrypt_html
@@&&fc_def_empty_var. moat369_conf_compress_html

@@&&fc_set_value_var_nvl. 'moat369_conf_encrypt_output' '&&moat369_pre_encrypt_output.' '&&moat369_conf_encrypt_output.'
@@&&fc_set_value_var_nvl. 'moat369_conf_encrypt_html'   '&&moat369_pre_encrypt_html.'   '&&moat369_conf_encrypt_html.'  
@@&&fc_set_value_var_nvl. 'moat369_conf_compress_html'  '&&moat369_pre_compress_html.'  '&&moat369_conf_compress_html.'  

@@&&fc_set_value_var_nvl. 'moat369_conf_encrypt_output' '&&moat369_conf_encrypt_output.' 'OFF'
@@&&fc_set_value_var_nvl. 'moat369_conf_encrypt_html'   '&&moat369_conf_encrypt_html.'   'OFF'
@@&&fc_set_value_var_nvl. 'moat369_conf_compress_html'  '&&moat369_conf_compress_html.'  'OFF'

@@&&fc_validate_variable. moat369_conf_encrypt_output ON_OFF
@@&&fc_validate_variable. moat369_conf_encrypt_html   ON_OFF
@@&&fc_validate_variable. moat369_conf_compress_html  ON_OFF

---------------------------

@@&&fc_def_empty_var. moat369_conf_incl_html
@@&&fc_def_empty_var. moat369_conf_incl_text
@@&&fc_def_empty_var. moat369_conf_incl_csv
@@&&fc_def_empty_var. moat369_conf_incl_line
@@&&fc_def_empty_var. moat369_conf_incl_pie
@@&&fc_def_empty_var. moat369_conf_incl_bar
@@&&fc_def_empty_var. moat369_conf_incl_graph
@@&&fc_def_empty_var. moat369_conf_incl_map
@@&&fc_def_empty_var. moat369_conf_incl_treemap
@@&&fc_def_empty_var. moat369_conf_incl_file

@@&&fc_set_value_var_nvl. 'moat369_conf_incl_html'    '&&moat369_conf_incl_html.'    'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_text'    '&&moat369_conf_incl_text.'    'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_csv'     '&&moat369_conf_incl_csv.'     'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_line'    '&&moat369_conf_incl_line.'    'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_pie'     '&&moat369_conf_incl_pie.'     'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_bar'     '&&moat369_conf_incl_bar.'     'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_graph'   '&&moat369_conf_incl_graph.'   'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_map'     '&&moat369_conf_incl_map.'     'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_treemap' '&&moat369_conf_incl_treemap.' 'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_file'    '&&moat369_conf_incl_file.'    'Y'

@@&&fc_validate_variable. moat369_conf_incl_html    Y_N
@@&&fc_validate_variable. moat369_conf_incl_text    Y_N
@@&&fc_validate_variable. moat369_conf_incl_csv     Y_N
@@&&fc_validate_variable. moat369_conf_incl_line    Y_N
@@&&fc_validate_variable. moat369_conf_incl_pie     Y_N
@@&&fc_validate_variable. moat369_conf_incl_bar     Y_N
@@&&fc_validate_variable. moat369_conf_incl_graph   Y_N
@@&&fc_validate_variable. moat369_conf_incl_map     Y_N
@@&&fc_validate_variable. moat369_conf_incl_treemap Y_N
@@&&fc_validate_variable. moat369_conf_incl_file    Y_N

---------------------------

@@&&fc_def_empty_var. moat369_conf_def_html
@@&&fc_def_empty_var. moat369_conf_def_text
@@&&fc_def_empty_var. moat369_conf_def_csv
@@&&fc_def_empty_var. moat369_conf_def_line
@@&&fc_def_empty_var. moat369_conf_def_pie
@@&&fc_def_empty_var. moat369_conf_def_bar
@@&&fc_def_empty_var. moat369_conf_def_graph
@@&&fc_def_empty_var. moat369_conf_def_map
@@&&fc_def_empty_var. moat369_conf_def_treemap
@@&&fc_def_empty_var. moat369_conf_def_file

@@&&fc_set_value_var_nvl. 'moat369_conf_def_html'    '&&moat369_conf_def_html.'    'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_text'    '&&moat369_conf_def_text.'    'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_csv'     '&&moat369_conf_def_csv.'     'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_line'    '&&moat369_conf_def_line.'    'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_pie'     '&&moat369_conf_def_pie.'     'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_bar'     '&&moat369_conf_def_bar.'     'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_graph'   '&&moat369_conf_def_graph.'   'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_map'     '&&moat369_conf_def_map.'     'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_treemap' '&&moat369_conf_def_treemap.' 'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_def_file'    '&&moat369_conf_def_file.'    'N'

@@&&fc_validate_variable. moat369_conf_def_html    Y_N
@@&&fc_validate_variable. moat369_conf_def_text    Y_N
@@&&fc_validate_variable. moat369_conf_def_csv     Y_N
@@&&fc_validate_variable. moat369_conf_def_line    Y_N
@@&&fc_validate_variable. moat369_conf_def_pie     Y_N
@@&&fc_validate_variable. moat369_conf_def_bar     Y_N
@@&&fc_validate_variable. moat369_conf_def_graph   Y_N
@@&&fc_validate_variable. moat369_conf_def_map     Y_N
@@&&fc_validate_variable. moat369_conf_def_treemap Y_N
@@&&fc_validate_variable. moat369_conf_def_file    Y_N

---------------------------

@@&&fc_def_empty_var. moat369_conf_incl_tkprof
@@&&fc_def_empty_var. moat369_conf_incl_opatch
@@&&fc_def_empty_var. moat369_conf_ask_license
@@&&fc_def_empty_var. moat369_conf_sql_format
@@&&fc_def_empty_var. moat369_conf_sql_highlight
@@&&fc_def_empty_var. moat369_conf_tablefilter

@@&&fc_set_value_var_nvl. 'moat369_conf_incl_tkprof'   '&&moat369_conf_incl_tkprof.'   'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_incl_opatch'   '&&moat369_conf_incl_opatch.'   'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_ask_license'   '&&moat369_conf_ask_license.'   'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_sql_format'    '&&moat369_conf_sql_format.'    'N'
@@&&fc_set_value_var_nvl. 'moat369_conf_sql_highlight' '&&moat369_conf_sql_highlight.' 'Y'
@@&&fc_set_value_var_nvl. 'moat369_conf_tablefilter'   '&&moat369_conf_tablefilter.'   'Y'

@@&&fc_validate_variable. moat369_conf_incl_tkprof   Y_N
@@&&fc_validate_variable. moat369_conf_incl_opatch   Y_N
@@&&fc_validate_variable. moat369_conf_ask_license   Y_N
@@&&fc_validate_variable. moat369_conf_sql_format    Y_N
@@&&fc_validate_variable. moat369_conf_sql_highlight Y_N
@@&&fc_validate_variable. moat369_conf_tablefilter   Y_N

---------------------------

@@&&fc_def_empty_var. moat369_def_sql_format
@@&&fc_def_empty_var. moat369_def_sql_highlight
@@&&fc_def_empty_var. moat369_def_sql_maxrows
@@&&fc_def_empty_var. moat369_def_sql_show

@@&&fc_set_value_var_nvl. 'moat369_def_sql_format'    '&&moat369_def_sql_format.'    'Y'
@@&&fc_set_value_var_nvl. 'moat369_def_sql_highlight' '&&moat369_def_sql_highlight.' 'Y'
@@&&fc_set_value_var_nvl. 'moat369_def_sql_maxrows'   '&&moat369_def_sql_maxrows.'   '10000'
@@&&fc_set_value_var_nvl. 'moat369_def_sql_show'      '&&moat369_def_sql_show.'      'Y'

@@&&fc_validate_variable. moat369_def_sql_format    Y_N
@@&&fc_validate_variable. moat369_def_sql_highlight Y_N
@@&&fc_validate_variable. moat369_def_sql_maxrows   IS_NUMBER
@@&&fc_validate_variable. moat369_def_sql_show      Y_N

---------------------------

@@&&fc_def_empty_var. moat369_sections

---------------------------

@@&&fc_def_empty_var. moat369_conf_days
@@&&fc_def_empty_var. moat369_conf_date_from
@@&&fc_def_empty_var. moat369_conf_date_to
@@&&fc_def_empty_var. moat369_conf_work_time_from
@@&&fc_def_empty_var. moat369_conf_work_time_to
@@&&fc_def_empty_var. moat369_conf_work_day_from
@@&&fc_def_empty_var. moat369_conf_work_day_to

@@&&fc_set_value_var_nvl. 'moat369_conf_days'           '&&moat369_conf_days.'           '31'
@@&&fc_set_value_var_nvl. 'moat369_conf_date_from'      '&&moat369_conf_date_from.'      'YYYY-MM-DD'
@@&&fc_set_value_var_nvl. 'moat369_conf_date_to'        '&&moat369_conf_date_to.'        'YYYY-MM-DD'
@@&&fc_set_value_var_nvl. 'moat369_conf_work_time_from' '&&moat369_conf_work_time_from.' '0730'
@@&&fc_set_value_var_nvl. 'moat369_conf_work_time_to'   '&&moat369_conf_work_time_to.'   '1930'
@@&&fc_set_value_var_nvl. 'moat369_conf_work_day_from'  '&&moat369_conf_work_day_from.'  '2'
@@&&fc_set_value_var_nvl. 'moat369_conf_work_day_to'    '&&moat369_conf_work_day_to.'    '6'

@@&&fc_validate_variable. moat369_conf_days           IS_NUMBER
@@&&fc_validate_variable. moat369_conf_work_time_from IS_NUMBER
@@&&fc_validate_variable. moat369_conf_work_time_to   IS_NUMBER
@@&&fc_validate_variable. moat369_conf_work_day_from  IS_NUMBER
@@&&fc_validate_variable. moat369_conf_work_day_to    IS_NUMBER

---------------------------

@@&&fc_def_empty_var.      moat369_sw_desc_linesize
@@&&fc_set_value_var_nvl. 'moat369_sw_desc_linesize'  '&&moat369_sw_desc_linesize.'  '80'
@@&&fc_validate_variable.  moat369_sw_desc_linesize   IS_NUMBER
