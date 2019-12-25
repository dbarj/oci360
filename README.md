# OCI360 #

OCI360 provides a human readable output of an OCI tenancy that allows for quick analysis of
an existing cloud estate to better optimize the use of cloud resources.
It takes around one hour to execute. Output ZIP file is usually small (~50 MBs), so
you may want to execute OCI360 from any directory with at least 1 GB of free 
space. OCI360 generated NO impact in cloud overall performance.

## How does it works ##

OCI360 will load and convert all the JSON information of your OCI tenancy into Oracle Database tables and views, creating a full metadata structure.
After the model is created on your database, it will query those tables and create reports about your OCI.

## Steps ##

1. Unzip oci360_master.zip, navigate to the root oci360_master directory, and connect as SYS, 
   DBA, or any User with Data Dictionary access:
```
$ unzip oci360_master.zip
$ cd oci360_master
$ sqlplus / as sysdba
```
2. Move the your tenancy JSONs ZIP file (created using oci_json_export.sh) to the oci360_master folder.

3. Execute OCI360.sql.
```
SQL> @oci360.sql
```
4. Unzip output oci360_YYYYMMDD_HH24MI.zip into a directory on your PC

5. Review main html file 00001_oci360_index.html

## Notes ##

1. As oci360 can run for a long time, in some systems it's recommend to execute it unattended:

   $ nohup sqlplus / as sysdba @oci360.sql &

2. If you need to execute only a portion of OCI360 (i.e. a column, section or range) use 
   these commands. Notice first parameter can be set to one section (i.e. 3b),
   one column (i.e. 3), a range of sections (i.e. 5c-6b) or range of columns (i.e. 5-7):

   SQL> @oci360.sql 3b
   
   note: valid column range for first parameter is 1 to 7. 

## Versions ##
* v1801 (2019-09-24) by Rodrigo Jorge