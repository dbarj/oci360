-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_LIMITS_SERVICE'
@@&&fc_json_loader. 'OCI360_LIMITS_QUOTA'
@@&&fc_json_loader. 'OCI360_LIMITS_VALUE'
@@&&fc_json_loader. 'OCI360_LIMITS_RES_AVAIL'
-----------------------------------------

DEF title = 'Limits Service'
DEF main_table = 'OCI360_LIMITS_SERVICE'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LIMITS_SERVICE t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Limits Quota'
DEF main_table = 'OCI360_LIMITS_QUOTA'

BEGIN
  :sql_text := q'{
SELECT *
FROM   OCI360_LIMITS_QUOTA t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Limit Value'
DEF main_table = 'OCI360_LIMITS_VALUE'

BEGIN
  :sql_text := q'{
SELECT *
FROM   OCI360_LIMITS_VALUE t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Limits Resource Availability'
DEF main_table = 'OCI360_LIMITS_RES_AVAIL'

BEGIN
  :sql_text := q'{
SELECT *
FROM   OCI360_LIMITS_RES_AVAIL
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------