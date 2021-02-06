-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_RESTYPES'
-----------------------------------------

DEF title = 'Resource Types'
DEF main_table = 'OCI360_RESTYPES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_RESTYPES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Json Metadata'
DEF main_table = '&&oci360_obj_metadata.'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   "&&oci360_obj_metadata." t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'IaaS Pricing'
DEF main_table = '&&oci360_obj_pricing.'

BEGIN
  :sql_text := q'{
SELECT SUBJECT,
       LIC_TYPE,
       INST_TYPE,
       TO_CHAR(CEIL(PAYG*100)/100,'999G990D99') PAYG_US$,
       TO_CHAR(CEIL(MF*100)/100,'999G990D99') MF_US$
FROM   "&&oci360_obj_pricing." t1
}';
END;
/
DEF foot = '* US$ values base url: &&oci360_pricing_url.<br> US$ values base date: &&oci360_pricing_date.<br>';
@@&&skip_billing_sql.&&9a_pre_one.
@@&&fc_reset_defs.

-----------------------------------------