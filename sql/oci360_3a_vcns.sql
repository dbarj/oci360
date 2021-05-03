-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_VNICS'
@@&&fc_table_loader. 'OCI360_SUBNETS'
@@&&fc_table_loader. 'OCI360_COMPARTMENTS'
@@&&fc_table_loader. 'OCI360_VCNS'
@@&&fc_table_loader. 'OCI360_VNIC_ATTACHS'
@@&&fc_table_loader. 'OCI360_PRIVATEIPS'
@@&&fc_table_loader. 'OCI360_DHCP_OPTIONS'
@@&&fc_table_loader. 'OCI360_ROUTE_TABLES'
@@&&fc_table_loader. 'OCI360_INTERNET_GW'
@@&&fc_table_loader. 'OCI360_NAT_GATEWAYS'
@@&&fc_table_loader. 'OCI360_DRGS'
@@&&fc_table_loader. 'OCI360_DRG_ATTACHS'
@@&&fc_table_loader. 'OCI360_FC_PROV_SRVCS'
@@&&fc_table_loader. 'OCI360_LOCAL_PEERING'
@@&&fc_table_loader. 'OCI360_REMOTE_PEERING'
@@&&fc_table_loader. 'OCI360_NETSERVICES'
@@&&fc_table_loader. 'OCI360_NETSERVICE_GW'
@@&&fc_table_loader. 'OCI360_PUBLICIPS'
-----------------------------------------

DEF title = 'VNICs'
DEF main_table = 'OCI360_VNICS'

BEGIN
  :sql_text := q'{
SELECT tcomp.NAME COMPARTMENT_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tsub.DISPLAY_NAME SUBNET_NAME,
       tvnic.public_ip,
       tvnic.is_primary,
       tvnic.private_ip,
       tvnic.mac_address,
       tvnic.display_name,
       tvnic.time_created,
       tvnic.hostname_label,
       tvnic.lifecycle_state,
       tvnic.availability_domain,
       tvnic.skip_source_dest_check,
       tvnic.id
FROM   OCI360_VNICS tvnic,
       (select distinct id, vcn_id, display_name from OCI360_SUBNETS) tsub,
       OCI360_COMPARTMENTS tcomp,
       OCI360_VCNS tvcn
WHERE  substr(tvnic.id,instr(tvnic.id,'.',1,3)+1,instr(tvnic.id,'.',1,4)-instr(tvnic.id,'.',1,3)-1) = '&&oci360_current_region.'
AND    tvnic.COMPARTMENT_ID = tcomp.ID
AND    tvnic.SUBNET_ID = tsub.id
AND    tsub.VCN_ID = tvcn.ID
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'VNIC Attachments'
DEF main_table = 'OCI360_VNIC_ATTACHS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VNIC_ATTACHS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Subnets'
DEF main_table = 'OCI360_SUBNETS'

BEGIN
  :sql_text := q'{
SELECT distinct
       tcomp.NAME COMPARTMENT_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tsub.ID,
       tsub.VCN_ID,
       tsub.DNS_LABEL,
       tsub.CIDR_BLOCK,
       tsub.DISPLAY_NAME,
       tsub.TIME_CREATED,
       tsub.COMPARTMENT_ID,
       tsub.ROUTE_TABLE_ID,
       tsub.DHCP_OPTIONS_ID,
       tsub.LIFECYCLE_STATE,
       tsub.VIRTUAL_ROUTER_IP,
       tsub.SUBNET_DOMAIN_NAME,
       tsub.VIRTUAL_ROUTER_MAC,
       tsub.AVAILABILITY_DOMAIN,
       tsub.PROHIBIT_PUBLIC_IP_ON_VNIC
FROM   OCI360_SUBNETS tsub,
       OCI360_COMPARTMENTS tcomp,
       OCI360_VCNS tvcn
WHERE  substr(tsub.id,instr(tsub.id,'.',1,3)+1,instr(tsub.id,'.',1,4)-instr(tsub.id,'.',1,3)-1) = '&&oci360_current_region.'
AND    tsub.COMPARTMENT_ID = tcomp.ID
AND    tsub.VCN_ID = tvcn.ID
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Used IPs per Subnets'
DEF main_table = 'OCI360_SUBNETS'

