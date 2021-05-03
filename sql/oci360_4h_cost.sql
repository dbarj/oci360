-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_REPORTS_COST'
-----------------------------------------

DEF oci360_usage_tzcolformat = 'YYYY-MM-DD"T"HH24:MI"Z"'

--- Get some Usage info before starting
@@&&fc_def_empty_var. oci360_usage_date_from
@@&&fc_def_empty_var. oci360_usage_date_to
@@&&fc_def_empty_var. oci360_usage_period

COL oci360_usage_date_from NEW_V oci360_usage_date_from NOPRI
COL oci360_usage_date_to   NEW_V oci360_usage_date_to   NOPRI
COL oci360_usage_period    NEW_V oci360_usage_period    NOPRI

SELECT TO_CHAR(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'YYYY-MM-DD') oci360_usage_date_from,
       TO_CHAR(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'YYYY-MM-DD') oci360_usage_date_to,
       EXTRACT(DAY FROM (max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')) - min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')))) oci360_usage_period
from   OCI360_REPORTS_COST;

COL oci360_usage_date_from CLEAR
COL oci360_usage_date_to   CLEAR
COL oci360_usage_period    CLEAR

DEF oci360_usage_between = '&&oci360_usage_date_from. and &&oci360_usage_date_to.'

-----------------------------------------

DEF oci360_list_subsec_start = '&&moat369_sw_folder./oci360_fc_list_subsection_start.sql'
DEF oci360_list_subsec_stop  = '&&moat369_sw_folder./oci360_fc_list_subsection_stop.sql'

-----------------------------------------

 -- lineItem/referenceNo				    VARCHAR2(4000)
 -- lineItem/tenantId				    VARCHAR2(4000)
 -- lineItem/intervalUsageStart			    VARCHAR2(4000)
 -- lineItem/intervalUsageEnd			    VARCHAR2(4000)
 -- product/service				    VARCHAR2(4000)
 -- product/compartmentId				    VARCHAR2(4000)
 -- product/compartmentName			    VARCHAR2(4000)
 -- product/region 				    VARCHAR2(4000)
 -- product/availabilityDomain			    VARCHAR2(4000)
 -- product/resourceId				    VARCHAR2(4000)
 -- usage/billedQuantity				    VARCHAR2(4000)
 -- usage/billedQuantityOverage			    VARCHAR2(4000)
 -- cost/subscriptionId				    VARCHAR2(4000)
 -- cost/productSku				    VARCHAR2(4000)
 -- product/Description				    VARCHAR2(4000)
 -- cost/unitPrice 				    VARCHAR2(4000)
 -- cost/unitPriceOverage				    VARCHAR2(4000)
 -- cost/myCost					    VARCHAR2(4000)
 -- cost/myCostOverage				    VARCHAR2(4000)
 -- cost/currencyCode				    VARCHAR2(4000)
 -- cost/billingUnitReadable			    VARCHAR2(4000)
 -- cost/overageFlag				    VARCHAR2(4000)
 -- lineItem/isCorrection				    VARCHAR2(4000)
 -- lineItem/backreferenceNo			    VARCHAR2(4000)
 -- tags/Oracle-Tags.CreatedBy			    VARCHAR2(4000)
 -- tags/Oracle-Tags.CreatedOn			    VARCHAR2(4000)
 -- tags/bds-instance				    VARCHAR2(4000)
 -- tags/orcl-cloud.free-tier-retained		    VARCHAR2(4000)
 -- tags/purpose					    VARCHAR2(4000)
 -- tags/type					    VARCHAR2(4000)
 -- tags/Agenda_AutoScale.Dia_da_Semana		    VARCHAR2(4000)
 -- tags/Description				    VARCHAR2(4000)
 -- tags/Tenancy_Access.OSMS			    VARCHAR2(4000)

 -----------------------------------------;

DEF title = 'Used Services'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT distinct "product/service" "Service"
FROM   OCI360_REPORTS_COST t1
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Used Resources'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT distinct "product/service" "Service", "product/resourceId" "Resource"
FROM   OCI360_REPORTS_COST t1
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Resources Unit Prices'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
select "product/service",
       "product/region",
       "cost/subscriptionId",
       "cost/productSku",
       "cost/unitPrice",
       "cost/unitPriceOverage",
       "cost/currencyCode",
       "cost/billingUnitReadable",
       "cost/overageFlag",
       min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')) MIN_USAGE_END,
       max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')) MAX_USAGE_END
