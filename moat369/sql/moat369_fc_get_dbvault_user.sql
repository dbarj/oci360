SET TERM ON
PRO
PRO Oracle Database Vault feature is enabled on this DB.
PRO If you have a license for Oracle Database Vault and want this tool to scan for issues on its configuration,
PRO please provide a username and password with access to DV_SECANALYST or DV_OWNER role.
PRO
ACCEPT dbvault_user char format a30 default '?' PROMPT "Oracle DB Vault Username: (NULL to skip check): "
ACCEPT dbvault_pass char format a30 default '?' PROMPT "Oracle DB Vault Password: (NULL to skip check): " HIDE
@@&&fc_set_term_off.

COL skip_database_vault NEW_V skip_database_vault
SELECT CASE WHEN '&&dbvault_user.' = '?' OR '&&dbvault_pass.' = '?' THEN '&&fc_skip_script.' ELSE NULL END skip_database_vault FROM DUAL;
COL skip_database_vault clear