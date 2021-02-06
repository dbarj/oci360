-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_SECLISTS'
@@&&fc_table_loader. 'OCI360_VCNS'
@@&&fc_table_loader. 'OCI360_COMPARTMENTS'
@@&&fc_table_loader. 'OCI360_SUBNETS'
@@&&fc_table_loader. 'OCI360_VNICS'
@@&&fc_table_loader. 'OCI360_PRIVATEIPS'
-----------------------------------------

DEF title = 'Security Lists per Subnet'
DEF main_table = 'OCI360_SECLISTS'

BEGIN
  :sql_text := q'{
SELECT distinct
       tsub.DISPLAY_NAME SUBNET_NAME,
       ts.DISPLAY_NAME SECLIST_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.ID SECLIST_ID,
       tsub.ID SUBNET_ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp,
       OCI360_SUBNETS tsub
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    tsub.security_list_ids LIKE '%' || ts.ID || '%'
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
ORDER BY COMPARTMENT_NAME, VCN_NAME, SUBNET_NAME, SECLIST_NAME
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Security Lists - Ingress'
DEF main_table = 'OCI360_SECLISTS'

BEGIN
  :sql_text := q'{
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts."INGRESS_SECURITY_RULES$SOURCE"                                  SOURCE,
       ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"                             SOURCE_TYPE,
       ts."INGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
       ts."INGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" is not null
AND    ts."INGRESS_SECURITY_RULES$PROTOCOL"!='17'
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
UNION ALL
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts."INGRESS_SECURITY_RULES$SOURCE"                                  SOURCE,
       ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"                             SOURCE_TYPE,
       ts."INGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
       ts."INGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" is not null
AND    ts."INGRESS_SECURITY_RULES$PROTOCOL"='17'
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
ORDER  BY COMPARTMENT_NAME,VCN_NAME,DISPLAY_NAME,LIFECYCLE_STATE,PROTOCOL
}';
END;
/

VAR sql_text_secl_ingress CLOB;
-- Error when use :sql_text_secl_ingress := :sql_text;
EXEC :sql_text_secl_ingress := TRIM(CHR(10) FROM :sql_text);
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Security Lists - Egress'
DEF main_table = 'OCI360_SECLISTS'

BEGIN
  :sql_text := q'{
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts."EGRESS_SECURITY_RULES$DESTINATION"                             DESTINATION,
       ts."EGRESS_SECURITY_RULES$DESTINATION_TYPE"                        DESTINATION_TYPE,
       ts."EGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
       ts."EGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
       ts."EGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
       ts."EGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
       ts."EGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
       ts."EGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
       ts."EGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
       ts."EGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."EGRESS_SECURITY_RULES$DESTINATION_TYPE" is not null
AND    ts."EGRESS_SECURITY_RULES$PROTOCOL"!='17'
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
UNION ALL
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts."EGRESS_SECURITY_RULES$DESTINATION"                             DESTINATION,
       ts."EGRESS_SECURITY_RULES$DESTINATION_TYPE"                        DESTINATION_TYPE,
       ts."EGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
       ts."EGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
       ts."EGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
       ts."EGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
       ts."EGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
       ts."EGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
       ts."EGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
       ts."EGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."EGRESS_SECURITY_RULES$DESTINATION_TYPE" is not null
AND    ts."EGRESS_SECURITY_RULES$PROTOCOL"='17'
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
ORDER  BY COMPARTMENT_NAME,VCN_NAME,DISPLAY_NAME,LIFECYCLE_STATE,PROTOCOL
}';
END;
/

@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Security Lists - Empty'
DEF main_table = 'OCI360_SECLISTS'

BEGIN
  :sql_text := q'{
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"     is null
AND    ts."EGRESS_SECURITY_RULES$DESTINATION_TYPE" is null
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
ORDER  BY ts.DISPLAY_NAME,ts.LIFECYCLE_STATE
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Subnet Internal Reachability per VNIC'
DEF main_table = 'OCI360_SECLISTS'

BEGIN
  :sql_with_clause := q'{
