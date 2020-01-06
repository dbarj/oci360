-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_VCNS'
@@&&fc_json_loader. 'OCI360_REGIONS_SUBS'
-----------------------------------------

@@&&fc_def_output_file. oci360_sub_sections 'oci360_sub_sections.sql'

-- Check if query can run. If the query fails, all will be skipped.
DEF oci360_skip_sub_sections = '&&fc_skip_script.'
COL oci360_skip_sub_sections NEW_V oci360_skip_sub_sections
SELECT substr(region_key || region_name,0,0) oci360_skip_sub_sections
FROM   ( SELECT   DISTINCT lower(t2.region_key) region_key,
                  t2.region_name
         FROM     OCI360_VCNS t1,
                  -- For IAD and PHX, the key used in objects OCID is actually the region key, while in other is the region name
                  (select decode(region_key,'IAD',region_key,'PHX',region_key,region_name) region_key, region_name from OCI360_REGIONS_SUBS) t2
         WHERE    substr(t1.id,instr(t1.id,'.',1,3)+1,instr(t1.id,'.',1,4)-instr(t1.id,'.',1,3)-1) = lower(t2.region_key)
         ORDER BY region_key);
COL oci360_skip_sub_sections CLEAR

-- BEGIN - Call sub-section for each region.
@@&&fc_spool_start.
SPO &&oci360_sub_sections.
SELECT 'DEF oci360_current_region = ''' || region_key || '''' || CHR(10) ||
       '@@&&fc_call_secion_sub. ''&&moat369_sec_id..'|| rownum || ''' ''&&moat369_sw_name._&&moat369_sec_id._seclists.sql'' ''' || region_name || ''''
FROM   ( SELECT   DISTINCT lower(t2.region_key) region_key,
                  t2.region_name
         FROM     OCI360_VCNS t1,
                  -- For IAD and PHX, the key used in objects OCID is actually the region key, while in other is the region name
                  (select decode(region_key,'IAD',region_key,'PHX',region_key,region_name) region_key, region_name from OCI360_REGIONS_SUBS) t2
         WHERE    substr(t1.id,instr(t1.id,'.',1,3)+1,instr(t1.id,'.',1,4)-instr(t1.id,'.',1,3)-1) = lower(t2.region_key)
         ORDER BY region_key);
SPO OFF
@@&&fc_spool_end.
@@&&oci360_skip_sub_sections.&&oci360_sub_sections.
-- END - Call sub-section for each region.

@@&&fc_zip_driver_files. &&oci360_sub_sections.

UNDEF oci360_sub_sections
UNDEF oci360_current_region
UNDEF oci360_skip_sub_sections
-----------------------------------------