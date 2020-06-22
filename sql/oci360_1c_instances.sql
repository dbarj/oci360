-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_INSTANCES'
@@&&fc_json_loader. 'OCI360_COMPARTMENTS'
@@&&fc_json_loader. 'OCI360_IMAGES'
@@&&fc_json_loader. 'OCI360_VNIC_ATTACHS'
@@&&fc_json_loader. 'OCI360_VNICS'
@@&&fc_json_loader. 'OCI360_SHAPES'
@@&&fc_json_loader. 'OCI360_CONSOLE_CONNS'
@@&&fc_json_loader. 'OCI360_CONSOLE_HIST'
@@&&fc_json_loader. 'OCI360_VOLUMES'
@@&&fc_json_loader. 'OCI360_BACKUPS'
@@&&fc_json_loader. 'OCI360_VOL_ATTACHS'
@@&&fc_json_loader. 'OCI360_BVOLUMES'
@@&&fc_json_loader. 'OCI360_BV_BACKUPS'
@@&&fc_json_loader. 'OCI360_BV_ATTACHS'
-----------------------------------------

DEF title = 'Compute Instances'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
WITH t1 as (select /*+ materialize */ * from OCI360_INSTANCES),
     t2 as (select /*+ materialize */ * from OCI360_COMPARTMENTS),
     t3 as (select /*+ materialize */ * from OCI360_IMAGES),
     t4 as (select /*+ materialize */ * from OCI360_VNIC_ATTACHS),
     t5 as (select /*+ materialize */ * from OCI360_VNICS)
SELECT distinct t1.id,
       t1.display_name,
       t1.shape,
       t1.region,
       t1.availability_domain,
       t1.lifecycle_state,
       t3.display_name image_name,
       t3.operating_system,
       t3.operating_system_version,
       t1.fault_domain,
       t1.time_created,
       t2.name compartment_name,
       t5.private_ip ip_address_pri_primary,
       t5.public_ip  ip_address_pub_primary
FROM   t1,t2,t3,t4,t5
WHERE  t1.image_id = t3.id (+)
AND    t1.compartment_id = t2.id (+)
AND    t1.id = t4.instance_id
AND    t4.lifecycle_state = 'ATTACHED'
AND    t4.vnic_id = t5.id
AND    t5.is_primary = 'true'
AND    t5.lifecycle_state = 'AVAILABLE'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Compute Instances - Raw'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_INSTANCES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Compute Instances per Compartment'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
WITH t1 as (select /*+ materialize */ compartment_id,count(*) total_comp from OCI360_INSTANCES group by compartment_id),
     t2 as (select /*+ materialize */ * from OCI360_COMPARTMENTS),
     tot as (select sum(total_comp) total_global from t1)
SELECT t2.name || ' - ' || total_comp name,
       total_comp total,
       trim(to_char(round(total_comp/decode(total_global,0,1,total_global),4)*100,'990D99')) percent
FROM   t1, t2, tot
WHERE  t1.compartment_id=t2.id
}';
END;
/
DEF skip_pch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Compute Instances per Shape'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
WITH tot as (SELECT count(*) total_global FROM OCI360_INSTANCES)
SELECT t1.shape || ' - ' || count(*) shape,
       count(*) total,
       trim(to_char(round(count(*)/decode(total_global,0,1,total_global),4)*100,'990D99')) percent
FROM   OCI360_INSTANCES t1, tot
GROUP BY t1.shape,total_global
}';
END;
/
DEF skip_pch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Shapes'
DEF main_table = 'OCI360_SHAPES'

BEGIN
  :sql_text := q'{
WITH
  t_price_comp AS (SELECT /*+ materialize */ * FROM "&&oci360_obj_pricing." WHERE subject = 'COMPUTE')
SELECT distinct t1.shape, t2.ocpu, t2.memory_gb, t2.local_disk_tb, t2.network_gbps, t2.gpu, t3.mf "Hour US$"
FROM   OCI360_SHAPES t1,
       "&&oci360_obj_shape." t2,
       t_price_comp t3
