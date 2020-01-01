-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_BVOLUMES'
@@&&fc_json_loader. 'OCI360_COMPARTMENTS'
@@&&fc_json_loader. 'OCI360_IMAGES'
@@&&fc_json_loader. 'OCI360_BKP_POLICY'
@@&&fc_json_loader. 'OCI360_BKP_POLICY_ASSIGN'
@@&&fc_json_loader. 'OCI360_BV_BACKUPS'
@@&&fc_json_loader. 'OCI360_BV_ATTACHS'
-----------------------------------------

DEF title = 'Boot-Volumes'
DEF main_table = 'OCI360_BVOLUMES'

BEGIN
  :sql_text := q'{
SELECT tb.DISPLAY_NAME BOOT_VOLUME_NAME,
       timg.DISPLAY_NAME IMAGE_NAME,
       tb.IS_HYDRATED,
       tb.SIZE_IN_GBS,
       tb.SIZE_IN_MBS,
       tb.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       tb."SOURCE_DETAILS$ID",
       tb."SOURCE_DETAILS$TYPE",
       tb.LIFECYCLE_STATE,
       tb.VOLUME_GROUP_ID,
       tb.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       tb.ID
FROM   OCI360_BVOLUMES tb,
       OCI360_COMPARTMENTS tcomp,
       OCI360_IMAGES timg,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol
WHERE  tb.COMPARTMENT_ID = tcomp.ID
AND    tb.IMAGE_ID = timg.ID (+)
AND    tb.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
ORDER  BY COMPARTMENT_NAME, tb.TIME_CREATED DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Unallocated Boot-Volumes'
DEF main_table = 'OCI360_BVOLUMES'

BEGIN
  :sql_text := q'{
with t1 as (select /*+ materialize */ * from OCI360_BVOLUMES),
     t2 as (select /*+ materialize */ * from OCI360_BV_ATTACHS)
SELECT t1.*
FROM   t1
WHERE  not exists (SELECT 1 FROM t2 WHERE t1.id = t2.boot_volume_id and t2.lifecycle_state = 'ATTACHED')
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Boot-Volume Attachments'
DEF main_table = 'OCI360_BV_ATTACHS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_BV_ATTACHS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Boot-Volumes without a backup policy'
DEF main_table = 'OCI360_VOLGROUP_BKP'

BEGIN
  :sql_text := q'{
SELECT tb.DISPLAY_NAME BOOT_VOLUME_NAME,
       tb.IS_HYDRATED,
       tb.SIZE_IN_GBS,
       tb.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       tb.LIFECYCLE_STATE,
       tb.VOLUME_GROUP_ID,
       tb.AVAILABILITY_DOMAIN,
       tb.ID
FROM   OCI360_BVOLUMES tb,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign
WHERE  tb.COMPARTMENT_ID = tcomp.ID
AND    tb.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.ASSET_ID is null
ORDER  BY COMPARTMENT_NAME, tb.TIME_CREATED DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Boot-Volumes without full backup in last 30 days'
DEF main_table = 'OCI360_VOLGROUP_BKP'

BEGIN
  :sql_text := q'{
SELECT tb.DISPLAY_NAME BOOT_VOLUME_NAME,
       tb.IS_HYDRATED,
       tb.SIZE_IN_GBS,
       tb.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       tb.LIFECYCLE_STATE,
       tb.VOLUME_GROUP_ID,
       tb.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       max(to_timestamp_tz(tbkp.time_created,'&&oci360_tzcolformat.')) LATEST_FULL,
       tb.ID
FROM   OCI360_BVOLUMES tb,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol,
       OCI360_BV_BACKUPS tbkp
WHERE  tb.COMPARTMENT_ID = tcomp.ID
AND    tb.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
AND    tb.ID = tbkp.boot_volume_id (+)
AND    tbkp.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp.TYPE (+) = 'FULL'
GROUP BY tb.DISPLAY_NAME,
         tb.IS_HYDRATED,
         tb.SIZE_IN_GBS,
         tb.TIME_CREATED,
         tcomp.NAME,
         tb.LIFECYCLE_STATE,
         tb.VOLUME_GROUP_ID,
         tb.AVAILABILITY_DOMAIN,
         tbkppol.POLICY_NAME,
         tb.ID
