-- @@&&fc_json_loader. 'OCI360_IMAGES'
-----------------------------------------

DEF title = 'Images'
DEF main_table = 'OCI360_IMAGES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_IMAGES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Compute Instances per Image'
DEF main_table = 'OCI360_IMAGES'

BEGIN
  :sql_text := q'{
WITH t1 as (select /*+ materialize */ * from OCI360_INSTANCES),
     t2 as (select /*+ materialize */ * from OCI360_IMAGES)
SELECT t2.id,
       t2.display_name,
       count(*) total
FROM   t1, t2
WHERE  t1.image_id=t2.id
GROUP BY t2.id, t2.display_name
ORDER BY 3 DESC
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------