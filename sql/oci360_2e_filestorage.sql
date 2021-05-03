-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_FILE_SYSTEMS'
@@&&fc_table_loader. 'OCI360_FS_EXPORTS'
@@&&fc_table_loader. 'OCI360_FS_EXPORT_SETS'
@@&&fc_table_loader. 'OCI360_MOUNT_TARGETS'
@@&&fc_table_loader. 'OCI360_SNAPSHOTS'
-----------------------------------------

DEF title = 'NFS File system'
DEF main_table = 'OCI360_FILE_SYSTEMS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_FILE_SYSTEMS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Exports'
DEF main_table = 'OCI360_FS_EXPORTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_FS_EXPORTS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Export Sets'
DEF main_table = 'OCI360_FS_EXPORT_SETS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_FS_EXPORT_SETS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Mount Targets'
DEF main_table = 'OCI360_MOUNT_TARGETS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_MOUNT_TARGETS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Snapshots'
DEF main_table = 'OCI360_SNAPSHOTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_SNAPSHOTS t1
}';
END;
/
@@&&9a_pre_one.