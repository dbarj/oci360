-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_USAGECOSTS'
@@&&fc_json_loader. 'OCI360_SERV_ENTITLEMENTS'
@@&&fc_json_loader. 'OCI360_SERV_RESOURCES'
@@&&fc_json_loader. 'OCI360_ACCOUNTDETAILS'
@@&&fc_json_loader. 'OCI360_USAGECOSTS_TAGGED_DAILY'
@@&&fc_json_loader. 'OCI360_USAGETAGS'
@@&&fc_json_loader. 'OCI360_USAGE'
@@&&fc_json_loader. 'OCI360_CHECKQUOTA'
@@&&fc_json_loader. 'OCI360_PROMOTIONS'
@@&&fc_json_loader. 'OCI360_CLOUDLIMITS'
-----------------------------------------

--- Get some Billing info before starting
@@&&fc_def_empty_var. oci360_billing_currency
@@&&fc_def_empty_var. oci360_billing_date_from
@@&&fc_def_empty_var. oci360_billing_date_to
@@&&fc_def_empty_var. oci360_billing_period

COL oci360_billing_currency NEW_V oci360_billing_currency NOPRI
SELECT distinct CURRENCY oci360_billing_currency
from   OCI360_USAGECOSTS;
COL oci360_billing_currency CLEAR

COL oci360_billing_date_from NEW_V oci360_billing_date_from NOPRI
COL oci360_billing_date_to   NEW_V oci360_billing_date_to   NOPRI
COL oci360_billing_period    NEW_V oci360_billing_period    NOPRI
SELECT TO_CHAR(min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'YYYY-MM-DD') oci360_billing_date_from,
       TO_CHAR(max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'YYYY-MM-DD') oci360_billing_date_to,
       EXTRACT(DAY FROM (max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')) - min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')))) oci360_billing_period
from   OCI360_USAGECOSTS;
COL oci360_billing_date_from CLEAR
COL oci360_billing_date_to   CLEAR
COL oci360_billing_period    CLEAR

DEF oci360_billing_between = ', between &&oci360_billing_date_from. and &&oci360_billing_date_to.'

-----------------------------------------

DEF title = 'Service Entitlements'
DEF main_table = 'OCI360_SERV_ENTITLEMENTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_SERV_ENTITLEMENTS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Service Resources'
DEF main_table = 'OCI360_SERV_RESOURCES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_SERV_RESOURCES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Resources Unit Prices'
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
select   distinct
         TO_CHAR(CEIL(COSTS$UNITPRICE*10000)/10000,'999G990D0000') UNITPRICE, -- CEIL * 10000 / 10000 is same as ROUNG UP in 4th digit
         COSTS$OVERAGESFLAG OVERAGESFLAG,
         CURRENCY,
         SERVICENAME,
         GSIPRODUCTID,
         RESOURCENAME,
         SUBSCRIPTIONID,
         SUBSCRIPTIONTYPE,
         DATACENTERID,
         SERVICEENTITLEMENTID
from     OCI360_USAGECOSTS
order by SERVICENAME, RESOURCENAME
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cost division per Service'
DEF title_suffix = '&&oci360_billing_between.';
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
WITH t1 AS (
SELECT COSTS$COMPUTEDAMOUNT COMPUTEDAMOUNT,
       SERVICENAME,
       CURRENCY
FROM   OCI360_USAGECOSTS ),
t2 as (select sum(COMPUTEDAMOUNT) total_global from t1)
SELECT t1.SERVICENAME || ' - ' || t1.CURRENCY || ' ' || round(sum(COMPUTEDAMOUNT)) SERVICENAME,
       round(sum(COMPUTEDAMOUNT)) total,
       trim(to_char(round(sum(COMPUTEDAMOUNT)/decode(total_global,0,1,total_global),4)*100,'990D99')) percent
FROM   t1, t2
GROUP BY t1.SERVICENAME,t1.CURRENCY,total_global
having sum(COMPUTEDAMOUNT) <> 0
order by total desc
}';
END;
/
DEF skip_pch = ''
DEF foot = 'Total for &&oci360_billing_period. days period.';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cost division per Resource'
DEF title_suffix = '&&oci360_billing_between.';
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
WITH t1 AS (
SELECT COSTS$COMPUTEDAMOUNT COMPUTEDAMOUNT,
       SERVICENAME,
       RESOURCENAME,
       CURRENCY
FROM   OCI360_USAGECOSTS ),
t2 as (select sum(COMPUTEDAMOUNT) total_global from t1)
SELECT t1.SERVICENAME || ' - ' || t1.RESOURCENAME || ' - ' || t1.CURRENCY || ' ' || round(sum(COMPUTEDAMOUNT)) SERVICENAME,
       round(sum(COMPUTEDAMOUNT)) total,
       trim(to_char(round(sum(COMPUTEDAMOUNT)/decode(total_global,0,1,total_global),4)*100,'990D99')) percent
