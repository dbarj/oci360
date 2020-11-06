whenever sqlerror exit sql.sqlcode
conn / as sysdba
alter session set container=XEPDB1;
create user OCI360 identified by "oracle";
alter user OCI360 default tablespace USERS quota unlimited on USERS;
grant CREATE SESSION, ALTER SESSION, CREATE SEQUENCE, CREATE TABLE, CREATE VIEW to OCI360;
grant SELECT on SYS.GV_$INSTANCE to OCI360;
grant SELECT on SYS.GV_$OSSTAT to OCI360;
grant SELECT on SYS.GV_$SYSTEM_PARAMETER2 to OCI360;
grant SELECT on SYS.V_$DATABASE to OCI360;
grant SELECT on SYS.V_$INSTANCE to OCI360;
grant SELECT on SYS.V_$PARAMETER to OCI360;
grant SELECT on SYS.V_$PARAMETER2 to OCI360;
grant SELECT on SYS.V_$PROCESS to OCI360;
grant SELECT on SYS.V_$SESSION to OCI360;
grant SELECT on SYS.V_$SYSTEM_PARAMETER2 to OCI360;
grant EXECUTE on SYS.DBMS_LOCK to OCI360;
grant EXECUTE on SYS.UTL_FILE to OCI360;
create directory OCI360_DIR as '/u01/oci360_tool/out/';
grant READ, WRITE on directory OCI360_DIR to OCI360;
exit