BEGIN
  :sql_text := q'{
SELECT tsub.display_name,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       tsub.cidr_block,
       power(2,32-substr(tsub.cidr_block,instr(tsub.cidr_block,'/')+1))-3 TOTAL_AVAILABLE,
       count(tpip.id) TOTAL_USED,
       power(2,32-substr(tsub.cidr_block,instr(tsub.cidr_block,'/')+1))-3 - count(tpip.id) TOTAL_FREE,
       tsub.dns_label,
       tsub.subnet_domain_name,
       tsub.lifecycle_state,
       tsub.virtual_router_ip,
       tsub.availability_domain,
       tsub.prohibit_public_ip_on_vnic,
       tsub.id
FROM   (SELECT distinct id, compartment_id, vcn_id, display_name, cidr_block, dns_label, subnet_domain_name, lifecycle_state, virtual_router_ip, availability_domain, prohibit_public_ip_on_vnic FROM OCI360_SUBNETS) tsub,
       OCI360_PRIVATEIPS tpip,
       OCI360_COMPARTMENTS tcomp,
       OCI360_VCNS tvcn
WHERE  substr(tsub.id,instr(tsub.id,'.',1,3)+1,instr(tsub.id,'.',1,4)-instr(tsub.id,'.',1,3)-1) = '&&oci360_current_region.'
AND    tsub.compartment_id = tcomp.ID
AND    tsub.id = tpip.SUBNET_ID (+)
AND    tsub.VCN_ID = tvcn.ID
GROUP BY tsub.display_name,
         tsub.cidr_block,
         tsub.dns_label,
         tsub.subnet_domain_name,
         tsub.lifecycle_state,
         tsub.virtual_router_ip,
         tsub.availability_domain,
         tsub.prohibit_public_ip_on_vnic,
         tsub.id,
         tcomp.NAME,
         tvcn.DISPLAY_NAME
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'DHCP Options'
DEF main_table = 'OCI360_DHCP_OPTIONS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DHCP_OPTIONS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Route Tables'
DEF main_table = 'OCI360_ROUTE_TABLES'

BEGIN
  :sql_text := q'{
SELECT tr.DISPLAY_NAME ROUTE_TABLE_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       tr.TIME_CREATED,
       tr.LIFECYCLE_STATE,
       tr.ROUTE_RULES$CIDR_BLOCK,
       tr.ROUTE_RULES$DESTINATION,
       tr.ROUTE_RULES$DESTINATION_TYPE,
       tr.ROUTE_RULES$NETWORK_ENTITY_ID,
       tr.ID
FROM   OCI360_ROUTE_TABLES tr,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  tr.COMPARTMENT_ID = tcomp.ID
AND    substr(tr.id,instr(tr.id,'.',1,3)+1,instr(tr.id,'.',1,4)-instr(tr.id,'.',1,3)-1) = '&&oci360_current_region.'
AND    tr.VCN_ID = tvcn.ID
ORDER  BY COMPARTMENT_NAME, VCN_NAME, ROUTE_TABLE_NAME, TIME_CREATED
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Internet Gateways'
DEF main_table = 'OCI360_INTERNET_GW'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_INTERNET_GW t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'NAT Gateways'
DEF main_table = 'OCI360_NAT_GATEWAYS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_NAT_GATEWAYS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'DRGs'
DEF main_table = 'OCI360_DRGS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DRGS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'DRG Attachments'
DEF main_table = 'OCI360_DRG_ATTACHS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DRG_ATTACHS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Fast-Connect Provider Services'
DEF main_table = 'OCI360_FC_PROV_SRVCS'

BEGIN
  :sql_text := q'{
SELECT ID,
       TYPE,
       DESCRIPTION,
       PROVIDER_NAME,
       PROVIDER_SERVICE_NAME,
       PUBLIC_PEERING_BGP_MANAGEMENT,
       PRIVATE_PEERING_BGP_MANAGEMENT,
       listagg(SUPPORTED_VIRTUAL_CIRCUIT_TYPES,', ') within group(order by SUPPORTED_VIRTUAL_CIRCUIT_TYPES) SUPPORTED_VIRTUAL_CIRCUIT_TYPES
