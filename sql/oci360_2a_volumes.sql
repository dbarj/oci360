@@&&fc_json_loader. 'OCI360_BKP_POLICY_ASSIGN'
-----------------------------------------

DEF title = 'Volumes'
DEF main_table = 'OCI360_VOLUMES'

BEGIN
  :sql_text := q'{
SELECT jt.DISPLAY_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_GBS,
       jt.SIZE_IN_MBS,
       jt.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       jt.SOURCE_DETAILS$ID,
       jt.SOURCE_DETAILS$TYPE,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       jt.ID
FROM   OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
ORDER  BY COMPARTMENT_NAME, jt.TIME_CREATED DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Total Intance Volumes'
DEF main_table = 'OCI360_VOLUMES'

BEGIN
  :sql_text := q'{
WITH t1 AS (SELECT /*+ materialize */ * FROM oci360_instances),
     t2 AS (SELECT /*+ materialize */ * FROM oci360_vol_attachs),
     t3 AS (SELECT /*+ materialize */ * FROM oci360_volumes),
     t4 AS (SELECT /*+ materialize */ * FROM oci360_bv_attachs),
     t5 AS (SELECT /*+ materialize */ * FROM oci360_bvolumes)
SELECT t1.display_name                      INSTANCE_NAME,
       COUNT(*)                             TOTAL_VOLS,
       TO_NUMBER(t5.size_in_gbs)            BOOTVOL_SIZE_GBS,
       SUM(nvl(t3.size_in_gbs,0))                  VOL_SIZE_GBS,
       t5.size_in_gbs + SUM(nvl(t3.size_in_gbs,0)) TOTAL_SIZE_GBS,
       t1.id                                INSTANCE_ID
FROM   t1, t2, t3, t4, t5
WHERE  t1.id = t2.instance_id(+)
AND    t2.volume_id = t3.id(+)
AND    t2.lifecycle_state(+) = 'ATTACHED'
AND    t1.id = t4.instance_id
AND    t4.boot_volume_id = t5.id
GROUP  BY t1.id, t1.display_name, t5.size_in_gbs
ORDER  BY total_size_gbs DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Unallocated Volumes'
DEF main_table = 'OCI360_VOLUMES'

BEGIN
  :sql_text := q'{
with t1 as (SELECT /*+ materialize */ * FROM oci360_volumes),
     t2 as (SELECT /*+ materialize */ * FROM oci360_vol_attachs)
SELECT t1.*
FROM   t1
WHERE  not exists (SELECT 1 FROM t2 WHERE t1.id = t2.volume_id AND t2.lifecycle_state = 'ATTACHED')
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Attachments'
DEF main_table = 'OCI360_VOL_ATTACHS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VOL_ATTACHS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Groups'
DEF main_table = 'OCI360_VOLGROUP'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       VOLUME_IDS,
       IS_HYDRATED,
       SIZE_IN_GBS,
       SIZE_IN_MBS,
       DISPLAY_NAME,
       TIME_CREATED,
       COMPARTMENT_ID,
       LIFECYCLE_STATE,
       AVAILABILITY_DOMAIN
FROM   OCI360_VOLGROUP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Group Sources'
DEF main_table = 'OCI360_VOLGROUP'

BEGIN
  :sql_text := q'{
SELECT ID,
       VOLUME_IDS,
       DISPLAY_NAME,
       TIME_CREATED,
       COMPARTMENT_ID,
       SOURCE_DETAILS$TYPE,
       SOURCE_DETAILS$VOLUME_IDS
FROM   OCI360_VOLGROUP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volumes without a backup policy'
DEF main_table = 'OCI360_VOLGROUP_BKP'

BEGIN
  :sql_text := q'{
SELECT jt.DISPLAY_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_GBS,
       tcomp.NAME COMPARTMENT_NAME,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       jt.ID
FROM   OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.ASSET_ID is null
ORDER  BY COMPARTMENT_NAME, jt.TIME_CREATED DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volumes without full backup in last 30 days'
DEF main_table = 'OCI360_VOLUMES'

BEGIN
  :sql_text := q'{
SELECT jt.DISPLAY_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_MBS,
       jt.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       max(to_timestamp_tz(tbkp.time_created,'&&oci360_tzcolformat.')) LATEST_FULL,
       jt.ID
FROM   OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol,
       OCI360_BACKUPS tbkp
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
AND    jt.ID = tbkp.volume_id (+)
AND    tbkp.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp.TYPE (+) = 'FULL'
GROUP BY jt.DISPLAY_NAME,
         jt.IS_HYDRATED,
         jt.SIZE_IN_MBS,
         jt.TIME_CREATED,
         tcomp.NAME,
         jt.LIFECYCLE_STATE,
         jt.VOLUME_GROUP_ID,
         jt.AVAILABILITY_DOMAIN,
         tbkppol.POLICY_NAME,
         jt.ID
HAVING  max(to_timestamp_tz(tbkp.time_created,'&&oci360_tzcolformat.')) <= to_date('&&moat369_date_to.','YYYY-MM-DD') - 30
OR      max(to_timestamp_tz(tbkp.time_created,'&&oci360_tzcolformat.')) is null
ORDER  BY COMPARTMENT_NAME, LATEST_FULL DESC NULLS LAST
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volumes latest backup'
DEF main_table = 'OCI360_VOLUMES'

BEGIN
  :sql_text := q'{
SELECT jt.DISPLAY_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_MBS,
       jt.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       tbkppol.POLICY_NAME,
       max(to_timestamp_tz(tbkp1.time_created,'&&oci360_tzcolformat.')) LATEST_FULL,
       max(to_timestamp_tz(tbkp2.time_created,'&&oci360_tzcolformat.')) LATEST_INCR,
       jt.ID
FROM   OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol,
       OCI360_BACKUPS tbkp1,
       OCI360_BACKUPS tbkp2
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
AND    jt.ID = tbkp1.volume_id (+)
AND    jt.ID = tbkp2.volume_id (+)
AND    tbkp1.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp1.TYPE (+) = 'FULL'
AND    tbkp2.LIFECYCLE_STATE (+) = 'AVAILABLE'
AND    tbkp2.TYPE (+) = 'INCREMENTAL'
GROUP BY jt.DISPLAY_NAME,
         jt.IS_HYDRATED,
         jt.SIZE_IN_MBS,
         jt.TIME_CREATED,
         tcomp.NAME,
         jt.LIFECYCLE_STATE,
         jt.VOLUME_GROUP_ID,
         jt.AVAILABILITY_DOMAIN,
         tbkppol.POLICY_NAME,
         jt.ID
ORDER  BY COMPARTMENT_NAME, LATEST_FULL DESC NULLS LAST
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volumes Backup Size Percentile'
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
FROM   OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       (select distinct id, display_name policy_name from OCI360_BKP_POLICY) tbkppol,
       OCI360_BACKUPS tbkp1,
       OCI360_BACKUPS tbkp2
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tbkppol.ID (+)
AND    jt.ID = tbkp1.volume_id (+)
AND    jt.ID = tbkp2.volume_id (+)
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