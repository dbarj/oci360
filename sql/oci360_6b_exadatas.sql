-----------------------------------------

DEF title = 'Database Estimated Costs'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
WITH DB_SRV AS
(
  SELECT distinct
         ID,
         CLUSTER_NAME,
         DISPLAY_NAME,
         LICENSE_MODEL,
         SHAPE,
         CPU_CORE_COUNT,
         DATABASE_EDITION,
         SUBSTR(SHAPE,1,INSTR(SHAPE,'.',1,1)-1)                                      SHAPE_TYPE,
         SUBSTR(SHAPE,INSTR(SHAPE,'.',-1,1)+1,LENGTH(SHAPE)-INSTR(SHAPE,'.',-1,1))   SHAPE_MAX_OCPUS
  FROM   OCI360_DB_SYSTEMS X
  WHERE  SHAPE LIKE 'VM.%' OR SHAPE LIKE 'BM.%'
),
DB_COST AS (
SELECT /*+ materialize */
       INST_TYPE,
       PAYG,
       MF,
       SUBSTR(INST_TYPE,1,INSTR(INST_TYPE,'.',1,1)-1) DB_VERS,
       LIC_TYPE DB_LIC_TYPE,
       SUBSTR(INST_TYPE,INSTR(INST_TYPE,'.',1,1)+1) DB_OCPUS_INCL
FROM   OCI360_PRICING
WHERE  SUBJECT = 'DATABASE'
AND    SUBSTR(INST_TYPE,INSTR(INST_TYPE,'.',1,1)+1) != 'OCPU'
),
DB_OCPU AS (
SELECT /*+ materialize */
       INST_TYPE,
       PAYG,
       MF,
       SUBSTR(INST_TYPE,1,INSTR(INST_TYPE,'.',1,1)-1) DB_VERS,
       LIC_TYPE DB_LIC_TYPE
FROM   OCI360_PRICING
WHERE  SUBJECT = 'DATABASE'
AND    INSTR(INST_TYPE,'.',1,2) = 0
AND    SUBSTR(INST_TYPE,INSTR(INST_TYPE,'.',1,1)+1) = 'OCPU'
)
SELECT t1.CLUSTER_NAME,
       t1.DISPLAY_NAME,
       t1.SHAPE_TYPE,
       t1.CPU_CORE_COUNT,
       t1.LICENSE_MODEL,
       t1.SHAPE,
       (t1.CPU_CORE_COUNT - t2.DB_OCPUS_INCL) EXTRA_USED_OCPUS,
       t1.SHAPE_MAX_OCPUS MAX_OCPUS,
       t1.DATABASE_EDITION,
       t1.ID,
       ROUND(T2.MF * 24 * 30,2) "Database - US$ Cost per month",
       ROUND((t1.CPU_CORE_COUNT - t2.DB_OCPUS_INCL) * T3.MF * 24 * 30,2) "Extra CPU - US$ Cost per month",
       ROUND((T2.MF   + (t1.CPU_CORE_COUNT - t2.DB_OCPUS_INCL) * T3.MF  ) * 24 * 30,2) "Total - US$ Cost per month"
FROM   DB_SRV      t1,
       DB_COST t2,
       DB_OCPU t3
WHERE  t1.SHAPE_TYPE = t2.DB_VERS (+)
AND    DECODE(t1.LICENSE_MODEL,'LICENSE_INCLUDED',t1.DATABASE_EDITION,t1.LICENSE_MODEL) = t2.DB_LIC_TYPE (+)
AND    t1.SHAPE_TYPE = t3.DB_VERS (+)
AND    DECODE(t1.LICENSE_MODEL,'LICENSE_INCLUDED',t1.DATABASE_EDITION,t1.LICENSE_MODEL) = t3.DB_LIC_TYPE (+)
}';
END;
/
DEF foot = '* US$ costs are estimations for Month Flex, not considering ANY account discounts. Values base date: &&oci360_pricing_date.<br>';

@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Exadata Estimated Costs'
DEF main_table = 'OCI360_DB_SYSTEMS'

BEGIN
  :sql_text := q'{
