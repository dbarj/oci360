-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_BACKUPS'
@@&&fc_table_loader. 'OCI360_VOLUMES'
@@&&fc_table_loader. 'OCI360_COMPARTMENTS'
@@&&fc_table_loader. 'OCI360_BKP_POLICY'
@@&&fc_table_loader. 'OCI360_BKP_POLICY_ASSIGN'
@@&&fc_table_loader. 'OCI360_VOLGROUP_BKP'
-----------------------------------------

-----------------------------------------
-- Backups are not an identical copy of the volume being backed up.
-- For incremental backups, they are a record of all the changes since the last backup.
-- For full backups, they are a record of all the changes since the volume was created.
-- For example, in a scenario where you create a 16 TB block volume, modify 40 GB on the volume, and then launch a full backup,
-- upon completion the volume backup size is 40 GB.
-- https://docs.cloud.oracle.com/iaas/Content/Block/Concepts/blockvolumebackups.htm

DEF title = 'Volume Backups - Available'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := q'{
SELECT t2.display_name VOLUME_NAME,
       t1.type,
       t1.size_in_gbs,
       t1.size_in_mbs,
       t1.source_type,
       t1.display_name,
       t1.time_created,
       t3.name COMPARTMENT_NAME,
       t1.expiration_time,
       t1.lifecycle_state,
       t1.unique_size_in_gbs,
       t1.unique_size_in_mbs,
       t1.time_request_received,
       t1.volume_id,
       t1.id
FROM   OCI360_BACKUPS t1,
       OCI360_VOLUMES t2,
       OCI360_COMPARTMENTS t3
