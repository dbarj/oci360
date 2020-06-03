-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_AUDIT_EVENTS'
-----------------------------------------

DEF max_rows = 1000
DEF title = 'Audit Events - Last &&max_rows. lines'
DEF main_table = 'OCI360_AUDIT_EVENTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUDIT_EVENTS t1
WHERE  t1.DATA$REQUEST$ACTION not in ('GET','HEAD')
ORDER BY EVENT_TIME DESC FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF max_rows = 100
DEF title = 'Audit Events - 100 random lines'
DEF main_table = 'OCI360_AUDIT_EVENTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUDIT_EVENTS SAMPLE (0.1) t1
FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Request Events per User'
DEF main_table = 'OCI360_AUDIT_EVENTS'

BEGIN
  :sql_text := q'{
SELECT DATA$EVENT_NAME,
       SOURCE,
       EVENT_TYPE,
       DATA$IDENTITY$PRINCIPAL_NAME,
       REGEXP_REPLACE(DATA$IDENTITY$PRINCIPAL_ID,'ocid1.instance.oc1.*','ocid1.instance.oc1.*') DATA$IDENTITY$PRINCIPAL_ID,
       REGEXP_REPLACE(DATA$IDENTITY$IP_ADDRESS,'172.24.*','172.24.*') DATA$IDENTITY$IP_ADDRESS,
       DATA$REQUEST$ACTION,
       COUNT(*)
FROM   OCI360_AUDIT_EVENTS t1
GROUP BY DATA$EVENT_NAME,
         SOURCE,
         EVENT_TYPE,
         DATA$IDENTITY$PRINCIPAL_NAME,
         REGEXP_REPLACE(DATA$IDENTITY$PRINCIPAL_ID,'ocid1.instance.oc1.*','ocid1.instance.oc1.*'),
         REGEXP_REPLACE(DATA$IDENTITY$IP_ADDRESS,'172.24.*','172.24.*'),
         DATA$REQUEST$ACTION
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
select DISTINCT
       DATA$EVENT_NAME,
       cast(TO_TIMESTAMP_TZ(EVENT_TIME,'&&oci360_tzcolformat.') AT LOCAL AS DATE) EVENT_TIME,
       EVENT_TYPE,
       SOURCE,
--     CREDENTIAL_ID,
       DATA$IDENTITY$TENANT_ID,
       DATA$IDENTITY$PRINCIPAL_NAME,
       DATA$IDENTITY$PRINCIPAL_ID,
       DATA$IDENTITY$USER_AGENT,
       DATA$IDENTITY$IP_ADDRESS,
       DATA$RESPONSE$RESPONSE_TIME,
       DATA$COMPARTMENT_ID,
       DATA$COMPARTMENT_NAME,
       DATA$REQUEST$ACTION,
       DATA$RESPONSE$STATUS,
       DATA$RESOURCE_NAME,
       DATA$RESOURCE_ID
--     NVL("response_payload$id","response_payload$id") response_payload$id,
--     NVL("response_payload$ResourceName","response_payload$resourceName") response_payload$resourceName
FROM   OCI360_AUDIT_EVENTS
WHERE  SOURCE='@filter_predicate@'
AND    DATA$REQUEST$ACTION not in ('GET','HEAD')
ORDER BY EVENT_TIME DESC
}';
END;
/

-----------------------------------------

DEF title = 'Compute Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'ComputeApi');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Block Volume Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'BlockVolumes');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Object Storage Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'ObjectStorage');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'File Storage Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'FileStorage');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Network Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'VirtualCloudNetworksApi');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'DatabaseService');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Identity Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'IdentityProvisioning');
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Load Balancer Actions'
DEF main_table = 'OCI360_AUDIT_EVENTS'

EXEC :sql_text := REPLACE(:sql_text_backup, '@filter_predicate@', 'OraLB-API');
@@&&9a_pre_one.

-----------------------------------------