WITH
    -- Functions by Rodrigo Jorge - www.dbarj.com.br
    -- Convert IP to Decimal
    FUNCTION ip_to_dec (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_oct1 NUMBER(3);
        v_oct2 NUMBER(3);
        v_oct3 NUMBER(3);
        v_oct4 NUMBER(3);
    BEGIN
        v_oct1 := SUBSTR(v_in,1,instr(v_in,'.',1,1)-1);
        v_oct2 := SUBSTR(v_in,instr(v_in,'.',1,1)+1,instr(v_in,'.',1,2)-instr(v_in,'.',1,1)-1);
        v_oct3 := SUBSTR(v_in,instr(v_in,'.',1,2)+1,instr(v_in,'.',1,3)-instr(v_in,'.',1,2)-1);
        v_oct4 := SUBSTR(v_in,instr(v_in,'.',1,3)+1);
        RETURN v_oct1*power(256,3)+v_oct2*power(256,2)+v_oct3*power(256,1)+v_oct4*power(256,0);
    END;
    -- Convert Decimal to IP
    FUNCTION dec_to_ip (v_in NUMBER) RETURN VARCHAR2 DETERMINISTIC IS
        v_oct1 NUMBER(3);
        v_oct2 NUMBER;
        v_oct3 NUMBER;
        v_oct4 NUMBER(3);
    BEGIN
        v_oct4 := trunc(mod(v_in,power(256,1))/power(256,0));
        v_oct3 := trunc(mod(v_in,power(256,2))/power(256,1));
        v_oct2 := trunc(mod(v_in,power(256,3))/power(256,2));
        v_oct1 := trunc(mod(v_in,power(256,4))/power(256,3));
        RETURN v_oct1 || '.' || v_oct2 || '.' || v_oct3 || '.' || v_oct4;
    END;
    -- Bit Or Function
    FUNCTION bitor(x NUMBER, y NUMBER) RETURN NUMBER DETERMINISTIC
    IS
    BEGIN
        RETURN x + y - bitand(x, y);
    END;
    -- Get Min IP decimal for CIDR
    FUNCTION cidr_dec_min (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_ip_num NUMBER;
        v_mask_num NUMBER;
        v_mask NUMBER(2);
    BEGIN
        v_ip_num := ip_to_dec(SUBSTR(v_in,1,instr(v_in,'/',1,1)-1));
        v_mask := SUBSTR(v_in,instr(v_in,'/',1,1)+1);
        v_mask_num := POWER(2,32) - POWER(2,32 - v_mask);
        RETURN BITAND(v_ip_num,v_mask_num);
    END;
    -- Get Max IP decimal for CIDR
    FUNCTION cidr_dec_max (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_ip_num NUMBER;
        v_mask_num NUMBER;
        v_mask NUMBER(2);
    BEGIN
        v_ip_num := ip_to_dec(SUBSTR(v_in,1,instr(v_in,'/',1,1)-1));
        v_mask := SUBSTR(v_in,instr(v_in,'/',1,1)+1);
        v_mask_num := POWER(2,32 - v_mask)-1;
        RETURN BITOR(v_ip_num,v_mask_num);
    END;
}';

  :sql_text := q'{
SELECT ts.COMPARTMENT_NAME,
       ts.VCN_NAME,
       tsubsrc.DISPLAY_NAME VNIC_SUBNET_NAME,
       tvnic.display_name VNIC_NAME,
       tvnic.private_ip,
       tvnic.public_ip,
       tvnic.is_primary,
       tvnic.lifecycle_state vnic_lifecycle_state,
       tvnic.availability_domain,
       tvnic.id vnic_id,
       tsubtrg.DISPLAY_NAME TARGET_SUBNET_NAME,
       ts.DISPLAY_NAME SECLIST_NAME,
       ts.LIFECYCLE_STATE,
       ts.SOURCE,
       ts.PROTOCOL,
       ts.SOURCE_PORT_RANGE_MIN,
       ts.SOURCE_PORT_RANGE_MAX,
       ts.DESTINATION_PORT_RANGE_MIN,
       ts.DESTINATION_PORT_RANGE_MAX,
       ts.ICMP_CODE,
       ts.ICMP_TYPE,
       ts.IS_STATELESS,
       ts.ID
FROM   OCI360_VNICS tvnic,
       OCI360_PRIVATEIPS tpips,
       (}' || REGEXP_REPLACE(:sql_text_secl_ingress,CHR(10),CHR(10) || '       ') || q'{) ts,
       (SELECT distinct id, vcn_id, display_name from OCI360_SUBNETS) tsubsrc,
       (SELECT distinct security_list_ids, vcn_id, display_name from OCI360_SUBNETS) tsubtrg
WHERE  tvnic.SUBNET_ID = tsubsrc.id
AND    tvnic.id = tpips.vnic_id
AND    tsubsrc.VCN_ID = tsubtrg.VCN_ID
AND    tsubtrg.security_list_ids LIKE '%' || ts.ID || '%'
AND    substr(tvnic.id,instr(tvnic.id,'.',1,3)+1,instr(tvnic.id,'.',1,4)-instr(tvnic.id,'.',1,3)-1) = '&&oci360_current_region.'
AND    ts.SOURCE_TYPE = 'CIDR_BLOCK'
AND    ip_to_dec(tpips.ip_address) between cidr_dec_min(ts.SOURCE) and cidr_dec_max(ts.SOURCE)
ORDER BY COMPARTMENT_NAME, VCN_NAME, VNIC_SUBNET_NAME, VNIC_NAME, TARGET_SUBNET_NAME
}';
END;
/

DEF max_rows='5e4'
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Obsolete Security Ingress Rules'
DEF main_table = 'OCI360_SECLISTS'

BEGIN

  :sql_with_clause := q'{
WITH
    -- Functions by Rodrigo Jorge - www.dbarj.com.br
    -- Convert IP to Decimal
    FUNCTION ip_to_dec (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_oct1 NUMBER(3);
        v_oct2 NUMBER(3);
        v_oct3 NUMBER(3);
        v_oct4 NUMBER(3);
    BEGIN
        v_oct1 := SUBSTR(v_in,1,instr(v_in,'.',1,1)-1);
        v_oct2 := SUBSTR(v_in,instr(v_in,'.',1,1)+1,instr(v_in,'.',1,2)-instr(v_in,'.',1,1)-1);
        v_oct3 := SUBSTR(v_in,instr(v_in,'.',1,2)+1,instr(v_in,'.',1,3)-instr(v_in,'.',1,2)-1);
        v_oct4 := SUBSTR(v_in,instr(v_in,'.',1,3)+1);
        RETURN v_oct1*power(256,3)+v_oct2*power(256,2)+v_oct3*power(256,1)+v_oct4*power(256,0);
    END;
    -- Convert Decimal to IP
    FUNCTION dec_to_ip (v_in NUMBER) RETURN VARCHAR2 DETERMINISTIC IS
        v_oct1 NUMBER(3);
        v_oct2 NUMBER;
        v_oct3 NUMBER;
        v_oct4 NUMBER(3);
    BEGIN
        v_oct4 := trunc(mod(v_in,power(256,1))/power(256,0));
        v_oct3 := trunc(mod(v_in,power(256,2))/power(256,1));
        v_oct2 := trunc(mod(v_in,power(256,3))/power(256,2));
        v_oct1 := trunc(mod(v_in,power(256,4))/power(256,3));
        RETURN v_oct1 || '.' || v_oct2 || '.' || v_oct3 || '.' || v_oct4;
    END;
    -- Bit Or Function
    FUNCTION bitor(x NUMBER, y NUMBER) RETURN NUMBER DETERMINISTIC
    IS
    BEGIN
        RETURN x + y - bitand(x, y);
    END;
    -- Get Min IP decimal for CIDR
    FUNCTION cidr_dec_min (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_ip_num NUMBER;
        v_mask_num NUMBER;
        v_mask NUMBER(2);
    BEGIN
        v_ip_num := ip_to_dec(SUBSTR(v_in,1,instr(v_in,'/',1,1)-1));
        v_mask := SUBSTR(v_in,instr(v_in,'/',1,1)+1);
        v_mask_num := POWER(2,32) - POWER(2,32 - v_mask);
        RETURN BITAND(v_ip_num,v_mask_num);
    END;
    -- Get Max IP decimal for CIDR
    FUNCTION cidr_dec_max (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_ip_num NUMBER;
        v_mask_num NUMBER;
        v_mask NUMBER(2);
    BEGIN
        v_ip_num := ip_to_dec(SUBSTR(v_in,1,instr(v_in,'/',1,1)-1));
        v_mask := SUBSTR(v_in,instr(v_in,'/',1,1)+1);
        v_mask_num := POWER(2,32 - v_mask)-1;
        RETURN BITOR(v_ip_num,v_mask_num);
    END;
}';

  :sql_text := q'{
SELECT ts.DISPLAY_NAME,
       ts.VCN_NAME,
       ts.COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts.SOURCE,
       ts.SOURCE_TYPE,
       ts.PROTOCOL,
       ts.SOURCE_PORT_RANGE_MIN,
       ts.SOURCE_PORT_RANGE_MAX,
       ts.DESTINATION_PORT_RANGE_MIN,
       ts.DESTINATION_PORT_RANGE_MAX,
       ts.ICMP_CODE,
       ts.ICMP_TYPE,
       ts.IS_STATELESS,
       ts.ID,
       ts.SOURCE_IP,
       ts.CIDR_BLOCK,
       ip_to_dec(ts.SOURCE_IP),
       cidr_dec_min(ts.CIDR_BLOCK),
       cidr_dec_max(ts.CIDR_BLOCK)
FROM  (SELECT ts.DISPLAY_NAME,
              tvcn.DISPLAY_NAME VCN_NAME,
              tcomp.NAME COMPARTMENT_NAME,
              ts.TIME_CREATED,
              ts.LIFECYCLE_STATE,
              ts."INGRESS_SECURITY_RULES$SOURCE"                                  SOURCE,
              ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"                             SOURCE_TYPE,
              ts."INGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
              ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
              ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
              ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
              ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
              ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
              ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
              ts."INGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
              ts.ID,
              tvcn.CIDR_BLOCK,
              tvcn.ID VCN_ID,
              SUBSTR(ts."INGRESS_SECURITY_RULES$SOURCE",1,instr(ts."INGRESS_SECURITY_RULES$SOURCE",'/',1,1)-1) SOURCE_IP
       FROM   OCI360_SECLISTS ts,
              OCI360_VCNS tvcn,
              OCI360_COMPARTMENTS tcomp
       WHERE  ts.COMPARTMENT_ID = tcomp.ID
       AND    ts.VCN_ID = tvcn.ID
       AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" = 'CIDR_BLOCK'
       AND    ts."INGRESS_SECURITY_RULES$PROTOCOL"!='17'
       AND    SUBSTR(ts."INGRESS_SECURITY_RULES$SOURCE",instr(ts."INGRESS_SECURITY_RULES$SOURCE",'/',1,1)+1)=32
       AND    cidr_dec_min(ts."INGRESS_SECURITY_RULES$SOURCE") between cidr_dec_min(tvcn.CIDR_BLOCK) and cidr_dec_max(tvcn.CIDR_BLOCK)
       AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
       UNION ALL
       SELECT ts.DISPLAY_NAME,
              tvcn.DISPLAY_NAME VCN_NAME,
              tcomp.NAME COMPARTMENT_NAME,
              ts.TIME_CREATED,
              ts.LIFECYCLE_STATE,
              ts."INGRESS_SECURITY_RULES$SOURCE"                                  SOURCE,
              ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"                             SOURCE_TYPE,
              ts."INGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
              ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
              ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
              ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
              ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
              ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
              ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
              ts."INGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
              ts.ID,
              tvcn.CIDR_BLOCK,
              tvcn.ID VCN_ID,
              SUBSTR(ts."INGRESS_SECURITY_RULES$SOURCE",1,instr(ts."INGRESS_SECURITY_RULES$SOURCE",'/',1,1)-1) SOURCE_IP
       FROM   OCI360_SECLISTS ts,
              OCI360_VCNS tvcn,
              OCI360_COMPARTMENTS tcomp
       WHERE  ts.COMPARTMENT_ID = tcomp.ID
       AND    ts.VCN_ID = tvcn.ID
       AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" = 'CIDR_BLOCK'
       AND    ts."INGRESS_SECURITY_RULES$PROTOCOL"='17'
       AND    SUBSTR(ts."INGRESS_SECURITY_RULES$SOURCE",instr(ts."INGRESS_SECURITY_RULES$SOURCE",'/',1,1)+1)=32
       AND    cidr_dec_min(ts."INGRESS_SECURITY_RULES$SOURCE") between cidr_dec_min(tvcn.CIDR_BLOCK) and cidr_dec_max(tvcn.CIDR_BLOCK)
       AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.') ts
WHERE  SOURCE_IP NOT IN
       ( SELECT tpips.ip_address
         from   OCI360_SUBNETS tsub,
                OCI360_PRIVATEIPS tpips
         where  tpips.SUBNET_ID = tsub.id
         AND    tsub.VCN_ID = ts.VCN_ID
       )
ORDER  BY COMPARTMENT_NAME,VCN_NAME,DISPLAY_NAME,LIFECYCLE_STATE,PROTOCOL
}';
END;
/

@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Redundant Security Ingress Rules'
DEF main_table = 'OCI360_SECLISTS'

BEGIN
  :sql_with_clause := q'{
WITH
    -- Functions by Rodrigo Jorge - www.dbarj.com.br
    -- Convert IP to Decimal
    FUNCTION ip_to_dec (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_oct1 NUMBER(3);
        v_oct2 NUMBER(3);
        v_oct3 NUMBER(3);
        v_oct4 NUMBER(3);
    BEGIN
        v_oct1 := SUBSTR(v_in,1,instr(v_in,'.',1,1)-1);
        v_oct2 := SUBSTR(v_in,instr(v_in,'.',1,1)+1,instr(v_in,'.',1,2)-instr(v_in,'.',1,1)-1);
        v_oct3 := SUBSTR(v_in,instr(v_in,'.',1,2)+1,instr(v_in,'.',1,3)-instr(v_in,'.',1,2)-1);
        v_oct4 := SUBSTR(v_in,instr(v_in,'.',1,3)+1);
        RETURN v_oct1*power(256,3)+v_oct2*power(256,2)+v_oct3*power(256,1)+v_oct4*power(256,0);
    END;
    -- Convert Decimal to IP
    FUNCTION dec_to_ip (v_in NUMBER) RETURN VARCHAR2 DETERMINISTIC IS
        v_oct1 NUMBER(3);
        v_oct2 NUMBER;
        v_oct3 NUMBER;
        v_oct4 NUMBER(3);
    BEGIN
        v_oct4 := trunc(mod(v_in,power(256,1))/power(256,0));
        v_oct3 := trunc(mod(v_in,power(256,2))/power(256,1));
        v_oct2 := trunc(mod(v_in,power(256,3))/power(256,2));
        v_oct1 := trunc(mod(v_in,power(256,4))/power(256,3));
        RETURN v_oct1 || '.' || v_oct2 || '.' || v_oct3 || '.' || v_oct4;
    END;
    -- Bit Or Function
    FUNCTION bitor(x NUMBER, y NUMBER) RETURN NUMBER DETERMINISTIC
    IS
    BEGIN
        RETURN x + y - bitand(x, y);
    END;
    -- Get Min IP decimal for CIDR
    FUNCTION cidr_dec_min (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_ip_num NUMBER;
        v_mask_num NUMBER;
        v_mask NUMBER(2);
    BEGIN
        v_ip_num := ip_to_dec(SUBSTR(v_in,1,instr(v_in,'/',1,1)-1));
        v_mask := SUBSTR(v_in,instr(v_in,'/',1,1)+1);
        v_mask_num := POWER(2,32) - POWER(2,32 - v_mask);
        RETURN BITAND(v_ip_num,v_mask_num);
    END;
    -- Get Max IP decimal for CIDR
    FUNCTION cidr_dec_max (v_in VARCHAR2) RETURN NUMBER DETERMINISTIC IS
        v_ip_num NUMBER;
        v_mask_num NUMBER;
        v_mask NUMBER(2);
    BEGIN
        v_ip_num := ip_to_dec(SUBSTR(v_in,1,instr(v_in,'/',1,1)-1));
        v_mask := SUBSTR(v_in,instr(v_in,'/',1,1)+1);
        v_mask_num := POWER(2,32 - v_mask)-1;
        RETURN BITOR(v_ip_num,v_mask_num);
    END;
}';

  :sql_text := q'{
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts."INGRESS_SECURITY_RULES$SOURCE"                                  SOURCE,
       ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"                             SOURCE_TYPE,
       ts."INGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
       ts."INGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" is not null
AND    ts."INGRESS_SECURITY_RULES$PROTOCOL"!='17'
AND    EXISTS (
              SELECT 1
              FROM   OCI360_SECLISTS TS2
              WHERE  TS.ID = TS2.ID
              AND    ts.rowid <> ts2.rowid
              AND    (cidr_dec_min(ts."INGRESS_SECURITY_RULES$SOURCE") >= cidr_dec_min(ts2."INGRESS_SECURITY_RULES$SOURCE")
                      and cidr_dec_max(ts."INGRESS_SECURITY_RULES$SOURCE") <= cidr_dec_max(ts2."INGRESS_SECURITY_RULES$SOURCE"))
              AND    (ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" = ts2."INGRESS_SECURITY_RULES$SOURCE_TYPE")
              AND    (ts."INGRESS_SECURITY_RULES$PROTOCOL" = ts2."INGRESS_SECURITY_RULES$PROTOCOL"
                      or ts2."INGRESS_SECURITY_RULES$PROTOCOL"='all')
              AND    (ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN" = ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN"
                      or ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MIN" is null)
              AND    (ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX" = ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX"
                      or ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$SOURCE_PORT_RANGE$MAX" is null)
              AND    (ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN" = ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN"
                      or ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MIN" is null)
              AND    (ts."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX" = ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX"
                      or ts2."INGRESS_SECURITY_RULES$TCP_OPTIONS$DESTINATION_PORT_RANGE$MAX" is null)
              AND    (ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE" = ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"
                      or ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE" is null)
              AND    (ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE" = ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"
                      or ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE" is null)
              AND    (ts."INGRESS_SECURITY_RULES$IS_STATELESS" = ts2."INGRESS_SECURITY_RULES$IS_STATELESS")
       )
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
UNION
SELECT ts.DISPLAY_NAME,
       tvcn.DISPLAY_NAME VCN_NAME,
       tcomp.NAME COMPARTMENT_NAME,
       ts.TIME_CREATED,
       ts.LIFECYCLE_STATE,
       ts."INGRESS_SECURITY_RULES$SOURCE"                                  SOURCE,
       ts."INGRESS_SECURITY_RULES$SOURCE_TYPE"                             SOURCE_TYPE,
       ts."INGRESS_SECURITY_RULES$PROTOCOL"                                PROTOCOL,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN"       SOURCE_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX"       SOURCE_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN"  DESTINATION_PORT_RANGE_MIN,
       ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX"  DESTINATION_PORT_RANGE_MAX,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"                       ICMP_CODE,
       ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"                       ICMP_TYPE,
       ts."INGRESS_SECURITY_RULES$IS_STATELESS"                            IS_STATELESS,
       ts.ID
FROM   OCI360_SECLISTS ts,
       OCI360_VCNS tvcn,
       OCI360_COMPARTMENTS tcomp
WHERE  ts.COMPARTMENT_ID = tcomp.ID
AND    ts.VCN_ID = tvcn.ID
AND    ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" is not null
AND    ts."INGRESS_SECURITY_RULES$PROTOCOL"='17'
AND    EXISTS (
              SELECT 1
              FROM   OCI360_SECLISTS TS2
              WHERE  TS.ID = TS2.ID
              AND    ts.rowid <> ts2.rowid
              AND    (cidr_dec_min(ts."INGRESS_SECURITY_RULES$SOURCE") >= cidr_dec_min(ts2."INGRESS_SECURITY_RULES$SOURCE")
                      and cidr_dec_max(ts."INGRESS_SECURITY_RULES$SOURCE") <= cidr_dec_max(ts2."INGRESS_SECURITY_RULES$SOURCE"))
              AND    (ts."INGRESS_SECURITY_RULES$SOURCE_TYPE" = ts2."INGRESS_SECURITY_RULES$SOURCE_TYPE")
              AND    (ts."INGRESS_SECURITY_RULES$PROTOCOL" = ts2."INGRESS_SECURITY_RULES$PROTOCOL"
                      or ts2."INGRESS_SECURITY_RULES$PROTOCOL"='all')
              AND    (ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN" = ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN"
                      or ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MIN" is null)
              AND    (ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX" = ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX"
                      or ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$SOURCE_PORT_RANGE$MAX" is null)
              AND    (ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN" = ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN"
                      or ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MIN" is null)
              AND    (ts."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX" = ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX"
                      or ts2."INGRESS_SECURITY_RULES$UDP_OPTIONS$DESTINATION_PORT_RANGE$MAX" is null)
              AND    (ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE" = ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE"
                      or ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$CODE" is null)
              AND    (ts."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE" = ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE"
                      or ts2."INGRESS_SECURITY_RULES$ICMP_OPTIONS$TYPE" is null)
              AND    (ts."INGRESS_SECURITY_RULES$IS_STATELESS" = ts2."INGRESS_SECURITY_RULES$IS_STATELESS")
       )
AND    substr(ts.id,instr(ts.id,'.',1,3)+1,instr(ts.id,'.',1,4)-instr(ts.id,'.',1,3)-1) = '&&oci360_current_region.'
ORDER  BY COMPARTMENT_NAME,VCN_NAME,DISPLAY_NAME,LIFECYCLE_STATE,PROTOCOL
}';
END;
/

@@&&9a_pre_one.

-----------------------------------------

EXEC :sql_text_secl_ingress := '';