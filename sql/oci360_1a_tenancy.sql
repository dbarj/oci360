-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_REGIONS_SUBS'
@@&&fc_json_loader. 'OCI360_LOCATION'
@@&&fc_json_loader. 'OCI360_COMPARTMENTS'
@@&&fc_json_loader. 'OCI360_ADS'
@@&&fc_json_loader. 'OCI360_FAULT_DOMAINS'
@@&&fc_json_loader. 'OCI360_VOLUMES'
@@&&fc_json_loader. 'OCI360_BVOLUMES'
@@&&fc_json_loader. 'OCI360_BACKUPS'
@@&&fc_json_loader. 'OCI360_BV_BACKUPS'
@@&&fc_json_loader. 'OCI360_OBJECTS'
@@&&fc_json_loader. 'OCI360_INSTANCES'
@@&&fc_json_loader. 'OCI360_VOL_ATTACHS'
@@&&fc_json_loader. 'OCI360_BV_ATTACHS'
-----------------------------------------

DEF title = 'Region Subscription'
DEF main_table = 'OCI360_REGIONS_SUBS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REGIONS_SUBS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Region Map'
DEF main_table = 'OCI360_REGIONS_SUBS'

-- Temporarily disable compress and encryption
DEF oci360_conf_encrypt_html  = '&&moat369_conf_encrypt_html.'
DEF oci360_conf_compress_html = '&&moat369_conf_compress_html.'
DEF moat369_conf_encrypt_html  = 'OFF'
DEF moat369_conf_compress_html = 'OFF'

BEGIN
  :sql_text := q'{
SELECT t1.region_name, t2.latitude, t2.longitude
FROM   OCI360_REGIONS_SUBS t1,
       OCI360_LOCATION t2
where  t1.region_key=t2.name
}';
END;
/
DEF skip_map = ''
@@&&9a_pre_one.

-- Turn it back
DEF moat369_conf_encrypt_html = '&&oci360_conf_encrypt_html.'
DEF moat369_conf_compress_html = '&&oci360_conf_compress_html.'

UNDEF oci360_conf_encrypt_html oci360_conf_compress_html

-----------------------------------------

DEF title = 'Compartments'
DEF main_table = 'OCI360_COMPARTMENTS'

BEGIN
  :sql_text := q'{
SELECT ID,
       NAME,
       DESCRIPTION,
       TIME_CREATED,
       INACTIVE_STATUS,
       LIFECYCLE_STATE,
       COMPARTMENT_ID PARENT_COMP_ID
FROM   OCI360_COMPARTMENTS
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'ADs'
DEF main_table = 'OCI360_ADS'

BEGIN
  :sql_text := q'{
SELECT   ID,
         NAME
FROM     OCI360_ADS
ORDER BY NAME ASC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Fault Domains'
DEF main_table = 'OCI360_FAULT_DOMAINS'

BEGIN
  :sql_text := q'{
SELECT   DISTINCT ID, NAME, AVAILABILITY_DOMAIN
FROM     OCI360_FAULT_DOMAINS
ORDER BY AVAILABILITY_DOMAIN, NAME
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Space Utilization Summary'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
WITH tvols  AS (select sum(SIZE_IN_GBS) tsize from OCI360_VOLUMES where lifecycle_state = 'AVAILABLE'),
     tbvols AS (select sum(SIZE_IN_GBS) tsize from OCI360_BVOLUMES where lifecycle_state = 'AVAILABLE'),
     tbkps  AS (select sum(UNIQUE_SIZE_IN_GBS) tsize from OCI360_BACKUPS where lifecycle_state = 'AVAILABLE'),
     tbbkps AS (select sum(UNIQUE_SIZE_IN_GBS) tsize from OCI360_BV_BACKUPS where lifecycle_state = 'AVAILABLE'),
     tbos   AS (select round(sum("SIZE")/power(1024,3)) tsize from OCI360_OBJECTS)
SELECT label, (tsize/SUM(tsize) over())*100 dummy_01, style dummy_02, mo
FROM (
     SELECT 'Volume Size' label, tsize, '34CF27' style, tsize || ' GB' mo FROM tvols
     UNION ALL
     SELECT 'Boot-Volume Size',  tsize, '9FFA9D', tsize || ' GB' FROM tbvols
     UNION ALL
     SELECT 'Volume Backup Size', tsize, '0252D7', tsize || ' GB' FROM tbkps
     UNION ALL
     SELECT 'Boot-Volume Backup Size', tsize, '1E96DD', tsize || ' GB' FROM tbbkps
     UNION ALL
     SELECT 'Object Storage Size', tsize, 'CFCF26', tsize || ' GB' FROM tbos
     )
}';
END;
/
DEF vaxis = 'Space Utilization (%)'
DEF haxis = 'Storage Type'
DEF bar_minperc = 0
DEF skip_bch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Utilization Tree Map'
DEF main_table = 'OCI360_INSTANCES'

BEGIN
  :sql_text := q'{
