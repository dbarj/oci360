-- webvowl configuration for OCI360 - Rodrigo Jorge

DEF oci360_webvowl_zip   = '&&moat369_sw_base./&&moat369_sw_misc_fdr./webvowl_1.1.7.zip'

DEF oci360_webvowl_fdr  = 'webvowl'
DEF oci360_webvowl_data = 'data'

@@&&fc_def_output_file. oci360_webvowl_json      'oci360.json'
@@&&fc_def_output_file. oci360_webvowl_qry       'webvowl_qry.sql'
@@&&fc_def_output_file. oci360_webvowl_fdr_path  '&&oci360_webvowl_fdr.'
@@&&fc_def_output_file. oci360_webvowl_data_path '&&oci360_webvowl_data.'

HOS mkdir &&oci360_webvowl_fdr_path.
HOS unzip -d &&oci360_webvowl_fdr_path. &&oci360_webvowl_zip. >> &&moat369_log3.

HOS &&cmd_awk. '{sub(/foaf/,"oci360")}1' &&oci360_webvowl_fdr_path./js/webvowl.app.js > &&oci360_webvowl_fdr_path./js/webvowl.app.js.new
HOS mv &&oci360_webvowl_fdr_path./js/webvowl.app.js.new &&oci360_webvowl_fdr_path./js/webvowl.app.js

HOS cd &&oci360_webvowl_fdr_path./../; zip -rm &&moat369_zip_filename. &&oci360_webvowl_fdr./css/        >> &&moat369_log3.
HOS cd &&oci360_webvowl_fdr_path./../; zip -rm &&moat369_zip_filename. &&oci360_webvowl_fdr./js/         >> &&moat369_log3.
HOS cd &&oci360_webvowl_fdr_path./../; zip -m  &&moat369_zip_filename. &&oci360_webvowl_fdr./favicon.ico >> &&moat369_log3.
HOS cd &&oci360_webvowl_fdr_path./../; zip -m  &&moat369_zip_filename. &&oci360_webvowl_fdr./license.txt >> &&moat369_log3.

HOS rm -rf &&oci360_webvowl_fdr_path.

BEGIN
  -- sql_with_clause MUST NOT HAVE AN EMPTY LINE IN THE BEGGINING OR END. Will make GET function to FAIL.
  :sql_with_clause := q'[ WITH
t_ids AS (
SELECT /*+ materialize */ id,
       to_char(rank() over (order by id asc)) owl_id
FROM  (select id from OCI360_INSTANCES union
       select distinct id from OCI360_SUBNETS union
       select distinct 'z_link_' || id from OCI360_SUBNETS union
       select id from OCI360_VCNS union
       select id from OCI360_PRIVATEIPS union
       select id from OCI360_REMOTE_PEERING union
       select id from OCI360_LOCAL_PEERING union
       select id from OCI360_PUBLICIPS union
       select 'z_link_' || id from OCI360_PUBLICIPS)),
