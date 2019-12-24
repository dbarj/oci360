-----------------------------------------

DEF title = 'CPEs'
DEF main_table = 'OCI360_CPE'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CPE t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'IPSec Connections'
DEF main_table = 'OCI360_IPSEC_CONNS'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       CPE_ID,
       DRG_ID,
       DISPLAY_NAME,
       TIME_CREATED,
       COMPARTMENT_ID,
       LIFECYCLE_STATE
FROM   OCI360_IPSEC_CONNS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'IPSec Connections - Static Routes'
DEF main_table = 'OCI360_IPSEC_CONNS'

BEGIN
  :sql_text := q'{
SELECT ID,
       DISPLAY_NAME,
       STATIC_ROUTES
FROM   OCI360_IPSEC_CONNS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Virtual Circuits'
DEF main_table = 'OCI360_VIRT_CIRC'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VIRT_CIRC t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Virtual Circuits Public Prefix'
DEF main_table = 'OCI360_VIRT_CIRC_PUBPREF'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VIRT_CIRC_PUBPREF t1
}';
END;
/
@@&&9a_pre_one.