FROM   t1, t2
GROUP BY t1.SERVICENAME,t1.RESOURCENAME,t1.CURRENCY,total_global
having sum(COMPUTEDAMOUNT) <> 0
order by total desc
}';
END;
/
DEF skip_pch = ''
DEF foot = 'Total for &&oci360_billing_period. days period.';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Used Quota'
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
WITH trange as (
  select /*+ materialize */ trunc(min(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')),'HH24') max
  FROM   OCI360_USAGECOSTS
),
t1 AS (
  SELECT /*+ materialize */ SUM(COSTS$COMPUTEDAMOUNT) COMPUTEDAMOUNT,
         TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') TIMEUTC
  FROM   OCI360_USAGECOSTS
  GROUP BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.')
),
tcycle AS (
  SELECT /*+ materialize */ PURCHASE$PURCHASEDRESOURCES$VALUE PURCHASEDRESOURCES,
         TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$STARTDATE,'&&oci360_tzcolformat.') STARTDATE,
         TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$ENDDATE,'&&oci360_tzcolformat.') ENDDATE
  FROM   OCI360_ACCOUNTDETAILS, trange
  WHERE  PURCHASE$ID is not null
    AND  PURCHASE$PURCHASEDRESOURCES$NAME = 'CLOUD_CREDIT_AMOUNT'
    AND  TO_TIMESTAMP(PURCHASE$PURCHASEDRESOURCES$STARTDATE,'&&oci360_tzcolformat.') > trange.min
),
allhours as ( -- Will generate all hours between Min and Max Start Time
  SELECT /*+ materialize */ trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24 -- Skip last hour as can be an incompleted current hour.
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
)
select seq              snap_id,
       TO_CHAR(vdate,     'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1/24,'YYYY-MM-DD HH24:MI') end_time,
       TO_CHAR(CEIL(tcycle.PURCHASEDRESOURCES*100)/100,'99999990D00')  line1,
       TO_CHAR(CEIL(SUM(t1.COMPUTEDAMOUNT)*100)/100,'99999990D00') line2,
       0                   dummy_03,
       0                   dummy_04,
       0                   dummy_05,
       0                   dummy_06,
       0                   dummy_07,
       0                   dummy_08,
       0                   dummy_09,
       0                   dummy_10,
       0                   dummy_11,
       0                   dummy_12,
       0                   dummy_13,
       0                   dummy_14,
       0                   dummy_15
from   t1, tcycle, allhours
WHERE  vdate between tcycle.STARTDATE AND tcycle.ENDDATE -- For each hour frame I get the billing period range
AND    t1.TIMEUTC >= tcycle.STARTDATE AND t1.TIMEUTC < vdate+1/24 -- The Billing end time must be inside the range until the computed hour
group by seq, vdate, PURCHASEDRESOURCES
order by seq
}';
END;
/

DEF tit_01 = 'Total Available'
DEF tit_02 = 'Total Used'
DEF vaxis = 'Cost (&&oci360_billing_currency.)'
DEF chartype = 'AreaChart'

DEF skip_lch = ''
@@&&9a_pre_one.

-----------------------------------------

DEF max_rows = 1000
DEF title = 'Computed Usage Costs - Last &&max_rows. lines'
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
SELECT   t1.*
FROM     OCI360_USAGECOSTS t1
ORDER BY TO_TIMESTAMP(LASTCOMPUTATIONDATE,'&&oci360_tzcolformat.') DESC FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF max_rows = 1000
DEF title = 'Computed Usage Costs Tagged - Last &&max_rows. lines'
DEF main_table = 'OCI360_USAGECOSTS_TAGGED_DAILY'

BEGIN
  :sql_text := q'{
SELECT   t1.*
FROM     OCI360_USAGECOSTS_TAGGED_DAILY t1
ORDER BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') DESC FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF max_rows = 1000
DEF title = 'Computed Usage - Last &&max_rows. lines'
DEF main_table = 'OCI360_USAGE'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_USAGE t1
ORDER BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') DESC FETCH NEXT &&max_rows. ROWS ONLY
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Usage Tags'
DEF main_table = 'OCI360_USAGETAGS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_USAGETAGS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Account Details'
DEF main_table = 'OCI360_ACCOUNTDETAILS'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       PAYG,
       STATUS,
       PROMOTION,
       SOFTLIMIT,
       BILLINGTYPE,
       HARDLIMITALL,
       HARDLIMITNEW,
       CANONICALLINK,
       ENTITLEMENTID,
       CLOUDBUCKSTYPE,
       OVERAGESALLOWED,
       SUBSCRIPTIONTYPE,
       SUBSCRIPTIONCATEGORY
