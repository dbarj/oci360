-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_PIC_AGREES'
@@&&fc_json_loader. 'OCI360_PIC_LISTING'
@@&&fc_json_loader. 'OCI360_PIC_SUBS'
@@&&fc_json_loader. 'OCI360_PIC_VERSIONS'
-----------------------------------------

DEF title = 'PIC Agreements'
DEF main_table = 'OCI360_PIC_AGREES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PIC_AGREES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'PIC Listing'
DEF main_table = 'OCI360_PIC_LISTING'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PIC_LISTING t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'PIC Subscription'
DEF main_table = 'OCI360_PIC_SUBS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PIC_SUBS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'PIC Version'
DEF main_table = 'OCI360_PIC_VERSIONS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PIC_VERSIONS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------