WITH t_reg  AS (SELECT /*+ materialize */ region_name, region_key from OCI360_REGIONS_SUBS),
     t_inst AS
        (SELECT /*+ materialize */
                id,
                display_name || ' - ' || 'I' || rank() over (order by display_name, id) display_name,
                compartment_id,
                -- For IAD and PHX, the key used in instance region column is actually the region key, while in other is the region name
                decode(region,'iad','us-ashburn-1','phx','us-phoenix-1',region) region
                FROM oci360_instances),
     t_comp AS (SELECT /*+ materialize */ id, name || ' - ' || 'C' || rank() over (order by name, id) name FROM oci360_compartments),
     t_vols AS
        (SELECT t1.id,
                t3.display_name || ' - ' || 'V' || rank() over (order by t3.display_name, t3.id) display_name,
                t3.size_in_gbs
         FROM   (SELECT /*+ materialize */ * FROM oci360_instances) t1,
                (SELECT /*+ materialize */ * FROM oci360_vol_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_volumes) t3
         WHERE  t1.id = t2.instance_id
         AND    t2.volume_id = t3.id
         AND    t2.lifecycle_state = 'ATTACHED'),
     t_bvols AS
        (SELECT t1.id,
                t3.display_name || ' - ' || 'B' || rank() over (order by t3.display_name, t3.id) display_name,
                t3.size_in_gbs
         FROM   (SELECT /*+ materialize */ * FROM oci360_instances) t1,
                (SELECT /*+ materialize */ * FROM oci360_bv_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_bvolumes) t3
         WHERE  t1.id = t2.instance_id
         AND    t2.boot_volume_id = t3.id
         AND    t2.lifecycle_state = 'ATTACHED'),
     t_bvols_bkp AS
        (SELECT t1.id,
                t4.display_name || ' - ' || 'D' || rank() over (order by t4.display_name, t4.id) display_name,
                t4.unique_size_in_gbs size_in_gbs
         FROM   (SELECT /*+ materialize */ * FROM oci360_instances) t1,
                (SELECT /*+ materialize */ * FROM oci360_bv_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_bvolumes) t3,
                (SELECT /*+ materialize */ * FROM oci360_bv_backups) t4
         WHERE  t1.id = t2.instance_id
         AND    t2.boot_volume_id = t3.id
         AND    t2.lifecycle_state = 'ATTACHED'
         AND    t3.id = t4.boot_volume_id
         AND    t4.lifecycle_state = 'AVAILABLE'),
     t_vols_bkp AS
        (SELECT t1.id,
                t4.display_name || ' - ' || 'E' || rank() over (order by t4.display_name, t4.id) display_name,
                t4.unique_size_in_gbs size_in_gbs
         FROM   (SELECT /*+ materialize */ * FROM oci360_instances) t1,
                (SELECT /*+ materialize */ * FROM oci360_vol_attachs) t2,
                (SELECT /*+ materialize */ * FROM oci360_volumes) t3,
                (SELECT /*+ materialize */ * FROM oci360_backups) t4
         WHERE  t1.id = t2.instance_id
            AND t2.volume_id = t3.id
            AND t2.lifecycle_state = 'ATTACHED'
            AND t3.id = t4.volume_id
            AND t4.lifecycle_state = 'AVAILABLE')
SELECT 'All Regions' "Object", null "Parent", 0 "Value", 0 Color
FROM   dual
UNION
SELECT region_name, 'All Regions', 0, 0
FROM   t_reg
UNION
SELECT name || ' - ' || region_name, region_name, 0, 0
FROM   t_comp, t_reg
UNION
SELECT t2.display_name, t1.name || ' - ' || region, 0, 0
FROM   t_comp t1,
       t_inst t2
WHERE  t2.compartment_id = t1.id
UNION
SELECT t1.display_name, t2.display_name, t1.size_in_gbs, 0
FROM   t_vols t1,
       t_inst t2
WHERE  t2.id = t1.id
UNION
SELECT t1.display_name, t2.display_name, t1.size_in_gbs, 0
FROM   t_bvols t1,
       t_inst t2
WHERE  t2.id = t1.id
UNION
SELECT t1.display_name, t2.display_name, t1.size_in_gbs, 1
FROM   t_vols_bkp t1,
       t_inst t2
WHERE  t2.id = t1.id
UNION
SELECT t1.display_name, t2.display_name, t1.size_in_gbs, 1
FROM   t_bvols_bkp t1,
       t_inst t2
WHERE  t2.id = t1.id
}';
END;
/
DEF chart_option1 = "highlightOnMouseOver: false, maxDepth: 1, maxPostDepth: 0,"
DEF chart_option2 = "minHighlightColor: '#8c6bb1', midHighlightColor: '#8c6bb1', maxHighlightColor: '#8c6bb1',"
DEF chart_option3 = "minColor: '#99ccff', midColor: '#b38080', maxColor: '#cc3300',"
DEF chart_option4 = "headerHeight: 15, showScale: false, height: 500, useWeightedAverageForAggregation: true, generateTooltip: showFullTooltip"
--DEF chart_option1 = "highlightOnMouseOver: false, maxDepth: 1, maxPostDepth: 0,"
--DEF chart_option2 = "minHighlightColor: '#8c6bb1', midHighlightColor: '#8c6bb1', maxHighlightColor: '#8c6bb1',"
--DEF chart_option3 = "minColor: '#009688', midColor: '#009688', maxColor: '#009688',"
--DEF chart_option4 = "headerHeight: 15, showScale: false, height: 500, useWeightedAverageForAggregation: true, generateTooltip: showFullTooltip"
DEF tremap_popup = "'<br>Total Size (this cell and its children): ' + size + ' GB'"
DEF foot = 'Blue = Volumes and Boot Volumes. Red = Backups<br>';
DEF skip_treemap = ''
@@&&9a_pre_one.

-----------------------------------------