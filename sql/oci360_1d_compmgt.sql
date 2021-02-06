-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_INST_CONFIG'
@@&&fc_table_loader. 'OCI360_INST_POOLS'
@@&&fc_table_loader. 'OCI360_INST_POOLS_INSTS'
-----------------------------------------

DEF title = 'Instance Configurations'
DEF main_table = 'OCI360_INST_CONFIG'

BEGIN
  :sql_text := q'{
SELECT distinct ID, DISPLAY_NAME, TIME_CREATED, COMPARTMENT_ID
FROM   OCI360_INST_CONFIG t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Instance Configuration Deferred Fields'
DEF main_table = 'OCI360_INST_CONFIG'

BEGIN
  :sql_text := q'{
SELECT ID, DISPLAY_NAME, TIME_CREATED, COMPARTMENT_ID, DEFERRED_FIELDS
FROM   OCI360_INST_CONFIG t1
WHERE  DEFERRED_FIELDS is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Instance Configuration Details'
DEF main_table = 'OCI360_INST_CONFIG'

BEGIN
  :sql_text := q'{
SELECT *
FROM   OCI360_INST_CONFIG t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Instance Pools'
DEF main_table = 'OCI360_INST_POOLS'

BEGIN
  :sql_text := q'{
SELECT ID,
       SIZE,
       DISPLAY_NAME,
       TIME_CREATED,
       COMPARTMENT_ID,
       LOAD_BALANCERS,
       LIFECYCLE_STATE,
       INSTANCE_CONFIGURATION_ID,
       PLACEMENT_CONFIGURATIONS$PRIMARY_SUBNET_ID,
       PLACEMENT_CONFIGURATIONS$AVAILABILITY_DOMAIN,
       PLACEMENT_CONFIGURATIONS$SECONDARY_VNIC_SUBNETS
FROM   OCI360_INST_POOLS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Instance Pool Members'
DEF main_table = 'OCI360_INST_POOLS_INSTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_INST_POOLS_INSTS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------