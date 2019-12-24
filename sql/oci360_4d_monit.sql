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
DEF main_table = 'OCI360_MONIT_METRIC_LIST'

BEGIN
  :sql_text := q'{
SELECT DISTINCT
       NAME,
       METADATA$UNIT,
       METADATA$DESCRIPTION,
       METADATA$DISPLAYNAME,
       NAMESPACE,
       RESOLUTION
FROM   OCI360_MONIT_METRIC_DATA_1HMAX t1
ORDER  BY NAMESPACE, NAME
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Monitoring Metric Data'
DEF main_table = 'OCI360_MONIT_METRIC_DATA'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_MONIT_METRIC_DATA t1
}';
END;
/
--@@&&9a_pre_one.

-----------------------------------------