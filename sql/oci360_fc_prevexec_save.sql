-- Required:
DEF oci360_in_target_table   = "&&1."
UNDEF 1

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Rename Target Table

BEGIN
  IF '&&oci360_in_target_table.' IN ('OCI360_INSTANCES','OCI360_VOLUMES','OCI360_SECLISTS')
  THEN
    EXECUTE IMMEDIATE 'DROP TABLE "&&oci360_in_target_table._PREV" PURGE';
  END IF;
EXCEPTION
  WHEN OTHERS
    THEN NULL;
END;
/

BEGIN
  IF '&&oci360_in_target_table.' IN ('OCI360_INSTANCES','OCI360_VOLUMES','OCI360_SECLISTS')
  THEN
    EXECUTE IMMEDIATE 'ALTER TABLE "&&oci360_in_target_table." RENAME TO "&&oci360_in_target_table._PREV"';
  END IF;
EXCEPTION
  WHEN OTHERS
    THEN NULL;
END;
/

UNDEF oci360_in_target_table