-- Parse parameter configuration to check if values are compatible.
-- Associate input parameters to the variables.

SET TERM ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  V_PARAM1      VARCHAR2(30)  := '&&moat369_sw_param1.';
  V_PARAM2      VARCHAR2(30)  := '&&moat369_sw_param2.';
  V_PARAM3      VARCHAR2(30)  := '&&moat369_sw_param3.';
  V_PARAM4      VARCHAR2(30)  := '&&moat369_sw_param4.';
  V_PARAM5      VARCHAR2(30)  := '&&moat369_sw_param5.';
  V_PARAM1_VAR  VARCHAR2(30)  := '&&moat369_sw_param1_var.';
  V_PARAM2_VAR  VARCHAR2(30)  := '&&moat369_sw_param2_var.';
  V_PARAM3_VAR  VARCHAR2(30)  := '&&moat369_sw_param3_var.';
  V_PARAM4_VAR  VARCHAR2(30)  := '&&moat369_sw_param4_var.';
  V_PARAM5_VAR  VARCHAR2(30)  := '&&moat369_sw_param5_var.';
  V_TOT_LIC     NUMBER;
  V_TOT_SEC     NUMBER;
BEGIN
  SELECT DECODE(V_PARAM1,'license',1,0) +
         DECODE(V_PARAM2,'license',1,0) +
         DECODE(V_PARAM3,'license',1,0) +
         DECODE(V_PARAM4,'license',1,0) +
         DECODE(V_PARAM5,'license',1,0)
  INTO   V_TOT_LIC
  FROM   DUAL;
  SELECT DECODE(V_PARAM1,'section',1,0) +
         DECODE(V_PARAM2,'section',1,0) +
         DECODE(V_PARAM3,'section',1,0) +
         DECODE(V_PARAM4,'section',1,0) +
         DECODE(V_PARAM5,'section',1,0)
  INTO   V_TOT_SEC
  FROM   DUAL;
  IF V_PARAM2 != 'null' AND (V_PARAM1 = 'null') THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined, all prior parameters must be defined.');
  END IF;
  IF V_PARAM3 != 'null' AND (V_PARAM1 = 'null' OR V_PARAM2 = 'null') THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined, all prior parameters must be defined.');
  END IF;
  IF V_PARAM4 != 'null' AND (V_PARAM1 = 'null' OR V_PARAM2 = 'null' OR V_PARAM3 = 'null') THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined, all prior parameters must be defined.');
  END IF;
  IF V_PARAM5 != 'null' AND (V_PARAM1 = 'null' OR V_PARAM2 = 'null' OR V_PARAM3 = 'null' OR V_PARAM4 = 'null') THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined, all prior parameters must be defined.');
  END IF;
  IF V_TOT_LIC > 1 THEN
    RAISE_APPLICATION_ERROR(-20000, 'More than one input parameter defined as "license". Please correct it on "00_software.sql" file.');
  END IF;
  IF V_TOT_SEC > 1 THEN
    RAISE_APPLICATION_ERROR(-20000, 'More than one input parameter defined as "section". Please correct it on "00_software.sql" file.');
  END IF;
  IF V_PARAM1 = 'custom' AND V_PARAM1_VAR IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined as custom, you must specify the variable that will receive the value.');
  END IF;
  IF V_PARAM2 = 'custom' AND V_PARAM2_VAR IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined as custom, you must specify the variable that will receive the value.');
  END IF;
  IF V_PARAM3 = 'custom' AND V_PARAM3_VAR IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined as custom, you must specify the variable that will receive the value.');
  END IF;
  IF V_PARAM4 = 'custom' AND V_PARAM4_VAR IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined as custom, you must specify the variable that will receive the value.');
  END IF;
  IF V_PARAM5 = 'custom' AND V_PARAM5_VAR IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'When a parameter is defined as custom, you must specify the variable that will receive the value.');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

@@&&fc_def_empty_var. moat369_param1
@@&&fc_def_empty_var. moat369_param2
@@&&fc_def_empty_var. moat369_param3
@@&&fc_def_empty_var. moat369_param4
@@&&fc_def_empty_var. moat369_param5

