-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_BDS_INSTANCES'
-----------------------------------------

DEF title = 'BigData Cluster Info'
DEF main_table = 'OCI360_BDS_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       IS_SECURE,
       CREATED_BY,
       DISPLAY_NAME,
       TIME_CREATED,
       TIME_UPDATED,
       COMPARTMENT_ID,
       NETWORK_CONFIG$CIDR_BLOCK,
       NETWORK_CONFIG$IS_NAT_GATEWAY_REQUIRED,
       CLUSTER_VERSION,
       LIFECYCLE_STATE,
       NUMBER_OF_NODES,
       CLOUD_SQL_DETAILS,
       IS_HIGH_AVAILABILITY,
       IS_CLOUD_SQL_CONFIGURED
FROM   OCI360_BDS_INSTANCES
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'BigData Cluster Details'
DEF main_table = 'OCI360_BDS_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       CLUSTER_DETAILS$BDA_VERSION,
       CLUSTER_DETAILS$BDM_VERSION,
       CLUSTER_DETAILS$TIME_CREATED,
       CLUSTER_DETAILS$HUE_SERVER_URL,
       CLUSTER_DETAILS$TIME_REFRESHED,
       CLUSTER_DETAILS$BIG_DATA_MANAGER_URL,
       CLUSTER_DETAILS$CLOUDERA_MANAGER_URL
FROM   OCI360_BDS_INSTANCES
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'BigData Nodes'
DEF main_table = 'OCI360_BDS_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT ID,
       NODES$SHAPE,
       NODES$HOSTNAME,
       NODES$IMAGE_ID,
       NODES$NODE_TYPE,
       NODES$SUBNET_ID,
       NODES$IP_ADDRESS,
       NODES$INSTANCE_ID,
       NODES$DISPLAY_NAME,
       NODES$FAULT_DOMAIN,
       NODES$TIME_CREATED,
       NODES$TIME_UPDATED,
       NODES$LIFECYCLE_STATE,
       NODES$SSH_FINGERPRINT,
       NODES$AVAILABILITY_DOMAIN,
       SUM(NODES$ATTACHED_BLOCK_VOLUMES$VOLUME_SIZE_IN_GBS) TOTAL_VOLUME_SIZE_IN_GBS
FROM   OCI360_BDS_INSTANCES
GROUP BY ID,
         NODES$SHAPE,
         NODES$HOSTNAME,
         NODES$IMAGE_ID,
         NODES$NODE_TYPE,
         NODES$SUBNET_ID,
         NODES$IP_ADDRESS,
         NODES$INSTANCE_ID,
         NODES$DISPLAY_NAME,
         NODES$FAULT_DOMAIN,
         NODES$TIME_CREATED,
         NODES$TIME_UPDATED,
         NODES$LIFECYCLE_STATE,
         NODES$SSH_FINGERPRINT,
         NODES$AVAILABILITY_DOMAIN
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'BigData Volumes'
DEF main_table = 'OCI360_BDS_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       NODES$HOSTNAME,
       NODES$NODE_TYPE,
       NODES$IP_ADDRESS,
       NODES$INSTANCE_ID,
       NODES$DISPLAY_NAME,
       NODES$ATTACHED_BLOCK_VOLUMES$VOLUME_SIZE_IN_GBS,
       NODES$ATTACHED_BLOCK_VOLUMES$VOLUME_ATTACHMENT_ID
FROM   OCI360_BDS_INSTANCES
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'BigData Total Volume'
DEF main_table = 'OCI360_BDS_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT ID,
       DISPLAY_NAME,
       NETWORK_CONFIG$CIDR_BLOCK,
       LIFECYCLE_STATE,
       NUMBER_OF_NODES,
       SUM(NODES$ATTACHED_BLOCK_VOLUMES$VOLUME_SIZE_IN_GBS) TOTAL_VOLUME_SIZE_IN_GBS
FROM   OCI360_BDS_INSTANCES
GROUP BY ID,
         DISPLAY_NAME,
         NETWORK_CONFIG$CIDR_BLOCK,
         LIFECYCLE_STATE,
         NUMBER_OF_NODES
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'BigData Raw'
DEF main_table = 'OCI360_BDS_INSTANCES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_BDS_INSTANCES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------