-- Function that will check if passed variable in parameter 1 has the condition of parameter 2. Exit code if condition is not met.
-- Valid conditions for parameter 2 are: "Y_N", "ON_OFF", "NOT_NULL", "UPPER_CASE", "LOWER_CASE", "T_D_N", "IS_NUMBER", "RANGE"
DEF in_param = "&1."
DEF in_cond  = "&2."
UNDEF 1 2

@@&&fc_def_empty_var. 3
def in_custom = '&&3.'
undef 3

@@&&fc_def_output_file. step_file 'step_file.sql'

SPOOL &&step_file.
PRO DEF in_param_content = '&&&&in_param..'
SPOOL OFF
@&&step_file.
HOS rm -f &&step_file.
UNDEF step_file

SET TERM ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  V_VAR         VARCHAR2(30)  := '&&in_param.';
  V_VAR_CONTENT VARCHAR2(500) := '&&in_param_content.';
  V_CONDITION   VARCHAR2(10)  := '&&in_cond.';
  V_CUSTOM      VARCHAR2(500) := '&&in_custom.';
  -- For Range scan:
  V_RANGE_STR_TO_PARSE VARCHAR2(500);
  V_RANGE_COUNT NUMBER;
  V_RANGE_VALUE VARCHAR2(500);
  V_RANGE_ERROR_OUT VARCHAR2(500);
  V_RANGE_POS   NUMBER;
  V_RANGE_FOUND NUMBER := 0;
BEGIN
  IF V_CONDITION NOT IN ('Y_N','ON_OFF','NOT_NULL','UPPER_CASE','LOWER_CASE','T_D_N','IS_NUMBER','RANGE') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid 2nd parameter "' || V_CONDITION || '" on call of validate_variable function.');
  END IF;
  IF V_CONDITION = 'Y_N' AND V_VAR_CONTENT NOT IN ('Y','N') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '". Valid values are "Y" or "N".');
  END IF;
  IF V_CONDITION = 'ON_OFF' AND V_VAR_CONTENT NOT IN ('ON','OFF') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '". Valid values are "ON" or "OFF".');
  END IF;
  IF V_CONDITION = 'NOT_NULL' AND V_VAR_CONTENT IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'Variable ' || V_VAR || ' must not be NULL. Please define it on "00_config.sql" file.');
  END IF;
  IF V_CONDITION = 'UPPER_CASE' AND V_VAR_CONTENT <> UPPER(V_VAR_CONTENT) THEN
    RAISE_APPLICATION_ERROR(-20000, 'Variable ' || V_VAR || ' must be upper case. Please correct it on "00_config.sql" file.');
  END IF;
  IF V_CONDITION = 'LOWER_CASE' AND V_VAR_CONTENT <> LOWER(V_VAR_CONTENT) THEN
    RAISE_APPLICATION_ERROR(-20000, 'Variable ' || V_VAR || ' must be lower case. Please correct it on "00_config.sql" file.');
  END IF;
  IF V_CONDITION = 'T_D_N' AND V_VAR_CONTENT NOT IN ('T','D','N') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid Oracle Pack License: "' || V_VAR_CONTENT || '". Valid values are T, D or N.');
  END IF;
  IF V_CONDITION = 'IS_NUMBER' AND LENGTH(TRIM(TRANSLATE(V_VAR_CONTENT, '0123456789', ' '))) IS NOT NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'Variable ' || V_VAR || ' must be a number. Please correct it on "00_config.sql" file.');
  END IF;
  IF V_CONDITION = 'RANGE' THEN
    IF V_CUSTOM IS NULL THEN
      RAISE_APPLICATION_ERROR(-20000, 'Variable ' || V_VAR || ' range values not specified. Please correct.');
    ELSE
      V_RANGE_STR_TO_PARSE := V_CUSTOM || ',';
      V_RANGE_COUNT := LENGTH(V_RANGE_STR_TO_PARSE) - LENGTH(REPLACE(V_RANGE_STR_TO_PARSE,',',''));
      FOR I IN 1 .. V_RANGE_COUNT LOOP
        V_RANGE_POS := INSTR(V_RANGE_STR_TO_PARSE,',');
        V_RANGE_VALUE := SUBSTR(V_RANGE_STR_TO_PARSE,1,V_RANGE_POS-1);
        V_RANGE_STR_TO_PARSE := SUBSTR(V_RANGE_STR_TO_PARSE,V_RANGE_POS+1);
        V_RANGE_ERROR_OUT := V_RANGE_ERROR_OUT || ' or "' || V_RANGE_VALUE || '"';
        IF V_RANGE_VALUE = V_VAR_CONTENT THEN
          V_RANGE_FOUND := 1;
        END IF;
      END LOOP;
      IF V_RANGE_FOUND = 0 THEN
        V_RANGE_ERROR_OUT := substr(V_RANGE_ERROR_OUT,5);
        RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '". Valid values are: ' || V_RANGE_ERROR_OUT || '.');
      END IF;
    END IF;
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

UNDEF in_param in_param_content in_cond in_custom