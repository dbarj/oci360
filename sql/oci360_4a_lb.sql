-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_LB_LOADBALANCERS'
@@&&fc_json_loader. 'OCI360_LB_LOADBALANCERS_HEALTH'
@@&&fc_json_loader. 'OCI360_LB_BACKENDSETS'
@@&&fc_json_loader. 'OCI360_LB_BACKENDSETS_HEALTH'
@@&&fc_json_loader. 'OCI360_LB_BACKENDS'
@@&&fc_json_loader. 'OCI360_LB_BACKENDS_HEALTH'
@@&&fc_json_loader. 'OCI360_LB_CERTIFICATES'
@@&&fc_json_loader. 'OCI360_LB_HEALTHCHECKS'
@@&&fc_json_loader. 'OCI360_LB_HOSTNAMES'
@@&&fc_json_loader. 'OCI360_LB_PATHROUTES'
@@&&fc_json_loader. 'OCI360_LB_POLICIES'
@@&&fc_json_loader. 'OCI360_LB_PROTOCOLS'
@@&&fc_json_loader. 'OCI360_LB_SHAPES'
@@&&fc_json_loader. 'OCI360_LB_WORKREQS'
-----------------------------------------

DEF title = 'Load Balancers'
DEF main_table = 'OCI360_LB_LOADBALANCERS'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       IS_PRIVATE,
       SHAPE_NAME,
       DISPLAY_NAME,
       TIME_CREATED,
       COMPARTMENT_ID,
       LIFECYCLE_STATE,
       IP_ADDRESSES$IS_PUBLIC,
       IP_ADDRESSES$IP_ADDRESS
FROM   OCI360_LB_LOADBALANCERS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Load Balancer Subnets'
DEF main_table = 'OCI360_LB_LOADBALANCERS'

BEGIN
  :sql_text := q'{
SELECT ID,
       DISPLAY_NAME,
       SUBNET_IDS
FROM   OCI360_LB_LOADBALANCERS t1
WHERE  SUBNET_IDS is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Load Balancers Health'
DEF main_table = 'OCI360_LB_LOADBALANCERS_HEALTH'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_LOADBALANCERS_HEALTH t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backend-Sets'
DEF main_table = 'OCI360_LB_BACKENDSETS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_BACKENDSETS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backend-Sets Health'
DEF main_table = 'OCI360_LB_BACKENDSETS_HEALTH'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_BACKENDSETS_HEALTH t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backends'
DEF main_table = 'OCI360_LB_BACKENDS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_BACKENDS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Backends Health'
DEF main_table = 'OCI360_LB_BACKENDS_HEALTH'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_BACKENDS_HEALTH t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Certificates'
DEF main_table = 'OCI360_LB_CERTIFICATES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_CERTIFICATES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Health Checks'
DEF main_table = 'OCI360_LB_HEALTHCHECKS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_HEALTHCHECKS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Hostnames'
DEF main_table = 'OCI360_LB_HOSTNAMES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_HOSTNAMES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Path Routes'
DEF main_table = 'OCI360_LB_PATHROUTES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_PATHROUTES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Policies'
DEF main_table = 'OCI360_LB_POLICIES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_POLICIES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Protocols'
DEF main_table = 'OCI360_LB_PROTOCOLS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_PROTOCOLS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Shapes'
DEF main_table = 'OCI360_LB_SHAPES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_SHAPES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Work Requests'
DEF main_table = 'OCI360_LB_WORKREQS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_LB_WORKREQS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------