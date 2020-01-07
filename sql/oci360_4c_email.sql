-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_EMAIL_SENDERS'
@@&&fc_json_loader. 'OCI360_EMAIL_SUPPR'
-----------------------------------------

DEF title = 'Approved senders'
DEF main_table = 'OCI360_EMAIL_SENDERS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_EMAIL_SENDERS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Email suppression'
DEF main_table = 'OCI360_EMAIL_SUPPR'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_EMAIL_SUPPR t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------