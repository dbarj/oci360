DEF oci360_in_table_before = "&&1."
DEF oci360_in_table_after  = "&&2."
DEF oci360_in_table_file   = "&&3."

UNDEF 1 2 3

@@&&fc_spool_start.
SET SERVEROUT ON
SPO &&oci360_in_table_file.;

DECLARE

  V_TAB_B4 VARCHAR2(30) := '&&oci360_in_table_before.';
  V_TAB_AF VARCHAR2(30) := '&&oci360_in_table_after.';

  CURSOR L_ADD IS (SELECT DISTINCT ID,DISPLAY_NAME FROM &&oci360_in_table_after. T1 WHERE NOT EXISTS (SELECT 1 FROM &&oci360_in_table_before. T2 WHERE T1.ID=T2.ID));
  CURSOR L_REM IS (SELECT DISTINCT ID,DISPLAY_NAME FROM &&oci360_in_table_before. T2 WHERE NOT EXISTS (SELECT 1 FROM &&oci360_in_table_after. T1 WHERE T1.ID=T2.ID));
  CURSOR L_COLS IS (SELECT T1.COLUMN_NAME COL1, T2.COLUMN_NAME COL2
                    FROM   ALL_TAB_COLUMNS T1, ALL_TAB_COLUMNS T2
                    WHERE  T1.COLUMN_NAME = T2.COLUMN_NAME (+)
                    AND    T1.TABLE_NAME = V_TAB_AF
                    AND    T2.TABLE_NAME(+) = V_TAB_B4
                    AND    T1.COLUMN_NAME != 'ID'
                    AND    T1.OWNER = '&&oci360_user_curschema.'
                    AND    T2.OWNER(+) = '&&oci360_user_curschema.'
                    UNION ALL
                    SELECT T1.COLUMN_NAME COL1, T2.COLUMN_NAME COL2
                    FROM   ALL_TAB_COLUMNS T1, ALL_TAB_COLUMNS T2
                    WHERE  T1.COLUMN_NAME(+) = T2.COLUMN_NAME
                    AND    T1.TABLE_NAME(+) = V_TAB_AF
                    AND    T2.TABLE_NAME = V_TAB_B4
                    AND    T2.COLUMN_NAME != 'ID'
                    AND    T1.OWNER(+) = '&&oci360_user_curschema.'
                    AND    T2.OWNER = '&&oci360_user_curschema.'
                    AND    T1.COLUMN_NAME IS NULL);
  V_DYNCUR SYS_REFCURSOR;
  V_QRY VARCHAR2(2000);

  -- Fields enquotes and separators
  V_ENC VARCHAR2(1) := '"';
  V_SEP VARCHAR2(1) := ',';

  -- Hold difference results
  V_RESULT_ID     VARCHAR2(300);
  V_RESULT_DN     VARCHAR2(300);
  V_RESULT_COL_B4 VARCHAR2(4000);
  V_RESULT_COL_AF VARCHAR2(4000);

  -- Hold Column Names
  V_COL_NM VARCHAR2(128);
  V_COL1 VARCHAR2(140);
  V_COL2 VARCHAR2(140);

  V_FIRST_COL BOOLEAN := TRUE;

  FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
    OUT_VALUE   VARCHAR2(4000);
  BEGIN
    IF IN_VALUE IS NOT NULL THEN
      OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');
      IF OUT_VALUE LIKE '%' || V_ENC || '%' OR OUT_VALUE LIKE '%' || V_SEP || '%' THEN
        RETURN V_ENC || REPLACE(OUT_VALUE,V_ENC,V_ENC || V_ENC) || V_ENC;
      ELSE
        RETURN OUT_VALUE;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
  END;

  PROCEDURE PRINT (IN_ARG1 IN VARCHAR2, IN_ARG2 IN VARCHAR2, IN_ARG3 IN VARCHAR2, IN_ARG4 IN VARCHAR2, IN_ARG5 IN VARCHAR2) AS
  BEGIN
    -- IF V_FIRST_COL THEN
    --   V_FIRST_COL := FALSE;
    --   PRINT('ID','DISPLAY_NAME','COLUMN_NAME','OLD_VALUE','NEW_VALUE');
    -- END IF;
    DBMS_OUTPUT.PUT_LINE(QA(IN_ARG1) || V_SEP || QA(IN_ARG2) || V_SEP || QA(IN_ARG3) || V_SEP || QA(IN_ARG4) || V_SEP || QA(IN_ARG5));
  END;

