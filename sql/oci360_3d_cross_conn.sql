-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_CROSSCONN'
@@&&fc_table_loader. 'OCI360_CROSSCONN_GRP'
@@&&fc_table_loader. 'OCI360_CROSSCONN_LOC'
@@&&fc_table_loader. 'OCI360_CROSSCONN_PORT'
@@&&fc_table_loader. 'OCI360_CROSSCONN_STATUS'
-----------------------------------------

DEF title = 'Cross-Connections'
DEF main_table = 'OCI360_CROSSCONN'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CROSSCONN t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cross-Connection Groups'
DEF main_table = 'OCI360_CROSSCONN_GRP'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CROSSCONN_GRP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cross-Connection Locations'
DEF main_table = 'OCI360_CROSSCONN_LOC'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CROSSCONN_LOC t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cross-Connection Ports'
DEF main_table = 'OCI360_CROSSCONN_PORT'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CROSSCONN_PORT t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cross-Connection Status'
DEF main_table = 'OCI360_CROSSCONN_STATUS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CROSSCONN_STATUS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------