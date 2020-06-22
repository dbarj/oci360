DEF gc_lin_1  = ''
DEF gc_lin_2  = ''
DEF gc_lin_3  = ''
DEF gc_lin_4  = ''
DEF gc_lin_5  = ''
DEF gc_lin_6  = ''
DEF gc_lin_7  = ''
DEF gc_lin_8  = ''
DEF gc_lin_9  = ''
DEF gc_lin_10 = ''
DEF gc_lin_11 = ''
DEF gc_lin_12 = ''
DEF gc_lin_13 = ''
DEF gc_lin_14 = ''
DEF gc_lin_15 = ''

COL gc_lin_1  NEW_V gc_lin_1  NOPRI
COL gc_lin_2  NEW_V gc_lin_2  NOPRI
COL gc_lin_3  NEW_V gc_lin_3  NOPRI
COL gc_lin_4  NEW_V gc_lin_4  NOPRI
COL gc_lin_5  NEW_V gc_lin_5  NOPRI
COL gc_lin_6  NEW_V gc_lin_6  NOPRI
COL gc_lin_7  NEW_V gc_lin_7  NOPRI
COL gc_lin_8  NEW_V gc_lin_8  NOPRI
COL gc_lin_9  NEW_V gc_lin_9  NOPRI
COL gc_lin_10 NEW_V gc_lin_10 NOPRI
COL gc_lin_11 NEW_V gc_lin_11 NOPRI
COL gc_lin_12 NEW_V gc_lin_12 NOPRI
COL gc_lin_13 NEW_V gc_lin_13 NOPRI
COL gc_lin_14 NEW_V gc_lin_14 NOPRI
COL gc_lin_15 NEW_V gc_lin_15 NOPRI

DEF gc_flt_1  = ''
DEF gc_flt_2  = ''
DEF gc_flt_3  = ''
DEF gc_flt_4  = ''
DEF gc_flt_5  = ''
DEF gc_flt_6  = ''
DEF gc_flt_7  = ''
DEF gc_flt_8  = ''
DEF gc_flt_9  = ''
DEF gc_flt_10 = ''
DEF gc_flt_11 = ''
DEF gc_flt_12 = ''
DEF gc_flt_13 = ''
DEF gc_flt_14 = ''
DEF gc_flt_15 = ''

COL gc_flt_1  NEW_V gc_flt_1  NOPRI
COL gc_flt_2  NEW_V gc_flt_2  NOPRI
COL gc_flt_3  NEW_V gc_flt_3  NOPRI
COL gc_flt_4  NEW_V gc_flt_4  NOPRI
COL gc_flt_5  NEW_V gc_flt_5  NOPRI
COL gc_flt_6  NEW_V gc_flt_6  NOPRI
COL gc_flt_7  NEW_V gc_flt_7  NOPRI
COL gc_flt_8  NEW_V gc_flt_8  NOPRI
COL gc_flt_9  NEW_V gc_flt_9  NOPRI
COL gc_flt_10 NEW_V gc_flt_10 NOPRI
COL gc_flt_11 NEW_V gc_flt_11 NOPRI
COL gc_flt_12 NEW_V gc_flt_12 NOPRI
COL gc_flt_13 NEW_V gc_flt_13 NOPRI
COL gc_flt_14 NEW_V gc_flt_14 NOPRI
COL gc_flt_15 NEW_V gc_flt_15 NOPRI

WITH t1 AS (
  SELECT SUM("cost/myCost") COMPUTEDAMOUNT,
         &&oci360_lin_prepare_id. ITEM_ID,
         &&oci360_lin_prepare_ds. ITEM_DESC
  FROM   OCI360_REPORTS_COST
  GROUP BY &&oci360_lin_prepare_id.
  HAVING SUM("cost/myCost") > 0
), t2 as (
  SELECT /*+ materialize */
         ITEM_ID,
         ITEM_DESC,
         rank() over (order by t1.COMPUTEDAMOUNT desc, t1.ITEM_ID) ord
  FROM  t1
)
SELECT
 -- Define filters
 (select ITEM_ID FROM t2 where ord = 1)  gc_flt_1,
 (select ITEM_ID FROM t2 where ord = 2)  gc_flt_2,
 (select ITEM_ID FROM t2 where ord = 3)  gc_flt_3,
 (select ITEM_ID FROM t2 where ord = 4)  gc_flt_4,
 (select ITEM_ID FROM t2 where ord = 5)  gc_flt_5,
 (select ITEM_ID FROM t2 where ord = 6)  gc_flt_6,
 (select ITEM_ID FROM t2 where ord = 7)  gc_flt_7,
 (select ITEM_ID FROM t2 where ord = 8)  gc_flt_8,
 (select ITEM_ID FROM t2 where ord = 9)  gc_flt_9,
 (select ITEM_ID FROM t2 where ord = 10) gc_flt_10,
 (select ITEM_ID FROM t2 where ord = 11) gc_flt_11,
 (select ITEM_ID FROM t2 where ord = 12) gc_flt_12,
 (select ITEM_ID FROM t2 where ord = 13) gc_flt_13,
 (select ITEM_ID FROM t2 where ord = 14) gc_flt_14,
 (select ITEM_ID FROM t2 where ord = 15) gc_flt_15,
 -- Define names
 (select ITEM_DESC  FROM t2 where ord = 1)  gc_lin_1,
 (select ITEM_DESC  FROM t2 where ord = 2)  gc_lin_2,
 (select ITEM_DESC  FROM t2 where ord = 3)  gc_lin_3,
 (select ITEM_DESC  FROM t2 where ord = 4)  gc_lin_4,
 (select ITEM_DESC  FROM t2 where ord = 5)  gc_lin_5,
 (select ITEM_DESC  FROM t2 where ord = 6)  gc_lin_6,
 (select ITEM_DESC  FROM t2 where ord = 7)  gc_lin_7,
 (select ITEM_DESC  FROM t2 where ord = 8)  gc_lin_8,
 (select ITEM_DESC  FROM t2 where ord = 9)  gc_lin_9,
 (select ITEM_DESC  FROM t2 where ord = 10) gc_lin_10,
 (select ITEM_DESC  FROM t2 where ord = 11) gc_lin_11,
 (select ITEM_DESC  FROM t2 where ord = 12) gc_lin_12,
 (select ITEM_DESC  FROM t2 where ord = 13) gc_lin_13,
 (select ITEM_DESC  FROM t2 where ord = 14) gc_lin_14,
 (select ITEM_DESC  FROM t2 where ord = 15) gc_lin_15
