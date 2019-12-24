-----------------------------------------

DEF max_rows = 1000
DEF title = 'Audit Events - Last &&max_rows. lines'
DEF main_table = 'OCI360_AUDIT_EVENTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUDIT_EVENTS t1
WHERE  t1.REQUEST_ACTION not in ('GET','HEAD')
ORDER BY EVENT_TIME DESC FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Request Events per User'
DEF main_table = 'OCI360_AUDIT_EVENTS'

BEGIN
  :sql_text := q'{
SELECT EVENT_NAME,
       EVENT_SOURCE,
       EVENT_TYPE,
       USER_NAME,
       REGEXP_REPLACE(PRINCIPAL_ID,'ocid1.instance.oc1.*','ocid1.instance.oc1.*') PRINCIPAL_ID,
       REGEXP_REPLACE(REQUEST_ORIGIN,'172.24.*','172.24.*') REQUEST_ORIGIN,
       REQUEST_ACTION,
       COUNT(*)
FROM   OCI360_AUDIT_EVENTS t1
GROUP BY EVENT_NAME,
         EVENT_SOURCE,
         EVENT_TYPE,
         USER_NAME,
         REGEXP_REPLACE(PRINCIPAL_ID,'ocid1.instance.oc1.*','ocid1.instance.oc1.*'),
         REGEXP_REPLACE(REQUEST_ORIGIN,'172.24.*','172.24.*'),
         REQUEST_ACTION
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

VAR sql_text_backup CLOB

BEGIN
  :sql_text_backup := q'{
select DISTINCT
       TENANT_ID,
       USER_NAME,
       EVENT_NAME,
       cast(TO_TIMESTAMP_TZ(EVENT_TIME,'&&oci360_tzcolformat.') AT LOCAL AS DATE) EVENT_TIME,
       EVENT_TYPE,
       EVENT_SOURCE,
       PRINCIPAL_ID,
--       CREDENTIAL_ID,
       REQUEST_AGENT,
       RESPONSE_TIME,
       COMPARTMENT_ID,
       REQUEST_ACTION,
       REQUEST_ORIGIN,
       RESPONSE_STATUS,
       COMPARTMENT_NAME,
       REQUEST_RESOURCE,
       NVL("response_payload$id","response_payload$id") response_payload$id,
       NVL("response_payload$ResourceName","response_payload$resourceName") response_payload$resourceName
FROM   OCI360_AUDIT_EVENTS
WHERE  EVENT_SOURCE='@filter_predicate@'
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