t_insts_subs AS (
SELECT t4.id,
       t4.ip_address display_name,
       'owl:ObjectProperty' owl_type,
       t2.subnet_id,
       t2.instance_id
FROM  OCI360_INSTANCES t1, OCI360_VNIC_ATTACHS t2, OCI360_VNICS t3, OCI360_PRIVATEIPS t4
WHERE t1.id = t2.instance_id (+)
AND   t2.lifecycle_state (+) = 'ATTACHED'
AND   t2.vnic_id = t3.id (+)
AND   t3.lifecycle_state (+) = 'AVAILABLE'
AND   t2.vnic_id = t4.vnic_id (+)),
t_subs_vcns AS (
SELECT distinct
       'z_link_' || t1.id id,
       t1.cidr_block display_name,
       'owl:ObjectProperty' owl_type,
       t1.id subnet_id,
       t1.vcn_id
FROM  OCI360_SUBNETS t1
WHERE exists (select 1 from t_insts_subs where t1.id=t_insts_subs.subnet_id)),
t_vcns_vcns_rmt AS (
SELECT t3.id,
       t1.cidr_block display_name,
       'owl:ObjectProperty' owl_type,
       t1.id vcn_1_id,
       t6.id vcn_2_id
FROM   OCI360_VCNS t1,
       OCI360_DRG_ATTACHS t2,
       OCI360_REMOTE_PEERING t3,
       OCI360_REMOTE_PEERING t4,
       OCI360_DRG_ATTACHS t5,
       OCI360_VCNS t6
WHERE  t1.id=t2.vcn_id
and    t2.drg_id=t3.drg_id
and    t3.peer_id=t4.id
and    t4.drg_id=t5.drg_id
and    t5.vcn_id=t6.id
and    t1.LIFECYCLE_STATE='AVAILABLE'
and    t2.LIFECYCLE_STATE='ATTACHED' 
and    t3.PEERING_STATUS='PEERED'
and    t3.LIFECYCLE_STATE='AVAILABLE'
and    t4.PEERING_STATUS='PEERED'
and    t4.LIFECYCLE_STATE='AVAILABLE'
and    t5.LIFECYCLE_STATE='ATTACHED' 
and    t6.LIFECYCLE_STATE='AVAILABLE' ),
t_vcns_vcns_loc AS (
SELECT id, display_name, owl_type, vcn_1_id, vcn_2_id, total FROM (
SELECT t2.id,
       t1.cidr_block display_name,
       'owl:ObjectProperty' owl_type,
       t1.id vcn_1_id,
       t3.id vcn_2_id,
       count(1) over (partition by t1.id,t2.id) total
FROM   OCI360_VCNS t1,
       OCI360_LOCAL_PEERING t2,
       OCI360_VCNS t3,
       OCI360_LOCAL_PEERING t4
WHERE  t1.id = t2.vcn_id
AND    t1.lifecycle_state='AVAILABLE'
AND    t2.peering_status = 'PEERED'
AND    t2.is_cross_tenancy_peering = 'false'
AND    t2.peer_advertised_cidr = t3.cidr_block
--
AND    t3.id = t4.vcn_id
AND    t3.lifecycle_state='AVAILABLE'
AND    t4.peering_status = 'PEERED'
AND    t4.is_cross_tenancy_peering = 'false'
AND    t4.peer_advertised_cidr = t1.cidr_block
) WHERE total=1 -- As joins are not using IDs, but CIDR, this is introduced to avoid false positives
),
t_insts_pubips AS (
SELECT 'z_link_' || t4.id id,
       initcap(t4.lifetime) display_name,
       'owl:DatatypeProperty' owl_type,
       t2.instance_id,
       t4.id pubip_id
FROM   OCI360_INSTANCES t1,
       OCI360_VNIC_ATTACHS t2,
       OCI360_VNICS t3,
       OCI360_PUBLICIPS t4
WHERE  t1.id = t2.instance_id
AND    t2.lifecycle_state = 'ATTACHED'
AND    t2.vnic_id = t3.id
AND    t3.lifecycle_state = 'AVAILABLE'
and    t3.public_ip = t4.ip_address
and    t4.lifecycle_state='ASSIGNED'
),
t_insts AS (
SELECT t1.id,
       t1.display_name,
       'rdfs:Class' owl_type
FROM   OCI360_INSTANCES t1
WHERE  t1.lifecycle_state != 'TERMINATED'),
t_subs AS (
SELECT distinct
       t1.id,
       t1.display_name,
       'owl:Class' owl_type
FROM  OCI360_SUBNETS t1
WHERE exists (select 1 from t_insts_subs where t1.id=t_insts_subs.subnet_id)),
t_vcns AS (
SELECT t1.id,
       t1.display_name,
       'owl:Thing' owl_type
FROM  OCI360_VCNS t1
WHERE exists (select 1 from t_subs_vcns where t1.id=t_subs_vcns.vcn_id)),
t_pubips AS (
SELECT t1.id,
       t1.ip_address display_name,
       'rdfs:Datatype' owl_type
FROM  OCI360_PUBLICIPS t1
WHERE exists (select 1 from t_insts_pubips where t1.id=t_insts_pubips.pubip_id)) ]';
END;
/

