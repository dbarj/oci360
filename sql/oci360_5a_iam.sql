-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_table_loader. 'OCI360_USERS'
@@&&fc_table_loader. 'OCI360_USER_GROUPS'
@@&&fc_table_loader. 'OCI360_GROUPS'
@@&&fc_table_loader. 'OCI360_DYN_GROUPS'
@@&&fc_table_loader. 'OCI360_POLICIES'
@@&&fc_table_loader. 'OCI360_AUTH_TOKEN'
@@&&fc_table_loader. 'OCI360_SMTP_CREDENTIALS'
@@&&fc_table_loader. 'OCI360_CUSTOMER_KEY'
@@&&fc_table_loader. 'OCI360_REGIONS'
@@&&fc_table_loader. 'OCI360_TAGS'
@@&&fc_table_loader. 'OCI360_TAG_NAMESPACES'
@@&&fc_table_loader. 'OCI360_IAM_WORKREQS'
-----------------------------------------

DEF title = 'Users'
DEF main_table = 'OCI360_USERS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_USERS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'User Groups'
DEF main_table = 'OCI360_USER_GROUPS'

BEGIN
  :sql_text := q'{
SELECT T2.NAME USER_NAME,
       T2.DESCRIPTION USER_DESCRIPTION,
       T1.NAME GROUP_NAME,
       T1.DESCRIPTION GROUP_DESCRIPTION,
       T2.ID USER_ID,
       T1.ID GROUP_ID
FROM   OCI360_USER_GROUPS t1, OCI360_USERS t2
WHERE  t1.user_id=t2.id
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Groups'
DEF main_table = 'OCI360_GROUPS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_GROUPS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Dynamic Groups'
DEF main_table = 'OCI360_DYN_GROUPS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_DYN_GROUPS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Policies'
DEF main_table = 'OCI360_POLICIES'

BEGIN
  :sql_text := q'{
SELECT distinct
       ID,
       NAME,
       DESCRIPTION,
       TIME_CREATED,
       VERSION_DATE,
       COMPARTMENT_ID,
       INACTIVE_STATUS,
       LIFECYCLE_STATE
FROM   OCI360_POLICIES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Policy Statements'
DEF main_table = 'OCI360_POLICIES'

BEGIN
  :sql_text := q'{
SELECT ID,
       NAME,
       STATEMENTS
FROM   OCI360_POLICIES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Users Auth Tokes'
DEF main_table = 'OCI360_AUTH_TOKEN'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_AUTH_TOKEN t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Users SMTP Credentials'
DEF main_table = 'OCI360_SMTP_CREDENTIALS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_SMTP_CREDENTIALS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Users Secret Keys'
DEF main_table = 'OCI360_CUSTOMER_KEY'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_CUSTOMER_KEY t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'All Regions'
DEF main_table = 'OCI360_REGIONS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_REGIONS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Tags'
DEF main_table = 'OCI360_TAGS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_TAGS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Tag Namespaces'
DEF main_table = 'OCI360_TAG_NAMESPACES'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_TAG_NAMESPACES t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Work Requests'
DEF main_table = 'OCI360_IAM_WORKREQS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_IAM_WORKREQS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------