BEGIN

  DBMS_OUTPUT.ENABLE(10000000);

  PRINT('ID','DISPLAY_NAME','COLUMN_NAME','OLD_VALUE','NEW_VALUE');

  FOR I IN L_ADD
  LOOP
    PRINT(I.ID,I.DISPLAY_NAME,'ALL','','ITEM ADDED');
  END LOOP;

  FOR I IN L_REM
  LOOP
    PRINT(I.ID,I.DISPLAY_NAME,'ALL','ITEM REMOVED','');
  END LOOP;

  FOR L IN L_COLS
  LOOP
    IF L.COL1 IS NULL THEN
      V_COL1 := 'NULL';
      V_COL2 := 'T2.' || DBMS_ASSERT.ENQUOTE_NAME('"' || L.COL2 || '"');
      V_COL_NM := L.COL2;
    ELSIF L.COL2 IS NULL THEN
      V_COL1 := 'T1.' || DBMS_ASSERT.ENQUOTE_NAME('"' || L.COL1 || '"');
      V_COL2 := 'NULL';
      V_COL_NM := L.COL1;
    ELSE
      V_COL1 := 'T1.' || DBMS_ASSERT.ENQUOTE_NAME('"' || L.COL1 || '"');
      V_COL2 := 'T2.' || DBMS_ASSERT.ENQUOTE_NAME('"' || L.COL2 || '"');
      V_COL_NM := L.COL1;
    END IF;
     V_QRY := 'SELECT DISTINCT AF.ID, T1.DISPLAY_NAME, B4.COL, AF.COL ' ||
              'FROM ' ||
              '    (SELECT T1.ID, ' ||
              '            ' || V_COL1 || ' COL ' ||
              '     FROM   ' || DBMS_ASSERT.ENQUOTE_NAME(V_TAB_AF) || ' T1, ' ||
                                DBMS_ASSERT.ENQUOTE_NAME(V_TAB_B4) || ' T2 ' ||
              '     WHERE   T1.ID=T2.ID ' ||
              '     MINUS ' ||
              '     SELECT T2.ID, ' ||
              '            ' || V_COL2 || ' COL ' ||
              '     FROM   ' || DBMS_ASSERT.ENQUOTE_NAME(V_TAB_B4) || ' T2, ' ||
                                DBMS_ASSERT.ENQUOTE_NAME(V_TAB_AF) || ' T1 ' ||
              '     WHERE  T1.ID=T2.ID) AF, ' ||
              '    (SELECT T2.ID, ' ||
              '            ' || V_COL2 || ' COL ' ||
              '     FROM   ' || DBMS_ASSERT.ENQUOTE_NAME(V_TAB_B4) || ' T2, ' ||
                                DBMS_ASSERT.ENQUOTE_NAME(V_TAB_AF) || ' T1 ' ||
              '     WHERE   T1.ID=T2.ID ' ||
              '     MINUS ' ||
              '     SELECT T1.ID, ' ||
              '            ' || V_COL1 || ' COL ' ||
              '     FROM   ' || DBMS_ASSERT.ENQUOTE_NAME(V_TAB_AF) || ' T1, ' ||
                                DBMS_ASSERT.ENQUOTE_NAME(V_TAB_B4) || ' T2 ' ||
              '     WHERE T1.ID=T2.ID) B4,                 ' ||
              '    ' || DBMS_ASSERT.ENQUOTE_NAME(V_TAB_AF) || ' T1 ' ||
              'WHERE AF.ID=B4.ID ' ||
              'AND   AF.ID=T1.ID';
     OPEN V_DYNCUR FOR V_QRY;
     LOOP
         FETCH V_DYNCUR INTO V_RESULT_ID, V_RESULT_DN, V_RESULT_COL_B4, V_RESULT_COL_AF;
         EXIT WHEN V_DYNCUR%NOTFOUND;
         PRINT(V_RESULT_ID,V_RESULT_DN,V_COL_NM,V_RESULT_COL_B4,V_RESULT_COL_AF);
     END LOOP;
  END LOOP;

  CLOSE V_DYNCUR;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(V_QRY);
    RAISE;
END;
/
SPO OFF;
@@&&fc_spool_end.

UNDEF oci360_in_table_before oci360_in_table_after oci360_in_table_file
---