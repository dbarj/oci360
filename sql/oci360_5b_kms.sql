-----------------------------------------
-- Tables Used in this Section
-----------------------------------------
@@&&fc_json_loader. 'OCI360_VAULTS'
@@&&fc_json_loader. 'OCI360_KEYS'
@@&&fc_json_loader. 'OCI360_KEY_VERSIONS'
@@&&fc_json_loader. 'OCI360_BV_KEYS'
@@&&fc_json_loader. 'OCI360_VOL_KEYS'
-----------------------------------------

DEF title = 'Vaults'
DEF main_table = 'OCI360_VAULTS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VAULTS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Keys'
DEF main_table = 'OCI360_KEYS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_KEYS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Key Versions'
DEF main_table = 'OCI360_KEY_VERSIONS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_KEY_VERSIONS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Boot-Volume Keys'
DEF main_table = 'OCI360_BV_KEYS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_BV_KEYS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Volume Keys'
DEF main_table = 'OCI360_VOL_KEYS'

BEGIN
  :sql_text := q'{
SELECT t1.*
FROM   OCI360_VOL_KEYS t1
}';
END;
/
@@&&9a_pre_one.

-----------------------------------------