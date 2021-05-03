-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_MONIT_METRIC_LIST'
@@&&fc_table_loader. 'OCI360_MONIT_METRIC_DATA_1HMAX'
-----------------------------------------

DEF title = 'Monitoring Metric List'
DEF main_table = 'OCI360_MONIT_METRIC_LIST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_MONIT_METRIC_LIST t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Distinct Metrics'
DEF main_table = 'OCI360_MONIT_METRIC_LIST'

BEGIN
  :sql_text := q'{
SELECT DISTINCT NAME, NAMESPACE, COMPARTMENT_ID
FROM   OCI360_MONIT_METRIC_LIST t1
ORDER  BY 1,2,3
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Distinct Name and Namespace'
DEF main_table = 'OCI360_MONIT_METRIC_LIST'

BEGIN
  :sql_text := q'{
SELECT DISTINCT NAME, NAMESPACE
FROM   OCI360_MONIT_METRIC_LIST t1
ORDER  BY 1,2
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Distinct Metric Info'
DEF main_table = 'OCI360_MONIT_METRIC_DATA_1HMAX'

BEGIN
  :sql_text := q'{
SELECT DISTINCT
       NAME,
       NAMESPACE,
       RESOLUTION
FROM   OCI360_MONIT_METRIC_DATA_1HMAX t1
ORDER  BY NAMESPACE, NAME
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Monitoring Metric Data - Sample 1% Cap 10k'
DEF main_table = 'OCI360_MONIT_METRIC_DATA_1HMAX'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_MONIT_METRIC_DATA_1HMAX SAMPLE (1) t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------