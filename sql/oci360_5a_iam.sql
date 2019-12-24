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