WHERE  t1.lifecycle_state = 'AVAILABLE'
AND    t1.volume_id = t2.id (+)
AND    t1.compartment_id = t3.id (+)
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Backups - Not Available'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := q'{
SELECT t2.display_name VOLUME_NAME,
       t1.type,
       t1.size_in_gbs,
       t1.size_in_mbs,
       t1.source_type,
       t1.display_name,
       t1.time_created,
       t3.name COMPARTMENT_NAME,
       t1.expiration_time,
       t1.lifecycle_state,
       t1.unique_size_in_gbs,
       t1.unique_size_in_mbs,
       t1.time_request_received,
       t1.volume_id,
       t1.id
FROM   OCI360_BACKUPS t1,
       OCI360_VOLUMES t2,
       OCI360_COMPARTMENTS t3
WHERE  t1.lifecycle_state != 'AVAILABLE'
AND    t1.volume_id = t2.id (+)
AND    t1.compartment_id = t3.id (+)
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backup Policies'
DEF main_table = 'OCI360_BKP_POLICY'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_BKP_POLICY t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backup Policies Assignments'
DEF main_table = 'OCI360_BKP_POLICY_ASSIGN'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_BKP_POLICY_ASSIGN t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Group Backups'
DEF main_table = 'OCI360_VOLGROUP_BKP'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       TYPE,
       SIZE_IN_GBS,
       SIZE_IN_MBS,
       DISPLAY_NAME,
       TIME_CREATED,
       COMPARTMENT_ID,
       LIFECYCLE_STATE,
       VOLUME_GROUP_ID,
       UNIQUE_SIZE_IN_GBS,
       UNIQUE_SIZE_IN_MBS,
       TIME_REQUEST_RECEIVED
FROM   OCI360_VOLGROUP_BKP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Group Backups - Volume Backup IDs'
DEF main_table = 'OCI360_VOLGROUP_BKP'

BEGIN
  :sql_text := q'{
SELECT ID,
       TYPE,
       DISPLAY_NAME,
       COMPARTMENT_ID,
       VOLUME_BACKUP_IDS
FROM   OCI360_VOLGROUP_BKP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Incremental Vol Backups without a prior Full'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := q'{
SELECT t1.display_name BACKUP_NAME,
       t2.display_name ASSET_NAME,
       'Volume' ASSET_TYPE,
       t1.type,
       t1.volume_id asset_id,
       t1.size_in_gbs,
       t1.source_type,
       t1.time_created,
       t1.compartment_id,
       t1.expiration_time,
       t1.lifecycle_state,
       t1.unique_size_in_gbs,
       t1.time_request_received,
       t1.id
FROM   OCI360_BACKUPS t1, OCI360_VOLUMES t2
WHERE  t1.type='INCREMENTAL'
AND    t1.lifecycle_state='AVAILABLE'
AND    t1.volume_id = t2.id (+)
AND    NOT EXISTS (SELECT 1
                   FROM   OCI360_BACKUPS t3
                   WHERE  t1.type='FULL'
                   AND    t1.lifecycle_state='AVAILABLE'
                   AND    t1.volume_id=t3.volume_id
                   AND    to_timestamp_tz(t1.time_created,'&&oci360_tzcolformat.') > to_timestamp_tz(t3.time_created,'&&oci360_tzcolformat.')
                  )
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backups for terminated Volumes'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := q'{
SELECT t1.display_name BACKUP_NAME,
       t2.display_name ASSET_NAME,
       'Volume' ASSET_TYPE,
       t1.type,
       t1.volume_id asset_id,
       t1.size_in_gbs,
       t1.source_type,
       t1.time_created,
       t1.compartment_id,
       t1.expiration_time,
       t1.lifecycle_state,
       t1.unique_size_in_gbs,
       t1.time_request_received,
       t1.id
FROM   OCI360_BACKUPS t1, OCI360_VOLUMES t2
WHERE  t1.lifecycle_state='AVAILABLE'
AND    t1.volume_id = t2.id (+)
AND    t2.lifecycle_state (+) != 'TERMINATED'
AND    t2.id is null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

-- This SQL will be repeated in several queries
VAR sql_text_bkps_future CLOB;

BEGIN
  :sql_text_bkps_future := q'{
days_in_future as (
SELECT vdate,
       decode(to_number(to_char (vdate, 'd', 'nls_date_language=english')),1,1,0) is_sunday,
       decode(vdate,trunc(vdate,'MM'),1,0)                                        is_month_first_day,
       decode(vdate,trunc(vdate,'YYYY'),1,0)                                      is_year_first_day
FROM   (SELECT  trunc(sysdate) + rownum vdate
        FROM    dual
        CONNECT BY LEVEL <= 366*6 -- 6 Years
       )
),
days_in_future_period as (
SELECT vdate,
       case
         when is_sunday+is_month_first_day+is_year_first_day = 0
           then 'ONE_DAY'
         when is_sunday=1 and is_month_first_day+is_year_first_day = 0
           then 'ONE_WEEK'
         when is_month_first_day=1 and is_year_first_day = 0
           then 'ONE_MONTH'
         else 'ONE_YEAR'
         end period
FROM   days_in_future
),
bkp_policies as (
SELECT distinct
       id policy_id,
       display_name policy_name,
       schedules$period period,
       schedules$backup_type type,
       schedules$retention_seconds retention_seconds
FROM   OCI360_BKP_POLICY
),
bkps_in_future as (
select t2.policy_name,
       t2.policy_id,
       t1.period,
       t2.type,
       t1.vdate creation_date,
       t1.vdate+ (t2.retention_seconds/(60*60*24)) expire_date
FROM   days_in_future_period t1,
       bkp_policies t2
WHERE  t1.period=t2.period
)
}';
END;
/

-----------------------------------------

DEF title = 'Total Volume Backup Forecast (By Volume)'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := 'WITH ' || :sql_text_bkps_future || ',' || q'{
bkps as (
select jt.DISPLAY_NAME VOLUME_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_GBS,
       jt.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       tas.creation_date,
       tas.expire_date,
       jt.ID
from   bkps_in_future tas,
       OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign
WHERE  jt.COMPARTMENT_ID = tcomp.ID
AND    jt.ID = tbkppolassign.ASSET_ID (+)
AND    tbkppolassign.POLICY_ID = tas.POLICY_ID (+)
UNION ALL
SELECT jt.DISPLAY_NAME VOLUME_NAME,
       jt.IS_HYDRATED,
       jt.SIZE_IN_GBS,
       jt.TIME_CREATED,
       tcomp.NAME COMPARTMENT_NAME,
       jt.LIFECYCLE_STATE,
       jt.VOLUME_GROUP_ID,
       jt.AVAILABILITY_DOMAIN,
       cast(to_timestamp_tz(t1.time_created,'&&oci360_tzcolformat.') AT LOCAL AS DATE) creation_date,
       nvl(cast(to_timestamp_tz(t1.expiration_time,'&&oci360_tzcolformat.') AT LOCAL AS DATE),sysdate+10000) expire_date,
       jt.ID
FROM   OCI360_BACKUPS t1,
       OCI360_VOLUMES jt,
       OCI360_COMPARTMENTS tcomp
WHERE  t1.lifecycle_state = 'AVAILABLE'
AND    t1.volume_id = jt.id (+)
AND    t1.compartment_id = tcomp.id
)
select VOLUME_NAME,
       IS_HYDRATED,
       SIZE_IN_GBS,
       TIME_CREATED,
       COMPARTMENT_NAME,
       LIFECYCLE_STATE,
       VOLUME_GROUP_ID,
       AVAILABILITY_DOMAIN,
       SUM(CASE WHEN SYSDATE                BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) TODAY,
       SUM(CASE WHEN ADD_MONTHS(SYSDATE,1)  BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) NEXT_1MONTH_BKPS,
       SUM(CASE WHEN ADD_MONTHS(SYSDATE,2)  BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) NEXT_2MONTH_BKPS,
       SUM(CASE WHEN ADD_MONTHS(SYSDATE,3)  BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) NEXT_3MONTH_BKPS,
       SUM(CASE WHEN ADD_MONTHS(SYSDATE,12) BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) NEXT_YEAR_BKPS,
       SUM(CASE WHEN ADD_MONTHS(SYSDATE,24) BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) NEXT_2YEAR_BKPS,
       SUM(CASE WHEN ADD_MONTHS(SYSDATE,60) BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) NEXT_5YEAR_BKPS,
       ID
from   bkps
GROUP BY VOLUME_NAME,
         IS_HYDRATED,
         SIZE_IN_GBS,
         TIME_CREATED,
         COMPARTMENT_NAME,
         LIFECYCLE_STATE,
         VOLUME_GROUP_ID,
         AVAILABILITY_DOMAIN,
         ID
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Total Volume Backups Forecast'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := 'WITH ' || :sql_text_bkps_future || ',' || q'{
bkps as (
select tas.creation_date,
       tas.expire_date,
       tas.type
from   bkps_in_future tas,
       OCI360_VOLUMES jt,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign
WHERE  jt.ID = tbkppolassign.ASSET_ID
AND    tbkppolassign.POLICY_ID = tas.POLICY_ID
UNION ALL
SELECT cast(to_timestamp_tz(t1.time_created,'&&oci360_tzcolformat.') AT LOCAL AS DATE) creation_date,
       nvl(cast(to_timestamp_tz(t1.expiration_time,'&&oci360_tzcolformat.') AT LOCAL AS DATE),sysdate+10000) expire_date,
       t1.type
FROM   OCI360_BACKUPS t1
WHERE  t1.lifecycle_state = 'AVAILABLE'
),
bkps_sum as (
select vord,
       vdate,
       type,
       SUM(CASE WHEN vdate BETWEEN creation_date AND expire_date THEN 1 ELSE 0 END) TOTAL
from   bkps,
       ( SELECT  rownum vord, trunc(sysdate) + ((ROWNUM-1)*10) vdate -- (10 in 10 days)
         FROM    dual
         CONNECT BY LEVEL <= (366*6) -- 6 Years
       ) days
where  vdate <= ADD_MONTHS(sysdate,12*6) -- 6 Years
group by vord, vdate, type
)
select
  vord             snap_id,
  TO_CHAR(vdate,  'YYYY-MM-DD HH24:MI:SS') begin_time,
  TO_CHAR(vdate+1,'YYYY-MM-DD HH24:MI:SS') end_time,
  SUM(total)       line1,
  SUM(CASE WHEN type = 'INCREMENTAL' THEN total ELSE 0 END)     line2,
  SUM(CASE WHEN type = 'FULL'        THEN total ELSE 0 END)     line3,
  0                dummy_04,
  0                dummy_05,
  0                dummy_06,
  0                dummy_07,
  0                dummy_08,
  0                dummy_09,
  0                dummy_10,
  0                dummy_11,
  0                dummy_12,
  0                dummy_13,
  0                dummy_14,
  0                dummy_15
from bkps_sum
group by vord, vdate
order by vord asc
}';
END;
/
DEF tit_01 = 'Total Backups'
DEF tit_02 = 'Incr Backups'
DEF tit_03 = 'Full Backups'

DEF vaxis = '# of Backups'
DEF chartype = 'AreaChart'
DEF stacked = ''

DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Total Volume Backups Size Forecast - Avg'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := 'WITH ' || :sql_text_bkps_future || ',' || q'{
bkp_size_estimation as (
select   DECODE(type,'INCREMENTAL',avg(unique_size_in_gbs),'FULL',max(unique_size_in_gbs)) est_unique_size_in_gbs,
         type,
         volume_id
FROM     OCI360_BACKUPS
WHERE    lifecycle_state = 'AVAILABLE'
GROUP BY type,
         volume_id
),
bkps as (
select tas.creation_date,
       tas.expire_date,
       bse.est_unique_size_in_gbs unique_size_in_gbs,
       tas.type
from   bkps_in_future tas,
       OCI360_VOLUMES jt,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       bkp_size_estimation bse
WHERE  jt.ID = tbkppolassign.ASSET_ID
AND    tbkppolassign.POLICY_ID = tas.POLICY_ID
AND    jt.ID = bse.volume_id (+)
AND    tas.type = bse.type (+)
UNION ALL
SELECT cast(to_timestamp_tz(t1.time_created,'&&oci360_tzcolformat.') AT LOCAL AS DATE) creation_date,
       nvl(cast(to_timestamp_tz(t1.expiration_time,'&&oci360_tzcolformat.') AT LOCAL AS DATE),sysdate+10000) expire_date,
       unique_size_in_gbs,
       t1.type
FROM   OCI360_BACKUPS t1
WHERE  t1.lifecycle_state = 'AVAILABLE'
),
bkps_sum_day as (
select vdate,
       type,
       SUM(CASE WHEN vdate BETWEEN creation_date AND expire_date THEN unique_size_in_gbs ELSE 0 END) TOTAL
from   bkps,
       ( SELECT  trunc(sysdate) + ((ROWNUM-1)*10) vdate -- (10 in 10 days)
         FROM    dual
         CONNECT BY LEVEL <= (366*6) -- 6 Years
       ) days
where  vdate <= ADD_MONTHS(sysdate,12*6) -- 6 Years
group by vdate, type
),
bkps_sum_month as ( 
select   trunc(vdate,'mm') vdate,
         type,
         max(total) total
from     bkps_sum_day
group by trunc(vdate,'mm'), type
),
result as (
select rank() over (order by vdate asc)                                snap_id,
       TO_CHAR(vdate, 'YYYY-MM-DD HH24:MI:SS')                         begin_time,
       TO_CHAR(ADD_MONTHS(vdate,1),'YYYY-MM-DD HH24:MI:SS')            end_time,
       CEIL(SUM(total))                                                line1,
       CEIL(SUM(CASE WHEN type = 'INCREMENTAL' THEN total ELSE 0 END)) line2,
       CEIL(SUM(CASE WHEN type = 'FULL'        THEN total ELSE 0 END)) line3
from   bkps_sum_month
group  by vdate
)
select snap_id,
       begin_time,
       end_time,
       line1,
       line2,
       line3,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
from   result
order by snap_id
}';
END;
/
DEF tit_01 = 'Total Backups Size (GB)'
DEF tit_02 = 'Incr Backups Size (GB)'
DEF tit_03 = 'Full Backups Size (GB)'
DEF foot = 'Future sizes are avarage of previous backups size.<br>';
DEF vaxis = 'Size of Backups (GB)'
DEF chartype = 'AreaChart'
DEF stacked = ''

DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Total Volume Backups Cost Forecast - Avg'
DEF main_table = 'OCI360_BACKUPS'

BEGIN
  :sql_text := 'WITH ' || :sql_text_bkps_future || ',' || q'{
bkp_size_estimation as (
select   DECODE(type,'INCREMENTAL',avg(unique_size_in_gbs),'FULL',max(unique_size_in_gbs)) est_unique_size_in_gbs,
         type,
         volume_id
FROM     OCI360_BACKUPS
WHERE    lifecycle_state = 'AVAILABLE'
GROUP BY type,
         volume_id
),
bkps as (
select tas.creation_date,
       tas.expire_date,
       bse.est_unique_size_in_gbs unique_size_in_gbs,
       tas.type
from   bkps_in_future tas,
       OCI360_VOLUMES jt,
       OCI360_BKP_POLICY_ASSIGN tbkppolassign,
       bkp_size_estimation bse
WHERE  jt.ID = tbkppolassign.ASSET_ID
AND    tbkppolassign.POLICY_ID = tas.POLICY_ID
AND    jt.ID = bse.volume_id (+)
AND    tas.type = bse.type (+)
UNION ALL
SELECT cast(to_timestamp_tz(t1.time_created,'&&oci360_tzcolformat.') AT LOCAL AS DATE) creation_date,
       nvl(cast(to_timestamp_tz(t1.expiration_time,'&&oci360_tzcolformat.') AT LOCAL AS DATE),sysdate+10000) expire_date,
       unique_size_in_gbs,
       t1.type
FROM   OCI360_BACKUPS t1
WHERE  t1.lifecycle_state = 'AVAILABLE'
),
bkps_sum_day as (
select vdate,
       type,
       SUM(CASE WHEN vdate BETWEEN creation_date AND expire_date THEN unique_size_in_gbs ELSE 0 END) TOTAL
from   bkps,
       ( SELECT  trunc(sysdate) + ((ROWNUM-1)*10) vdate -- (10 in 10 days)
         FROM    dual
         CONNECT BY LEVEL <= (366*6) -- 6 Years
       ) days
where  vdate <= ADD_MONTHS(sysdate,12*6) -- 6 Years
group by vdate, type
),
bkps_sum_month as ( 
select   trunc(vdate,'mm') vdate,
         type,
         max(total) total
from     bkps_sum_day
group by trunc(vdate,'mm'), type
),
result as (
SELECT rank() over (order by vdate asc)                                      snap_id,
       TO_CHAR(vdate, 'YYYY-MM-DD HH24:MI:SS')                               begin_time,
       TO_CHAR(ADD_MONTHS(vdate,1),'YYYY-MM-DD HH24:MI:SS')                  end_time,
       ROUND(SUM(total)*MF,2)                                                line1,
       ROUND(SUM(CASE WHEN type = 'INCREMENTAL' THEN total ELSE 0 END)*MF,2) line2,
       ROUND(SUM(CASE WHEN type = 'FULL'        THEN total ELSE 0 END)*MF,2) line3
FROM   bkps_sum_month,
       "&&oci360_obj_pricing."
WHERE  subject = 'STORAGE'
AND    inst_type = 'Object Storage' -- Backups are encrypted and stored in Oracle Cloud Infrastructure Object Storage
GROUP  BY vdate, MF
)
select snap_id,
       begin_time,
       end_time,
       line1,
       line2,
       line3,
       0 dummy_04,
       0 dummy_05,
       0 dummy_06,
       0 dummy_07,
       0 dummy_08,
       0 dummy_09,
       0 dummy_10,
       0 dummy_11,
       0 dummy_12,
       0 dummy_13,
       0 dummy_14,
       0 dummy_15
from   result
order by snap_id
}';
END;
/
DEF tit_01 = 'Total Backups - US$ Cost per month'
DEF tit_02 = 'Incr Backups - US$ Cost per month'
DEF tit_03 = 'Full Backups - US$ Cost per month'
DEF foot = 'Future costs are estimations based on previous backups size.<br>';
DEF vaxis = 'US$'
DEF chartype = 'AreaChart'
DEF stacked = ''
DEF skip_lch = ''
@@&&skip_billing_sql.&&9a_pre_one.
@@&&fc_reset_defs.

-----------------------------------------

EXEC :sql_text_bkps_future := '';