@@&&fc_spool_start.
SPO &&oci360_webvowl_json.
PRO {
PRO   "_comment" : "Created with OCI360",
PRO   "header" : {
PRO     "languages" : [ "english" ],
PRO     "baseIris": [
PRO       "http://schema.org",
PRO       "http://www.w3.org/2000/01/rdf-schema",
PRO       "http://www.w3.org/2003/01/geo/wgs84_pos",
PRO       "http://purl.org/dc/terms",
PRO       "http://www.w3.org/2001/XMLSchema",
PRO       "http://xmlns.com/foaf/0.1",
PRO       "http://www.w3.org/2000/10/swap/pim/contact",
PRO       "http://www.w3.org/2004/02/skos/core"
PRO     ],
PRO     "title" : {
PRO       "undefined" : "OCI360 Infrastructure View"
PRO     },
PRO     "iri" : "https://docs.cloud.oracle.com/",
PRO     "description" : {
PRO       "undefined" : "Infrastructure Network configuration in OCI."
PRO     },
PRO     "version": "1.0",
PRO     "author": "Rodrigo Jorge"
PRO   },
PRO   "settings": {
PRO     "modes": {
PRO       "checkBox": [
PRO         {
PRO           "id": "pickandpinModuleCheckbox",
PRO           "checked": true
PRO         }
PRO       ]
PRO     },
PRO     "filter": {
PRO       "degreeSliderValue": "0"
PRO     }
PRO   },
PRO   "namespace" : [ ],
PRO   "class" : [
SPO OFF
@@&&fc_spool_end.

BEGIN
  :sql_text := :sql_with_clause || q'[
SELECT json_object(
  'id' VALUE owl_id,
  'type' VALUE owl_type) || decode(rownum,count(1) over (),'',',') text
FROM   (select owl_id, owl_type from t_insts inner join t_ids using (id)
        union
        select owl_id, owl_type from t_subs inner join t_ids using (id)
        union
        select owl_id, owl_type from t_vcns inner join t_ids using (id)
        union
        select owl_id, owl_type from t_pubips inner join t_ids using (id))
]';
END;
/

@@&&fc_spool_start.
SPO &&oci360_webvowl_qry.
SELECT :sql_text FROM DUAL;
SPO OFF

GET &&oci360_webvowl_qry.

SPO &&oci360_webvowl_json. APP
/
PRO   ],
PRO   "classAttribute" : [
SPO OFF
@@&&fc_spool_end.

@@&&fc_zip_driver_files. &&oci360_webvowl_qry.

BEGIN
  :sql_text := :sql_with_clause || q'[
SELECT json_object(
--  'iri'         VALUE 'http://xmlns.com/foaf/0.1/OnlineAccount' || owl_id,
--  'baseIri'     VALUE 'http://xmlns.com/foaf/0.1',
--  'instances'   VALUE 0,
--  'annotations' VALUE json_object(
--    'isDefinedBy'  VALUE json_array(json_object(
--      'identifier'   VALUE 'isDefinedBy',
--      'language'     VALUE 'undefined',
--      'value'        VALUE 'http://xmlns.com/foaf/0.1/',
--      'type'         VALUE 'iri')),
--    'term_status'  VALUE json_array(json_object(
--      'identifier'   VALUE 'term_status',
--      'language'     VALUE 'undefined',
--      'value'        VALUE 'stable',
--      'type'         VALUE 'label'))),
  'label'       VALUE json_object(
--    'IRI-based'    VALUE 'OnlineAccount'  || owl_id,
    'undefined'    VALUE display_name),
--  'subClasses'  VALUE NULL,
  'comment'     VALUE json_object(
    'undefined'    VALUE id),
  'id'          VALUE owl_id
  ABSENT ON NULL) || decode(rownum,count(1) over (),'',',') text
FROM   (select id, display_name, owl_id from t_insts inner join t_ids using (id)
        union
        select id, display_name, owl_id from t_subs inner join t_ids using (id)
        union
        select id, display_name, owl_id from t_vcns inner join t_ids using (id)
        union
        select id, display_name, owl_id from t_pubips inner join t_ids using (id))
]';
END;
/

@@&&fc_spool_start.
SPO &&oci360_webvowl_qry.
SELECT :sql_text FROM DUAL;
SPO OFF

GET &&oci360_webvowl_qry.

SPO &&oci360_webvowl_json. APP
/
PRO   ],
PRO   "property" : [
SPO OFF
@@&&fc_spool_end.

@@&&fc_zip_driver_files. &&oci360_webvowl_qry.

BEGIN
  :sql_text := :sql_with_clause || q'[
SELECT json_object(
  'id' VALUE owl_id,
  'type' VALUE owl_type) || decode(rownum,count(1) over (),'',',') text
FROM   (select owl_id, owl_type from t_insts_subs    inner join t_ids using (id) union
        select owl_id, owl_type from t_subs_vcns     inner join t_ids using (id) union
        select owl_id, owl_type from t_vcns_vcns_rmt inner join t_ids using (id) union
        select owl_id, owl_type from t_vcns_vcns_loc inner join t_ids using (id) union
        select owl_id, owl_type from t_insts_pubips  inner join t_ids using (id))
]';
END;
/

