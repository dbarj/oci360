-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_IMAGES'
@@&&fc_table_loader. 'OCI360_INSTANCES'
-----------------------------------------

DEF title = 'Images'
DEF main_table = 'OCI360_IMAGES'

BEGIN
  :sql_text := q'{
SELECT ID,
       LAUNCH_MODE,
       SIZE_IN_MBS,
       DISPLAY_NAME,
       TIME_CREATED,
       BASE_IMAGE_ID,
       AGENT_FEATURES,
       COMPARTMENT_ID,
       LAUNCH_OPTIONS$FIRMWARE,
       LAUNCH_OPTIONS$NETWORK_TYPE,
       LAUNCH_OPTIONS$BOOT_VOLUME_TYPE,
       LAUNCH_OPTIONS$REMOTE_DATA_VOLUME_TYPE,
       LAUNCH_OPTIONS$IS_CONSISTENT_VOLUME_NAMING_ENABLED,
       LAUNCH_OPTIONS$IS_PV_ENCRYPTION_IN_TRANSIT_ENABLED,
       LIFECYCLE_STATE,
       OPERATING_SYSTEM,
       CREATE_IMAGE_ALLOWED,
       OPERATING_SYSTEM_VERSION
FROM   OCI360_IMAGES
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Compute Instances per Image'
DEF main_table = 'OCI360_IMAGES'

BEGIN
  :sql_text := q'{
WITH t1 as (select /*+ materialize */ * from OCI360_INSTANCES),
     t2 as (select /*+ materialize */ * from OCI360_IMAGES)
SELECT t2.id,
       t2.display_name,
       count(*) total
FROM   t1, t2
WHERE  t1.image_id=t2.id
GROUP BY t2.id, t2.display_name
ORDER BY 3 DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------