FROM   OCI360_ACCOUNTDETAILS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Account Balance'
DEF main_table = 'OCI360_ACCOUNTDETAILS'

BEGIN
  :sql_text := q'{
SELECT BALANCE$ID,
       BALANCE$CREATEDON,
       BALANCE$PURCHASEDRESOURCES$NAME,
       BALANCE$PURCHASEDRESOURCES$UNIT,
       BALANCE$PURCHASEDRESOURCES$VALUE,
       BALANCE$PURCHASEDRESOURCES$DERIVED,
       BALANCE$PURCHASEDRESOURCES$CREATEDON,
       BALANCE$PURCHASEDRESOURCES$MODIFIEDON
FROM   OCI360_ACCOUNTDETAILS t1
WHERE  BALANCE$ID is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Account Purchase'
DEF main_table = 'OCI360_ACCOUNTDETAILS'

BEGIN
  :sql_text := q'{
SELECT   PURCHASE$ID,
         PURCHASE$CREATEDON,
         PURCHASE$SOFTLIMIT,
         PURCHASE$HARDLIMITALL,
         PURCHASE$HARDLIMITNEW,
         PURCHASE$OVERAGESALLOWED,
         PURCHASE$PURCHASEDRESOURCES$NAME,
         PURCHASE$PURCHASEDRESOURCES$UNIT,
         PURCHASE$PURCHASEDRESOURCES$VALUE,
         PURCHASE$PURCHASEDRESOURCES$ENDDATE,
         PURCHASE$PURCHASEDRESOURCES$CREATEDON,
         PURCHASE$PURCHASEDRESOURCES$STARTDATE,
         PURCHASE$PURCHASEDRESOURCES$PURCHASETYPE
FROM     OCI360_ACCOUNTDETAILS t1
WHERE    PURCHASE$ID is not null
ORDER BY PURCHASE$PURCHASEDRESOURCES$STARTDATE ASC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Account Running Balance'
DEF main_table = 'OCI360_ACCOUNTDETAILS'

BEGIN
  :sql_text := q'{
SELECT RUNNINGBALANCE$ID,
       RUNNINGBALANCE$CREATEDON,
       RUNNINGBALANCE$PURCHASEDRESOURCES$NAME,
       RUNNINGBALANCE$PURCHASEDRESOURCES$UNIT,
       RUNNINGBALANCE$PURCHASEDRESOURCES$VALUE,
       RUNNINGBALANCE$PURCHASEDRESOURCES$DERIVED,
       RUNNINGBALANCE$PURCHASEDRESOURCES$CREATEDON,
       RUNNINGBALANCE$PURCHASEDRESOURCES$MODIFIEDON,
       RUNNINGBALANCE$PURCHASEDRESOURCES$PURCHASETYPE
FROM   OCI360_ACCOUNTDETAILS t1
WHERE  RUNNINGBALANCE$ID is not null
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Check Quota'
DEF main_table = 'OCI360_CHECKQUOTA'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CHECKQUOTA t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Promotions'
DEF main_table = 'OCI360_PROMOTIONS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_PROMOTIONS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Cloud Limits'
DEF main_table = 'OCI360_CLOUDLIMITS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CLOUDLIMITS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Raw Computed Usage Costs Tagged'
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
SELECT   t1.*
FROM     OCI360_USAGECOSTS_TAGGED_DAILY t1
ORDER BY TO_TIMESTAMP(ENDTIMEUTC,'&&oci360_tzcolformat.') DESC
}';
END;
/
DEF max_rows = 1000000
DEF skip_csv = ''
DEF skip_html = '--'
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Raw Computed Usage Costs'
DEF main_table = 'OCI360_USAGECOSTS'

BEGIN
  :sql_text := q'{
SELECT   t1.*
FROM     OCI360_USAGECOSTS t1
ORDER BY TO_TIMESTAMP(LASTCOMPUTATIONDATE,'&&oci360_tzcolformat.') DESC
}';
END;
/
DEF max_rows = 1000000
DEF skip_csv = ''
DEF skip_html = '--'
@@&&9a_pre_one.

-----------------------------------------
UNDEF oci360_billing_currency oci360_billing_date_from oci360_billing_date_to oci360_billing_period