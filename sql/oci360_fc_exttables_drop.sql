--
BEGIN
  IF '&&oci360_obj_dir_del.' = 'Y' and '&&oci360_loc_skip.' is NULL
  THEN
    EXECUTE IMMEDIATE 'DROP DIRECTORY "&&oci360_obj_dir."';
  END IF;
END;
/

--
BEGIN
  IF '&&oci360_clean_on_exit.' = 'ON'
  THEN
    FOR I IN (SELECT OWNER, VIEW_NAME FROM ALL_VIEWS WHERE VIEW_NAME LIKE 'OCI360|_%' ESCAPE '|' AND OWNER = SYS_CONTEXT('userenv','current_schema'))
    LOOP
      EXECUTE IMMEDIATE 'DROP VIEW ' || DBMS_ASSERT.ENQUOTE_NAME(I.OWNER) || '.' || DBMS_ASSERT.ENQUOTE_NAME(I.VIEW_NAME);
    END LOOP;
    FOR I IN (SELECT OWNER, TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME LIKE 'OCI360|_%' ESCAPE '|' AND OWNER = SYS_CONTEXT('userenv','current_schema'))
    LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || DBMS_ASSERT.ENQUOTE_NAME(I.OWNER) || '.' || DBMS_ASSERT.ENQUOTE_NAME(I.TABLE_NAME) || ' PURGE';
    END LOOP;
  END IF;
END;
/

--

DECLARE
 v_session_user   VARCHAR2(30);
 v_current_schema VARCHAR2(30);
BEGIN
  select sys_context('userenv','current_schema'),
         sys_context('userenv','session_user')
  into v_current_schema, v_session_user
  from dual;
  IF (v_session_user = 'SYS' and v_current_schema = '&&oci360_obj_schema.')
  THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA=SYS';
  END IF;
END;
/

--
UNDEF oci360_user_curschema
UNDEF oci360_user_session

-- Undef other variables
UNDEF﻿oci360_pricing_date
UNDEF oci360_pricing_url
----

UNDEF oci360_obj_dir
-- UNDEF oci360_obj_exttab - Moved to json_converter
UNDEF oci360_obj_jsoncols
UNDEF oci360_obj_jsontabs
UNDEF oci360_obj_metadata
UNDEF oci360_obj_pricing
UNDEF oci360_obj_location
UNDEF oci360_obj_shape
UNDEF oci360_obj_schema