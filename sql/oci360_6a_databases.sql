-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_DATABASES'
@@&&fc_json_loader. 'OCI360_DB_SYSTEMS'
@@&&fc_json_loader. 'OCI360_DB_SYSTEM_SHAPES'
@@&&fc_json_loader. 'OCI360_DB_VERSIONS'
@@&&fc_json_loader. 'OCI360_DB_NODES'
@@&&fc_json_loader. 'OCI360_DB_BACKUPS'
@@&&fc_json_loader. 'OCI360_DB_BACKUP_JOBS'
@@&&fc_json_loader. 'OCI360_DATAGUARD_ASSOC'
@@&&fc_json_loader. 'OCI360_DB_PATCH_BYDB'
@@&&fc_json_loader. 'OCI360_DB_PATCH_BYDB_HIST'
@@&&fc_json_loader. 'OCI360_DB_PATCH_BYDS'
@@&&fc_json_loader. 'OCI360_DB_PATCH_BYDS_HIST'
@@&&fc_json_loader. 'OCI360_PRIVATEIPS'
-----------------------------------------

DEF title = 'Databases'
DEF main_table = 'OCI360_DATABASES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DATABASES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Systems'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       SHAPE,
       DOMAIN,
       VERSION,
       HOSTNAME,
       SUBNET_ID,
       NODE_COUNT,
       CLUSTER_NAME,
       DISPLAY_NAME,
       TIME_CREATED,
       LICENSE_MODEL,
       LISTENER_PORT,
       COMPARTMENT_ID,
       CPU_CORE_COUNT,
       DISK_REDUNDANCY,
       LIFECYCLE_STATE,
       BACKUP_SUBNET_ID,
       DATABASE_EDITION,
       SPARSE_DISKGROUP,
       LIFECYCLE_DETAILS,
       SCAN_DNS_RECORD_ID,
       AVAILABILITY_DOMAIN,
       DATA_STORAGE_PERCENTAGE,
       RECO_STORAGE_SIZE_IN_GB,
       DATA_STORAGE_SIZE_IN_GBS,
       LAST_PATCH_HISTORY_ENTRY_ID
FROM   OCI360_DB_SYSTEMS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database System VIP IDs'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
SELECT ID,
       CLUSTER_NAME,
       DISPLAY_NAME,
       VIP_IDS
FROM   OCI360_DB_SYSTEMS t1
WHERE  VIP_IDS is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Systems Scan IDs'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
SELECT ID,
       CLUSTER_NAME,
       DISPLAY_NAME,
       SCAN_IP_IDS
FROM   OCI360_DB_SYSTEMS t1
WHERE  SCAN_IP_IDS is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Systems SSH Keys'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
SELECT ID,
       CLUSTER_NAME,
       DISPLAY_NAME,
       SSH_PUBLIC_KEYS
FROM   OCI360_DB_SYSTEMS t1
WHERE  SSH_PUBLIC_KEYS is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database System Shapes'
DEF main_table = 'OCI360_DB_SYSTEM_SHAPES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_SYSTEM_SHAPES t1
ORDER BY 1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Versions'
DEF main_table = 'OCI360_DB_VERSIONS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_VERSIONS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Nodes'
DEF main_table = 'OCI360_DB_NODES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_NODES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Backups'
DEF main_table = 'OCI360_DB_BACKUPS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_BACKUPS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Backup Jobs'
DEF main_table = 'OCI360_DB_BACKUP_JOBS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_BACKUP_JOBS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Dataguard Associations'
DEF main_table = 'OCI360_DATAGUARD_ASSOC'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DATAGUARD_ASSOC t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Patches by Database'
DEF main_table = 'OCI360_DB_PATCH_BYDB'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_PATCH_BYDB t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Patches by Database History'
DEF main_table = 'OCI360_DB_PATCH_BYDB_HIST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_PATCH_BYDB_HIST t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Patches by System'
DEF main_table = 'OCI360_DB_PATCH_BYDS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_PATCH_BYDS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Patches by System History'
DEF main_table = 'OCI360_DB_PATCH_BYDS_HIST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DB_PATCH_BYDS_HIST t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Database Networks'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
SELECT t1.CLUSTER_NAME,
       t1.DISPLAY_NAME,
       t1.hostname SYSTEM_HOSTNAME,
       t1.TIME_CREATED,
       t1.LIFECYCLE_STATE SYSTEM_LIFECYCLE_STATE,
       t1.SHAPE,
       'BACKUP' IP_TYPE,
       t3.ip_address,
       t2.hostname NODE_HOSTNAME,
       t2.LIFECYCLE_STATE NODE_LIFECYCLE_STATE
