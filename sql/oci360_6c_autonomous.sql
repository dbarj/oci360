-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_AUTONOMOUS_DB'
@@&&fc_table_loader. 'OCI360_AUTONOMOUS_DB_BKP'
@@&&fc_table_loader. 'OCI360_AUTONOMOUS_DW'
@@&&fc_table_loader. 'OCI360_AUTONOMOUS_DW_BKP'
-----------------------------------------

DEF title = 'Autonomous Databases'
DEF main_table = 'OCI360_AUTONOMOUS_DB'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUTONOMOUS_DB t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Autonomous Database Backups'
DEF main_table = 'OCI360_AUTONOMOUS_DB_BKP'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUTONOMOUS_DB_BKP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Autonomous Datawarehouses'
DEF main_table = 'OCI360_AUTONOMOUS_DW'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUTONOMOUS_DW t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Autonomous Datawarehouse Backups'
DEF main_table = 'OCI360_AUTONOMOUS_DW_BKP'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUTONOMOUS_DW_BKP t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------