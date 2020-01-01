-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_DNS_ZONES'
-----------------------------------------

DEF title = 'Zones'
DEF main_table = 'OCI360_DNS_ZONES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DNS_ZONES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------