WITH EXA_SRV AS
(
  SELECT distinct
         ID,
         CLUSTER_NAME,
         DISPLAY_NAME,
         LICENSE_MODEL,
         SHAPE,
         CPU_CORE_COUNT,
         DATABASE_EDITION,
         SUBSTR(SHAPE,INSTR(SHAPE,'.',1,1)+1,INSTR(SHAPE,'.',1,2)-INSTR(SHAPE,'.',1,1)-1) EXA_TYPE,
         SUBSTR(SHAPE,INSTR(SHAPE,'.',1,2)+1,LENGTH(SHAPE)-INSTR(SHAPE,'.',1,2))          EXA_MAX_OCPUS
  FROM   OCI360_DB_SYSTEMS X
  WHERE  SHAPE LIKE 'Exadata.%'
),
EXA AS
(
  SELECT ID,
         CLUSTER_NAME,
         DISPLAY_NAME,
         LICENSE_MODEL,
         SHAPE,
         CPU_CORE_COUNT,
         DATABASE_EDITION,
         EXA_MAX_OCPUS,
         UPPER(SUBSTR(EXA_TYPE,1,LENGTH(EXA_TYPE)-1)) EXA_SIZE,
         SUBSTR(EXA_TYPE,LENGTH(EXA_TYPE),1)   EXA_VERS
  FROM   EXA_SRV
),
EXA_COST AS (
SELECT /*+ materialize */
       INST_TYPE,
       PAYG,
       MF,
       SUBSTR(INST_TYPE,1,INSTR(INST_TYPE,'.',1,1)-1) EXA_VERS,
       SUBSTR(INST_TYPE,INSTR(INST_TYPE,'.',1,1)+1,INSTR(INST_TYPE,'.',1,2)-INSTR(INST_TYPE,'.',1,1)-1) EXA_SIZE,
       LIC_TYPE EXA_LIC_TYPE,
       SUBSTR(INST_TYPE,INSTR(INST_TYPE,'.',1,2)+1) EXA_OCPUS_INCL
FROM   OCI360_PRICING
WHERE  SUBJECT = 'EXADATA'
AND    INSTR(INST_TYPE,'.',1,2) != 0
),
EXA_OCPU AS (
SELECT /*+ materialize */
       INST_TYPE,
       PAYG,
       MF,
       SUBSTR(INST_TYPE,1,INSTR(INST_TYPE,'.',1,1)-1) EXA_VERS,
       LIC_TYPE EXA_LIC_TYPE
FROM   OCI360_PRICING
WHERE  SUBJECT = 'EXADATA'
AND    INSTR(INST_TYPE,'.',1,2) = 0
AND    SUBSTR(INST_TYPE,INSTR(INST_TYPE,'.',1,1)+1) = 'OCPU'
)
SELECT t1.CLUSTER_NAME,
       t1.DISPLAY_NAME,
       t2.EXA_VERS,
       t1.EXA_SIZE,
       t1.CPU_CORE_COUNT,
       t1.LICENSE_MODEL,
       t1.SHAPE,
       (t1.CPU_CORE_COUNT - t2.EXA_OCPUS_INCL) EXTRA_USED_OCPUS,
       t1.EXA_MAX_OCPUS MAX_OCPUS,
       t1.DATABASE_EDITION,
       t1.ID,
       ROUND(T2.MF * 24 * 30,2) "Exadata - US$ Cost per month",
       ROUND((t1.CPU_CORE_COUNT - t2.EXA_OCPUS_INCL) * T3.MF * 24 * 30,2) "Extra CPU - US$ Cost per month",
       ROUND((T2.MF   + (t1.CPU_CORE_COUNT - t2.EXA_OCPUS_INCL) * T3.MF  ) * 24 * 30,2) "Total - US$ Cost per month"
FROM   EXA      t1,
       EXA_COST t2,
       EXA_OCPU t3
WHERE  DECODE(t1.EXA_VERS,1,'X6',2,'X7') = t2.EXA_VERS (+)
AND    DECODE(t1.LICENSE_MODEL,'LICENSE_INCLUDED','LIC','BYOL') = t2.EXA_LIC_TYPE (+)
AND    DECODE(t1.EXA_SIZE,'QUARTER','QR','HALF','HR','FULL','FR') = T2.EXA_SIZE (+)
AND    t2.EXA_VERS = t3.EXA_VERS (+)
AND    t2.EXA_LIC_TYPE = t3.EXA_LIC_TYPE (+)
}';
END;
/
DEF foot = '* US$ costs are estimations for Month Flex, not considering ANY account discounts. Values base date: &&oci360_pricing_date.<br>';

@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Exadata Infrastructure'
DEF main_table = 'OCI360_DB_EXAINFRA'

BEGIN
  :sql_text := q'{
SELECT * FROM OCI360_DB_EXAINFRA
}';
END;
/

@@&&9a_pre_one.
