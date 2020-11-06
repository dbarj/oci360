whenever sqlerror exit sql.sqlcode
conn / as sysdba
alter session set container=XEPDB1;
shutdown immediate;
startup upgrade;
alter system set MAX_STRING_SIZE='EXTENDED' scope=both;
@?/rdbms/admin/utl32k.sql
shutdown immediate;
startup;
@?/rdbms/admin/utlrp.sql
exit