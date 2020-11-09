--------------------------
-- Check oci360_adb_uri --
--------------------------

@@&&fc_def_output_file. oci360_step_file 'oci360_step_file.sql'
HOS touch "&&oci360_step_file."

@@&&fc_set_term_off.

COL oci360_adb_uri NEW_V oci360_adb_uri
SELECT TRIM('/' FROM '&&oci360_adb_uri.') || '/' oci360_adb_uri FROM DUAL;
COL oci360_adb_uri clear

DEF oci360_adb_uri_pattern = 'https://objectstorage.[^.]*.oraclecloud.com/n/[^/]*/b/[^/]*/o/'

DEF oci360_check = 0
COL oci360_check NEW_V oci360_check
SELECT count(*) oci360_check
from DUAL
WHERE REGEXP_LIKE ('&&oci360_adb_uri.','&&oci360_adb_uri_pattern.');
COL oci360_check clear

HOS if [ &&oci360_check. -eq 0 ]; then printf 'PRO\nPRO Variable oci360_adb_uri is with wrong pattern. It should be "https://objectstorage.REGION.oraclecloud.com/n/NAMESPACE/b/BUCKET/o/".\nHOS rm -f original_settings.sql "&&oci360_step_file."\nEXIT 1' > &&oci360_step_file.; fi

SET TERM ON

@@&&oci360_step_file.
@@&&fc_set_term_off.

---------------------------
-- Check oci360_adb_cred --
---------------------------

DEF oci360_check = 0
COL oci360_check NEW_V oci360_check
SELECT count(*) oci360_check
from all_credentials
WHERE CREDENTIAL_NAME = '&&oci360_adb_cred.';
COL oci360_check clear

HOS if [ &&oci360_check. -eq 0 ]; then printf 'PRO\nPRO Could not find the credential oci360_adb_cred: "&&oci360_adb_cred.".\nHOS rm -f original_settings.sql "&&oci360_step_file."\nEXIT 1' > &&oci360_step_file.; fi

SET TERM ON

@@&&oci360_step_file.
@@&&fc_set_term_off.

---------------------------
-- Check DBMS_CLOUD.LIST --
---------------------------

@@&&fc_def_output_file. oci360_step_out 'oci360_step_out.sql'

@@&&fc_spool_start.
SPO &&oci360_step_file.
PRO @@&&fc_spool_start.
PRO SET ECHO OFF FEED ON VER ON HEAD ON SERVEROUT ON
PRO SPO &&oci360_step_out.
PRO SELECT count(*) from 
PRO table(DBMS_CLOUD.LIST_OBJECTS (
PRO        credential_name      => '&&oci360_adb_cred.',
PRO        location_uri         => '&&oci360_adb_uri.'))
PRO ;;
PRO SPO OFF
PRO @@&&fc_spool_end.
SPO OFF
@@&&fc_spool_end.

@@&&oci360_step_file.

HOS if [ $(cat "&&oci360_step_out." | grep 'ORA-' | wc -l) -ge 1 ]; then printf 'PRO\nPRO Error when running DBMS_CLOUD.LIST_OBJECTS...\nPRO Check the credential permissions and the URL.\nPRO\nHOS cat "&&oci360_step_out."\nHOS rm -f original_settings.sql "&&oci360_step_file." "&&oci360_step_out."\nEXIT 1' > &&oci360_step_file.; fi
SET TERM ON

@@&&oci360_step_file.
@@&&fc_set_term_off.

HOS rm -f &&oci360_step_file.
HOS rm -f &&oci360_step_out.

UNDEF oci360_step_file oci360_step_out