FROM   OCI360_FC_PROV_SRVCS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
GROUP BY
       ID,
       TYPE,
       DESCRIPTION,
       PROVIDER_NAME,
       PROVIDER_SERVICE_NAME,
       PUBLIC_PEERING_BGP_MANAGEMENT,
       PRIVATE_PEERING_BGP_MANAGEMENT
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Local Peering Gateways'
DEF main_table = 'OCI360_LOCAL_PEERING'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LOCAL_PEERING t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Remote Peering Connections'
DEF main_table = 'OCI360_REMOTE_PEERING'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REMOTE_PEERING t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Network Services'
DEF main_table = 'OCI360_NETSERVICES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_NETSERVICES t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Network Service Gateways'
DEF main_table = 'OCI360_NETSERVICE_GW'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_NETSERVICE_GW t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'VCNs'
DEF main_table = 'OCI360_VCNS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VCNS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Private IPs'
DEF main_table = 'OCI360_PRIVATEIPS'

BEGIN
  :sql_text := q'{
SELECT tcomp.NAME COMPARTMENT_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tsub.DISPLAY_NAME SUBNET_NAME,
       tpip.IP_ADDRESS,
       tpip.IS_PRIMARY,
       tpip.DISPLAY_NAME,
       tpip.TIME_CREATED,
       tpip.HOSTNAME_LABEL,
       tpip.AVAILABILITY_DOMAIN,
       tpip.VNIC_ID,
       tpip.ID
FROM   OCI360_PRIVATEIPS tpip,
       (select distinct id, vcn_id, display_name from OCI360_SUBNETS) tsub,
       OCI360_COMPARTMENTS tcomp,
       OCI360_VCNS tvcn
WHERE  substr(tpip.id,instr(tpip.id,'.',1,3)+1,instr(tpip.id,'.',1,4)-instr(tpip.id,'.',1,3)-1) = '&&oci360_current_region.'
AND    tpip.COMPARTMENT_ID = tcomp.ID
AND    tpip.SUBNET_ID = tsub.id
AND    tsub.VCN_ID = tvcn.ID
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Public IPs'
DEF main_table = 'OCI360_PUBLICIPS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PUBLICIPS t1
WHERE  substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'VCN Map'
DEF main_table = 'OCI360_VCNS'

BEGIN
  :sql_text := q'[
  WITH t_regs  AS (SELECT /*+ materialize */
                         region_name,
                         lower(region_key) region_key
                   from  OCI360_REGIONS_SUBS
                   where lower(region_key)='&&oci360_current_region.'),
       t_vcns  AS (SELECT /*+ materialize */
                         id,
                         display_name || ' - ' || CIDR_BLOCK display_name,
                         substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) region_key
                   FROM  OCI360_VCNS
                   where substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'),
       t_subs  AS (SELECT /*+ materialize */ distinct
                         id,
                         display_name || ' - ' || CIDR_BLOCK display_name,
                         vcn_id
                   FROM  OCI360_SUBNETS
                   where substr(id,instr(id,'.',1,3)+1,instr(id,'.',1,4)-instr(id,'.',1,3)-1) = '&&oci360_current_region.'),
       t_insts AS (SELECT t1.id,
                          t3.id subnet_id,
                          t1.display_name,
                          substr(t1.shape,instr(t1.shape,'.',-1)+1) value
                   FROM  OCI360_INSTANCES t1, OCI360_VNIC_ATTACHS t2, t_subs t3
                   WHERE t1.id = t2.instance_id
                   AND   t2.subnet_id = t3.id)
  SELECT region_key "ID", null "PARENT_ID", region_name "DISPLAY_NAME", 0 "VALUE"
  FROM   t_regs
  UNION ALL
  SELECT id, region_key, display_name, 1
  FROM   t_vcns
  UNION ALL
  SELECT id, vcn_id, display_name, 2
  FROM   t_subs
  UNION ALL
  SELECT id, subnet_id, display_name, 3*to_number(value)
  FROM   t_insts
  ]';
END;
/
DEF d3_graph='circle_packing'
@@&&9a_pre_one.

-----------------------------------------