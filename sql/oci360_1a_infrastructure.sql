-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_INSTANCES'
@@&&fc_json_loader. 'OCI360_SUBNETS'
@@&&fc_json_loader. 'OCI360_VCNS'
@@&&fc_json_loader. 'OCI360_PRIVATEIPS'
@@&&fc_json_loader. 'OCI360_REMOTE_PEERING'
@@&&fc_json_loader. 'OCI360_LOCAL_PEERING'
@@&&fc_json_loader. 'OCI360_PUBLICIPS'
@@&&fc_json_loader. 'OCI360_VNIC_ATTACHS'
@@&&fc_json_loader. 'OCI360_VNICS'
@@&&fc_json_loader. 'OCI360_DRG_ATTACHS'
-----------------------------------------

DEF title = 'Infrastructure Visual Design'

-- Run OCI360 webvowl function.
DEF fc_webvowl    = '&&moat369_sw_folder./oci360_fc_webvowl.sql'
@@&&fc_webvowl.

DEF oci360_webvowl_index_file = 'webvowl_index.html'
DEF oci360_webvowl_index_path = '&&moat369_sw_base./&&moat369_sw_misc_fdr./&&oci360_webvowl_index_file.'
DEF oci360_webvowl_filename = '&&oci360_webvowl_index_file.'
@@&&fc_seq_output_file. oci360_webvowl_filename
@@&&fc_def_output_file. oci360_webvowl_fpath_filename '&&oci360_webvowl_filename.'

HOS cat &&oci360_webvowl_index_path. > &&oci360_webvowl_fpath_filename.
HOS zip -mj &&moat369_zip_filename. &&oci360_webvowl_fpath_filename. >> &&moat369_log3.

@@&&fc_def_output_file. one_spool_html_file 'infra_view_&&current_time..html'

HOS echo '<iframe src="&&oci360_webvowl_filename." height="600" width="100%"></iframe>' > &&one_spool_html_file.

DEF row_num_dif    = 2
DEF skip_html      = '--'
DEF skip_html_file = ''

@@&&9a_pre_one.

UNDEF fc_webvowl