FROM   (select distinct id, cluster_name, display_name, hostname, time_created, lifecycle_state, shape FROM OCI360_DB_SYSTEMS) t1,
       OCI360_DB_NODES t2,
       OCI360_PRIVATEIPS t3
where  t1.id=t2.DB_SYSTEM_ID
and    t2.BACKUP_VNIC_ID = t3.VNIC_ID
and    t3.IS_PRIMARY='true'
UNION ALL
SELECT t1.CLUSTER_NAME,
       t1.DISPLAY_NAME,
       t1.hostname SYSTEM_HOSTNAME,
       t1.TIME_CREATED,
       t1.LIFECYCLE_STATE SYSTEM_LIFECYCLE_STATE,
       t1.SHAPE,
       'PUBLIC' IP_TYPE,
       t3.ip_address,
       t2.hostname NODE_HOSTNAME,
       t2.LIFECYCLE_STATE NODE_LIFECYCLE_STATE
FROM   (select distinct id, cluster_name, display_name, hostname, time_created, lifecycle_state, shape FROM OCI360_DB_SYSTEMS) t1,
       OCI360_DB_NODES t2,
       OCI360_PRIVATEIPS t3
where  t1.id=t2.DB_SYSTEM_ID
and    t2.VNIC_ID=t3.VNIC_ID
and    t3.IS_PRIMARY='true'
UNION ALL
SELECT t1.CLUSTER_NAME,
       t1.DISPLAY_NAME,
       t1.hostname SYSTEM_HOSTNAME,
       t1.TIME_CREATED,
       t1.LIFECYCLE_STATE SYSTEM_LIFECYCLE_STATE,
       t1.SHAPE,
       'VIP' IP_TYPE,
       t3.ip_address,
       t2.hostname NODE_HOSTNAME,
       t2.LIFECYCLE_STATE NODE_LIFECYCLE_STATE
FROM   (select distinct id, vip_ids, cluster_name, display_name, hostname, time_created, lifecycle_state, shape FROM OCI360_DB_SYSTEMS) t1,
       OCI360_DB_NODES t2,
       OCI360_PRIVATEIPS t3
where  t1.id=t2.DB_SYSTEM_ID
and    t2.VNIC_ID=t3.VNIC_ID
and    t1.vip_ids like '%' || t3.ID || '%'
UNION ALL
SELECT t1.CLUSTER_NAME,
       t1.DISPLAY_NAME,
       t1.hostname SYSTEM_HOSTNAME,
       t1.TIME_CREATED,
       t1.LIFECYCLE_STATE SYSTEM_LIFECYCLE_STATE,
       t1.SHAPE,
       'SCAN'    IP_TYPE,
       t3.ip_address,
       t2.hostname NODE_HOSTNAME,
       t2.LIFECYCLE_STATE NODE_LIFECYCLE_STATE
FROM   (select distinct id, scan_ip_ids, cluster_name, display_name, hostname, time_created, lifecycle_state, shape FROM OCI360_DB_SYSTEMS) t1,
       OCI360_DB_NODES t2,
       OCI360_PRIVATEIPS t3
where  t1.id=t2.DB_SYSTEM_ID
and    t2.VNIC_ID=t3.VNIC_ID
and    t1.scan_ip_ids like '%' || t3.ID || '%'
ORDER BY CLUSTER_NAME,IP_TYPE,NODE_HOSTNAME
}';
END;
/
@@&&9a_pre_one.