FROM DUAL;

COL gc_lin_1  CLEAR
COL gc_lin_2  CLEAR
COL gc_lin_3  CLEAR
COL gc_lin_4  CLEAR
COL gc_lin_5  CLEAR
COL gc_lin_6  CLEAR
COL gc_lin_7  CLEAR
COL gc_lin_8  CLEAR
COL gc_lin_9  CLEAR
COL gc_lin_10 CLEAR
COL gc_lin_11 CLEAR
COL gc_lin_12 CLEAR
COL gc_lin_13 CLEAR
COL gc_lin_14 CLEAR
COL gc_lin_15 CLEAR

COL gc_flt_1  CLEAR
COL gc_flt_2  CLEAR
COL gc_flt_3  CLEAR
COL gc_flt_4  CLEAR
COL gc_flt_5  CLEAR
COL gc_flt_6  CLEAR
COL gc_flt_7  CLEAR
COL gc_flt_8  CLEAR
COL gc_flt_9  CLEAR
COL gc_flt_10 CLEAR
COL gc_flt_11 CLEAR
COL gc_flt_12 CLEAR
COL gc_flt_13 CLEAR
COL gc_flt_14 CLEAR
COL gc_flt_15 CLEAR

BEGIN
  :sql_text := q'{
WITH t1 AS (
  SELECT SUM("cost/myCost") COMPUTEDAMOUNT,
         TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.') ENDTIMEUTC,
         &&oci360_lin_prepare_id. ITEM_ID
  FROM   OCI360_REPORTS_COST
  GROUP BY TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.'), &&oci360_lin_prepare_id.
),
trange as (
  select trunc(min(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') min,
         trunc(max(TO_TIMESTAMP("lineItem/intervalUsageEnd",'&&oci360_usage_tzcolformat.')),'HH24') max
  FROM   OCI360_REPORTS_COST
),
allhours as ( -- Will generate all hours between Min and Max Start Time
  SELECT trange.min + (rownum - 1)/24 vdate,
         rownum seq
  FROM   trange
  WHERE  trange.min + (rownum - 1)/24 <= trange.max - 1/24  -- Skip last entry as may be incomplete.
  CONNECT BY LEVEL <= (trange.max - trange.min)*24 + 1
)
select seq              snap_id,
       TO_CHAR(vdate,  'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(vdate+1,'YYYY-MM-DD HH24:MI') end_time,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_1.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line1,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_2.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line2,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_3.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line3,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_4.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line4,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_5.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line5,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_6.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line6,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_7.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line7,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_8.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line8,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_9.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line9,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_10.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line10,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_11.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line11,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_12.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line12,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_13.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line13,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_14.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line14,
       TO_CHAR(NVL(CEIL(SUM(DECODE(ITEM_ID,'&&gc_flt_15.',COMPUTEDAMOUNT,0))*100)/100,0),'99999990D00') line15
from   t1, allhours
where  ENDTIMEUTC(+) >= vdate and ENDTIMEUTC(+)  < vdate+1/24
group by seq, vdate
order by seq
}';
END;
/

DEF tit_01 = '&&gc_lin_1.'
DEF tit_02 = '&&gc_lin_2.'
DEF tit_03 = '&&gc_lin_3.'
DEF tit_04 = '&&gc_lin_4.'
DEF tit_05 = '&&gc_lin_5.'
DEF tit_06 = '&&gc_lin_6.'
DEF tit_07 = '&&gc_lin_7.'
DEF tit_08 = '&&gc_lin_8.'
DEF tit_09 = '&&gc_lin_9.'
DEF tit_10 = '&&gc_lin_10.'
DEF tit_11 = '&&gc_lin_11.'
DEF tit_12 = '&&gc_lin_12.'
DEF tit_13 = '&&gc_lin_13.'
DEF tit_14 = '&&gc_lin_14.'
DEF tit_15 = '&&gc_lin_15.'

UNDEF gc_lin_1 gc_lin_2 gc_lin_3 gc_lin_4 gc_lin_5 gc_lin_6 gc_lin_7 gc_lin_8 gc_lin_9 gc_lin_10 gc_lin_11 gc_lin_12 gc_lin_13 gc_lin_14 gc_lin_15
UNDEF gc_flt_1 gc_flt_2 gc_flt_3 gc_flt_4 gc_flt_5 gc_flt_6 gc_flt_7 gc_flt_8 gc_flt_9 gc_flt_10 gc_flt_11 gc_flt_12 gc_flt_13 gc_flt_14 gc_flt_15

UNDEF oci360_lin_prepare_id oci360_lin_prepare_ds