@@&&fc_spool_start.
SPO &&oci360_webvowl_qry.
SELECT :sql_text FROM DUAL;
SPO OFF

GET &&oci360_webvowl_qry.

SPO &&oci360_webvowl_json. APP
/
PRO   ],
PRO   "propertyAttribute" : [
SPO OFF
@@&&fc_spool_end.

@@&&fc_zip_driver_files. &&oci360_webvowl_qry.

BEGIN
  :sql_text := :sql_with_clause || q'[
SELECT json_object(
  'id'          VALUE owl_id,
  'domain'      VALUE owl_domain,
  'range'       VALUE owl_range,
--  'baseIri'     VALUE 'http://xmlns.com/foaf/0.1',
  'label'       VALUE owl_label,
  'inverse'     VALUE owl_inverse_id,
--  'attributes'  VALUE json_array('object'),
  'comment'     VALUE json_object(
    'undefined'    VALUE id)
  ABSENT ON NULL) || decode(rownum,count(1) over (),'',',') text
FROM (
SELECT t2.id, t2.owl_id, torig.owl_id owl_domain, tdest.owl_id owl_range, t1.display_name owl_label, null owl_inverse_id
FROM   t_insts_subs t1,
       t_ids t2,
       t_ids torig,
       t_ids tdest
WHERE  t1.id = t2.id
AND    t1.subnet_id = torig.id
AND    t1.instance_id = tdest.id
union
SELECT null id, t2.owl_id, torig.owl_id owl_domain, tdest.owl_id owl_range, t1.display_name owl_label, null owl_inverse_id
FROM   t_subs_vcns t1,
       t_ids t2,
       t_ids torig,
       t_ids tdest
WHERE  t1.id = t2.id
AND    t1.vcn_id = torig.id
AND    t1.subnet_id = tdest.id
union
SELECT t2.id, t2.owl_id, torig.owl_id owl_domain, tdest.owl_id owl_range, t1.display_name owl_label, t4.owl_id owl_inverse_id
FROM   t_vcns_vcns_rmt t1,
       t_ids t2,
       t_ids torig,
       t_ids tdest,
       t_vcns_vcns_rmt t3,
       t_ids t4
WHERE  t1.id = t2.id
AND    t1.vcn_1_id = torig.id
AND    t1.vcn_2_id = tdest.id
AND    t1.vcn_1_id = t3.vcn_2_id (+)
AND    t1.vcn_2_id = t3.vcn_1_id (+)
AND    t3.id = t4.id (+)
union
SELECT t2.id, t2.owl_id, torig.owl_id owl_domain, tdest.owl_id owl_range, t1.display_name owl_label, t4.owl_id owl_inverse_id
FROM   t_vcns_vcns_loc t1,
       t_ids t2,
       t_ids torig,
       t_ids tdest,
       t_vcns_vcns_loc t3,
       t_ids t4
WHERE  t1.id = t2.id
AND    t1.vcn_1_id = torig.id
AND    t1.vcn_2_id = tdest.id
AND    t1.vcn_1_id = t3.vcn_2_id (+)
AND    t1.vcn_2_id = t3.vcn_1_id (+)
AND    t3.id = t4.id (+)
union
SELECT null id, t2.owl_id, torig.owl_id owl_domain, tdest.owl_id owl_range, t1.display_name owl_label, null owl_inverse_id
FROM   t_insts_pubips t1,
       t_ids t2,
       t_ids torig,
       t_ids tdest
WHERE  t1.id = t2.id
AND    t1.instance_id = torig.id
AND    t1.pubip_id = tdest.id )
]';
END;
/

@@&&fc_spool_start.
SPO &&oci360_webvowl_qry.
SELECT :sql_text FROM DUAL;
SPO OFF

GET &&oci360_webvowl_qry.

SPO &&oci360_webvowl_json. APP
/
PRO   ] }
SPO OFF
@@&&fc_spool_end.

@@&&fc_zip_driver_files. &&oci360_webvowl_qry.

HOS mkdir &&oci360_webvowl_data_path.
HOS mv &&oci360_webvowl_json. &&oci360_webvowl_data_path.

HOS cd &&oci360_webvowl_data_path./../; zip -rm &&moat369_zip_filename. &&oci360_webvowl_data. >> &&moat369_log3.

EXEC :sql_with_clause := '';
EXEC :sql_text := '';
--