from OCI360_REPORTS_COST
GROUP BY "product/service",
         "product/region",
         "cost/subscriptionId",
         "cost/productSku",
         "cost/unitPrice",
         "cost/unitPriceOverage",
         "cost/currencyCode",
         "cost/billingUnitReadable",
         "cost/overageFlag"
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Services Utilization'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT "product/service" "Service",
        MIN("lineItem/intervalUsageStart") "Date Min",
        MAX("lineItem/intervalUsageStart") "Date Max",
        "cost/subscriptionId" "subscriptionId",
        "cost/productSku" "SKU",
        "cost/currencyCode" "Currency",
        "cost/billingUnitReadable" "Units",
        TO_CHAR(SUM("cost/myCost")) "Total Cost"
FROM   OCI360_REPORTS_COST t1
GROUP BY "product/service",
         "cost/subscriptionId",
         "cost/productSku",
         "cost/currencyCode",
         "cost/billingUnitReadable"
HAVING SUM("cost/myCost")>0
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Resources Utilization'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT "product/service" "Service",
       "product/compartmentId",
       "product/compartmentName",
       "product/region",
       "product/availabilityDomain",
       "product/resourceId",
       MIN("lineItem/intervalUsageStart") "Date Min",
       MAX("lineItem/intervalUsageStart") "Date Max",
       "cost/subscriptionId" "subscriptionId",
       "cost/productSku" "SKU",
       "cost/currencyCode" "Currency",
       "cost/billingUnitReadable" "Units",
       TO_CHAR(SUM("cost/myCost")) "Total Cost"
FROM   OCI360_REPORTS_COST t1
GROUP BY "product/service",
         "product/compartmentId",
         "product/compartmentName",
         "product/region",
         "product/availabilityDomain",
         "product/resourceId","cost/subscriptionId",
         "cost/productSku",
         "cost/currencyCode",
         "cost/billingUnitReadable"
HAVING SUM("cost/myCost")>0
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cost Corrections'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REPORTS_COST t1
WHERE  "lineItem/isCorrection" != 'false'
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cost Overage'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REPORTS_COST t1
WHERE  "cost/myCostOverage" > 0
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.


-----------------------------------------

DEF title = 'Cost Gaps'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
WITH t1 AS (
  SELECT /*+ materialize */ distinct TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC
  FROM   OCI360_REPORTS_COST
),
trange as (
  select trunc(min(ENDTIMEUTC),'HH24') min,
         trunc(max(ENDTIMEUTC),'HH24') max
  FROM   t1
),
allhours as ( /*  Will generate all hours between Min and Max Start Time */
  SELECT trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  /*  Skip last entry as may be incomplete. */
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
)
select seq              snap_id,
       TO_CHAR(vdate,     'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1/24,'YYYY-MM-DD HH24:MI') end_time
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
and    ENDTIMEUTC is null
group by seq, vdate
order by seq
}';
END;
/
DEF foot = 'If this statement return lines, you may have gaps in your utilization results.<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Distinct Objects per Resource'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT "product/service",
       substr(resource_id,1,instr(resource_id,'.',1,4)-1) resource_id_pref,
       count(*) total_distinct_resources
FROM   ( select distinct "product/service", "product/resourceId" resource_id
           from OCI360_REPORTS_COST )
GROUP BY "product/service", substr(resource_id,1,instr(resource_id,'.',1,4)-1)
ORDER BY resource_id_pref,total_distinct_resources DESC
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Usage Costs - Sample lines (0.1%)'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REPORTS_COST SAMPLE(0.1) t1
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Non-OCID Resources'
DEF main_table = 'OCI360_REPORTS_COST'

BEGIN
  :sql_text := q'{
select distinct "product/service", "product/resourceId" resource_id
from   OCI360_REPORTS_COST
where  substr("product/resourceId",1,instr("product/resourceId",'.',1,1)-1) != 'ocid1'
and    "product/resourceId" is not null
}';
END;
/
DEF foot = 'Report Usage info is between &&oci360_usage_date_from. and &&oci360_usage_date_to..<br>';
@@&&9a_pre_one.

-----------------------------------------

UNDEF oci360_usage_date_from oci360_usage_date_to oci360_usage_period
UNDEF oci360_usage_tzcolformat oci360_usage_between

-----------------------------------------