WHERE  t1.shape = t2.shape(+)
AND    t1.shape = t3.inst_type(+)
}';
END;
/
DEF foot = '* US$ costs are estimations for Month Flex, not considering machine state or any other changes. Values base date: &&oci360_pricing_date.<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Shapes in Tenancy'
DEF main_table = 'OCI360_SHAPES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_SHAPES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Console Connections'
DEF main_table = 'OCI360_CONSOLE_CONNS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CONSOLE_CONNS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Console History'
DEF main_table = 'OCI360_CONSOLE_HIST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CONSOLE_HIST t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Instance Costs estimations'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
WITH t_inst AS (SELECT /*+ materialize */ * FROM OCI360_INSTANCES),
     t_comp AS (SELECT /*+ materialize */ * FROM oci360_compartments),
     t_img AS (SELECT /*+ materialize */ * FROM oci360_images),
     t_price_comp AS (SELECT /*+ materialize */ inst_type, mf FROM "&&oci360_obj_pricing." WHERE subject = 'COMPUTE'),
     t_price_win AS (SELECT /*+ materialize */ * FROM "&&oci360_obj_pricing." WHERE subject = 'OS_WINDOWS'),
     t_price_vol AS (SELECT /*+ materialize */ * FROM "&&oci360_obj_pricing." WHERE subject = 'STORAGE' AND inst_type = 'Block Volumes'),
     t_price_bkp AS (SELECT /*+ materialize */ * FROM "&&oci360_obj_pricing." WHERE subject = 'STORAGE' AND inst_type = 'Object Storage'),
     t_vols AS
        (SELECT t1.id,
                t5.size_in_gbs              BOOTVOL_SIZE_GBS,
                NVL(SUM(t3.size_in_gbs), 0) VOL_SIZE_GBS
         FROM   (SELECT /*+ materialize */ * FROM OCI360_INSTANCES) t1,
                (SELECT /*+ materialize */ * FROM oci360_vol_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_volumes) t3,
                (SELECT /*+ materialize */ * FROM oci360_bv_attachs) t4,
                (SELECT /*+ materialize */ * FROM oci360_bvolumes) t5
         WHERE  t1.id = t2.instance_id (+)
         AND    t2.volume_id = t3.id (+)
         AND    t2.lifecycle_state (+) = 'ATTACHED'
         AND    t1.id = t4.instance_id (+)
         AND    t4.boot_volume_id = t5.id (+)
         AND    t4.lifecycle_state (+) = 'ATTACHED'
         GROUP  BY t1.id, t5.size_in_gbs),
     t_bvols_bkp AS
        (SELECT t1.id,
                NVL(SUM(t4.unique_size_in_gbs), 0) BKP_BOOTVOL_SIZE_GBS
         FROM   (SELECT /*+ materialize */ * FROM OCI360_INSTANCES) t1,
                (SELECT /*+ materialize */ * FROM oci360_bv_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_bvolumes) t3,
                (SELECT /*+ materialize */ * FROM oci360_bv_backups) t4
         WHERE  t1.id = t2.instance_id (+)
         AND    t2.boot_volume_id = t3.id (+)
         AND    t2.lifecycle_state (+) = 'ATTACHED'
         AND    t3.id = t4.boot_volume_id (+)
         AND    t4.lifecycle_state (+) = 'AVAILABLE'
         GROUP  BY t1.id),
     t_vols_bkp AS
        (SELECT t1.id,
                NVL(SUM(t4.unique_size_in_gbs), 0) BKP_VOL_SIZE_GBS
         FROM   (SELECT /*+ materialize */ * FROM OCI360_INSTANCES) t1,
                (SELECT /*+ materialize */ * FROM oci360_vol_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_volumes) t3,
                (SELECT /*+ materialize */ * FROM oci360_backups) t4
         WHERE  t1.id = t2.instance_id (+)
            AND t2.volume_id = t3.id (+)
            AND t2.lifecycle_state (+) = 'ATTACHED'
            AND t3.id = t4.volume_id (+)
            AND t4.lifecycle_state (+) = 'AVAILABLE'
         GROUP  BY t1.id)
SELECT display_name                                  "Compute Name",
       shape                                         "Shape",
       region                                        "Region",
       availability_domain                           "AD",
       lifecycle_state                               "State",
       operating_system                              "OS",
       compartment_name                              "Compartment",
       bootvol_size_gbs                              "Boot Size",
       vol_size_gbs                                  "Volumes Size",
       bkp_size_gbs                                  "Backups Size",
       ROUND(price_comp_month, 2)                    "Shape - US$ Cost per month",
       ROUND(price_win_month, 2)                     "Windows - US$ Cost per month",
       ROUND(price_vol_month, 2)                     "Storage - US$ Cost per month",
       ROUND(price_bkp_month, 2)                     "Backup - US$ Cost per month",
       ROUND(price_comp_month + price_win_month
             + price_vol_month + price_bkp_month, 2) "Total - US$ Cost per month",
       id                                            "Instance OCID"
FROM   (SELECT t_inst.display_name,
               t_inst.shape,
               t_inst.region,
               t_inst.availability_domain,
               t_inst.lifecycle_state,
               t_img.operating_system,
               t_comp.name COMPARTMENT_NAME,
               t_vols.bootvol_size_gbs,
               t_vols.vol_size_gbs,
               t_bvols_bkp.bkp_bootvol_size_gbs + t_vols_bkp.bkp_vol_size_gbs BKP_SIZE_GBS,
               t_price_comp.mf * to_number(substr(t_inst.shape,instr(t_inst.shape,'.',-1)+1)) * 24 * 30
               price_comp_month,
               DECODE(t_img.operating_system, 'Windows',t_price_win.mf * to_number(substr(t_inst.shape,instr(t_inst.shape,'.',-1)+1)) * 24 * 30, 0) price_win_month,
               t_price_vol.mf * ( t_vols.bootvol_size_gbs + t_vols.vol_size_gbs ) price_vol_month,
               t_price_bkp.mf * ( t_bvols_bkp.bkp_bootvol_size_gbs + t_vols_bkp.bkp_vol_size_gbs ) price_bkp_month,
               t_inst.id
        FROM   t_inst,
               t_comp,
               t_img,
               t_vols,
               t_vols_bkp,
               t_bvols_bkp,
               t_price_comp,
               t_price_win,
               t_price_vol,
               t_price_bkp
        WHERE  t_inst.compartment_id = t_comp.id (+)
           AND t_inst.image_id = t_img.id (+)
           AND substr(t_inst.shape,1,instr(t_inst.shape,'.',-1)-1) = t_price_comp.inst_type (+)
--         AND t_inst.shape = t_price_win.inst_type (+)
           AND t_inst.id = t_vols.id (+)
           AND t_inst.id = t_vols_bkp.id (+)
           AND t_inst.id = t_bvols_bkp.id (+))
ORDER  BY "Total - US$ Cost per month" DESC
}';
END;
/
DEF foot = '* US$ costs are estimations for Month Flex, not considering machine state changes (24h x 30d) / volumes or any other changes. Values base date: &&oci360_pricing_date.<br>';
@@&&skip_billing_sql.&&9a_pre_one.
@@&&fc_reset_defs.

-----------------------------------------