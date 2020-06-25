-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_NAMESERVER'
@@&&fc_json_loader. 'OCI360_NAMESERVER_META'
@@&&fc_json_loader. 'OCI360_BUCKETS'
@@&&fc_json_loader. 'OCI360_MULTIPARTS'
@@&&fc_json_loader. 'OCI360_OBJECTS'
@@&&fc_json_loader. 'OCI360_PREAUTH_REQUESTS'
@@&&fc_json_loader. 'OCI360_OS_WORKREQS'
@@&&fc_json_loader. 'OCI360_OBJECT_POLICIES'
-----------------------------------------

COL skip_objects_table NEW_V skip_objects_table
SELECT DECODE(count(*),0,'&&fc_skip_script.','') skip_objects_table
FROM   ALL_TABLES
WHERE  owner = SYS_CONTEXT('userenv','current_schema')
and    table_name = 'OCI360_OBJECTS';
COL skip_objects_table clear

-----------------------------------------

DEF title = 'Nameserver'
DEF main_table = 'OCI360_NAMESERVER'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_NAMESERVER t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Nameserver Metadata'
DEF main_table = 'OCI360_NAMESERVER_META'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_NAMESERVER_META t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Buckets'
DEF main_table = 'OCI360_BUCKETS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_BUCKETS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Multiparts'
DEF main_table = 'OCI360_MULTIPARTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_MULTIPARTS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF max_rows = 100
DEF title = 'Objects - 100 random lines'
DEF main_table = 'OCI360_AUDIT_EVENTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_OBJECTS SAMPLE (1) t1
FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&skip_objects_table.&&9a_pre_one.

-----------------------------------------

DEF title = 'Objects - Grouped by PATH'
DEF main_table = 'OCI360_OBJECTS'

BEGIN
  :sql_text := q'{
select t.MD5,
       t.BUCKET_NAME,
       t.TIME_CREATED,
       substr(t.name, 1, decode(instr(t.name,'/',-1),0,length(t.name),instr(t.name,'/',-1))) PATH,
       sum(t."SIZE") "SIZE"
from   OCI360_OBJECTS t
GROUP BY MD5,
         BUCKET_NAME,
         TIME_CREATED,
         substr(t.name, 1, decode(instr(t.name,'/',-1),0,length(t.name),instr(t.name,'/',-1)))
}';
END;
/
@@&&skip_objects_table.&&9a_pre_one.

-----------------------------------------

DEF title = 'Buckets - Approx Totals'
DEF main_table = 'OCI360_BUCKETS'

BEGIN
  :sql_text := q'{
select t.NAME,
       t."APPROXIMATE_SIZE"/POWER(1024,3) "APPROX_SIZE_GB",
       t."APPROXIMATE_COUNT" "APPROX_COUNT"
from   OCI360_BUCKETS t
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Objects - Totals'
DEF main_table = 'OCI360_OBJECTS'

BEGIN
  :sql_text := q'{
select t.BUCKET_NAME,
       sum(t."SIZE")/POWER(1024,3) "SIZE_GB",
       COUNT(*) "COUNT",
       t2."APPROXIMATE_SIZE"/POWER(1024,3) "APPROX_SIZE_GB",
       t2."APPROXIMATE_COUNT" "APPROX_COUNT"
from   OCI360_OBJECTS t, OCI360_BUCKETS t2
WHERE  t.BUCKET_NAME=t2.NAME
GROUP BY BUCKET_NAME, t2."APPROXIMATE_SIZE", t2."APPROXIMATE_COUNT"
}';
END;
/
@@&&skip_objects_table.&&9a_pre_one.

-----------------------------------------

DEF title = 'Pre-authenticated Requests'
DEF main_table = 'OCI360_PREAUTH_REQUESTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PREAUTH_REQUESTS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Work Requests'
DEF main_table = 'OCI360_OS_WORKREQS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_OS_WORKREQS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Lifecycle Policy Rules'
DEF main_table = 'OCI360_OBJECT_POLICIES'

BEGIN
  :sql_text := q'{
SELECT distinct
       ITEMS$NAME,
       ITEMS$ACTION,
       ITEMS$TIME_UNIT,
       ITEMS$IS_ENABLED,
       ITEMS$TIME_AMOUNT,
       TIME_CREATED
FROM   OCI360_OBJECT_POLICIES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Lifecycle Policy Rules - Prefixes'
DEF main_table = 'OCI360_OBJECT_POLICIES'

BEGIN
  :sql_text := q'{
SELECT ITEMS$NAME,
       ITEMS$OBJECT_NAME_FILTER$INCLUSION_PREFIXES
FROM   OCI360_OBJECT_POLICIES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------
UNDEF skip_objects_table