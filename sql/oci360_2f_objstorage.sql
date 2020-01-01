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

DEF title = 'Buckets Objects'
DEF main_table = 'OCI360_OBJECTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_OBJECTS t1
}';
END;
/
@@&&9a_pre_one.

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
@@&&9a_pre_one.

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