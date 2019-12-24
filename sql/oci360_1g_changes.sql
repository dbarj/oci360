@@&&fc_json_loader. 'OCI360_INSTANCES'
@@&&fc_json_loader. 'OCI360_VOLUMES'
@@&&fc_json_loader. 'OCI360_SECLISTS'
-----------------------------------------

DEF oci360_func_1g = '&&moat369_sw_folder./oci360_1g_changes_func.sql'

DEF title = 'Compute changes'
@@&&oci360_func_1g. 'OCI360_INSTANCES'

DEF title = 'Volume changes'
@@&&oci360_func_1g. 'OCI360_VOLUMES'

DEF title = 'Security Lists changes'
@@&&oci360_func_1g. 'OCI360_SECLISTS'

-- DEF title = 'User changes'
-- @@&&oci360_func_1g. 'OCI360_USERS'

-- DEF title = 'Policies changes'
-- @@&&oci360_func_1g. 'OCI360_POLICIES'

UNDEF oci360_func_1g