@@&&fc_set_value_var_nvl. 'moat369_param1' '&&in_main_param1.' '&&moat369_param1.'
@@&&fc_set_value_var_nvl. 'moat369_param2' '&&in_main_param2.' '&&moat369_param2.'
@@&&fc_set_value_var_nvl. 'moat369_param3' '&&in_main_param3.' '&&moat369_param3.'
@@&&fc_set_value_var_nvl. 'moat369_param4' '&&in_main_param4.' '&&moat369_param4.'
@@&&fc_set_value_var_nvl. 'moat369_param5' '&&in_main_param5.' '&&moat369_param5.'

@@&&fc_def_empty_var. license_pack_param
@@&&fc_set_value_var_decode. 'license_pack_param' '&&moat369_sw_param1.' 'license' '&&moat369_param1.' '&&license_pack_param.'
@@&&fc_set_value_var_decode. 'license_pack_param' '&&moat369_sw_param2.' 'license' '&&moat369_param2.' '&&license_pack_param.'
@@&&fc_set_value_var_decode. 'license_pack_param' '&&moat369_sw_param3.' 'license' '&&moat369_param3.' '&&license_pack_param.'
@@&&fc_set_value_var_decode. 'license_pack_param' '&&moat369_sw_param4.' 'license' '&&moat369_param4.' '&&license_pack_param.'
@@&&fc_set_value_var_decode. 'license_pack_param' '&&moat369_sw_param5.' 'license' '&&moat369_param5.' '&&license_pack_param.'

@@&&fc_def_empty_var. sections_param
@@&&fc_set_value_var_decode. 'sections_param' '&&moat369_sw_param1.' 'section' '&&moat369_param1.' '&&sections_param.'
@@&&fc_set_value_var_decode. 'sections_param' '&&moat369_sw_param2.' 'section' '&&moat369_param2.' '&&sections_param.'
@@&&fc_set_value_var_decode. 'sections_param' '&&moat369_sw_param3.' 'section' '&&moat369_param3.' '&&sections_param.'
@@&&fc_set_value_var_decode. 'sections_param' '&&moat369_sw_param4.' 'section' '&&moat369_param4.' '&&sections_param.'
@@&&fc_set_value_var_decode. 'sections_param' '&&moat369_sw_param5.' 'section' '&&moat369_param5.' '&&sections_param.'

@@&&fc_def_output_file. step_parse_param 'step_parse_param.sql'
COL skip_parse_param NEW_V skip_parse_param NOPRI

-- Param 1
SELECT CASE WHEN '&moat369_sw_param1.' = 'custom' THEN '' ELSE '&&fc_skip_script.' END "skip_parse_param" FROM DUAL;
SPO &&step_parse_param.
PRO DEF &&moat369_sw_param1_var. = '&&moat369_param1.'
SPO OFF
@&&skip_parse_param.&&step_parse_param.

-- Param 2
SELECT CASE WHEN '&moat369_sw_param2.' = 'custom' THEN '' ELSE '&&fc_skip_script.' END "skip_parse_param" FROM DUAL;
SPO &&step_parse_param.
PRO DEF &&moat369_sw_param2_var. = '&&moat369_param2.'
SPO OFF
@&&skip_parse_param.&&step_parse_param.

-- Param 3
SELECT CASE WHEN '&moat369_sw_param3.' = 'custom' THEN '' ELSE '&&fc_skip_script.' END "skip_parse_param" FROM DUAL;
SPO &&step_parse_param.
PRO DEF &&moat369_sw_param3_var. = '&&moat369_param3.'
SPO OFF
@&&skip_parse_param.&&step_parse_param.

-- Param 4
SELECT CASE WHEN '&moat369_sw_param4.' = 'custom' THEN '' ELSE '&&fc_skip_script.' END "skip_parse_param" FROM DUAL;
SPO &&step_parse_param.
PRO DEF &&moat369_sw_param4_var. = '&&moat369_param4.'
SPO OFF
@&&skip_parse_param.&&step_parse_param.

-- Param 5
SELECT CASE WHEN '&moat369_sw_param5.' = 'custom' THEN '' ELSE '&&fc_skip_script.' END "skip_parse_param" FROM DUAL;
SPO &&step_parse_param.
PRO DEF &&moat369_sw_param5_var. = '&&moat369_param5.'
SPO OFF
@&&skip_parse_param.&&step_parse_param.

HOS rm -f &&step_parse_param.
UNDEF skip_parse_param step_parse_param

undef moat369_param1 moat369_param2 moat369_param3 moat369_param4 moat369_param5