HAVING  max(to_timestamp_tz(tbkp.time_created,'&&oci360_tzcolformat.')) <= to_date('&&moat369_date_to.','YYYY-MM-DD') - 30
OR      max(to_timestamp_tz(tbkp.time_created,'&&oci360_tzcolformat.')) is null
ORDER  BY COMPARTMENT_NAME, LATEST_FULL DESC NULLS LAST
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Boot-Volumes latest backup'
DEF main_table = 'OCI360_VOLGROUP_BKP'

BEGIN
  :sql_text := q'{
SELECT tb.DISPLAY_NAME BOOT_VOLUME_NAME,
       tb.IS_HYDRATED,
       tb.SIZE_IN_GBS,
       tb.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       tb.LIFECYCLE_STATE,
       tb.VOLUME_GROUP_ID,
       tb.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       max(to_timestamp_tz(tbkp1.time_created,'&&oci360_tzcolformat.')) LATEST_FULL,
       max(to_timestamp_tz(tbkp2.time_created,'&&oci360_tzcolformat.')) LATEST_INCR,
       tb.ID
FROM   OCI360_BVOLUMES tb,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol,
       OCI360_BV_BACKUPS tbkp1,
       OCI360_BV_BACKUPS tbkp2
WHERE  tb.COMPARTMENT_ID = tcomp.ID
AND    tb.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
AND    tb.ID = tbkp1.boot_volume_id (+)
AND    tb.ID = tbkp2.boot_volume_id (+)
AND    tbkp1.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp1.TYPE (+) = 'FULL'
AND    tbkp2.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp2.TYPE (+) = 'INCREMENTAL'
GROUP BY tb.DISPLAY_NAME,
         tb.IS_HYDRATED,
         tb.SIZE_IN_GBS,
         tb.TIME_CREATED,
         tcomp.NAME,
         tb.LIFECYCLE_STATE,
         tb.VOLUME_GROUP_ID,
         tb.AVAILABILITY_DOMAIN,
         tbkppol.POLICY_NAME,
         tb.ID
ORDER  BY COMPARTMENT_NAME, LATEST_FULL DESC NULLS LAST
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Boot-Volumes Backup Size Percentile'
DEF main_table = 'OCI360_VOLUMES'

BEGIN
  :sql_text := q'{
SELECT jt.DISPLAY_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_GBS,
       jt.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       -- FULL
       MAX(tbkp1.unique_size_in_gbs)                                              full_unique_max,
       -- INCR
       MAX(tbkp2.unique_size_in_gbs)                                              incr_unique_max,
       PERCENTILE_DISC(0.75)   WITHIN GROUP (ORDER BY tbkp2.unique_size_in_gbs)   incr_unique_75,
       ROUND(AVG(tbkp2.unique_size_in_gbs), 1)                                    incr_unique_avg,
       jt.ID
FROM   OCI360_BVOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol,
       OCI360_BV_BACKUPS tbkp1,
       OCI360_BV_BACKUPS tbkp2
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
AND    jt.ID = tbkp1.boot_volume_id (+)
AND    jt.ID = tbkp2.boot_volume_id (+)
AND    tbkp1.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp1.TYPE (+) = 'FULL'
AND    tbkp2.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp2.TYPE (+) = 'INCREMENTAL'
GROUP BY jt.DISPLAY_NAME,
         jt.IS_HYDRATED,
         jt.SIZE_IN_GBS,
         jt.TIME_CREATED,
         tcomp.NAME,
         jt.LIFECYCLE_STATE,
         jt.VOLUME_GROUP_ID,
         jt.AVAILABILITY_DOMAIN,
         tbkppol.POLICY_NAME,
         jt.ID
ORDER  BY COMPARTMENT_NAME, jt.TIME_CREATED DESC
}';
END;
/
@@&&9a_pre_one.