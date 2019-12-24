# OCI360 #

OCI360 provides a human readable output of an OCI tenancy that allows for quick analysis of
an existing cloud estate to better optimize the use of cloud resources.
It takes around one hour to execute. Output ZIP file is usually small (~10 MBs), so
you may want to execute OCI360 from any directory with at least 1 GB of free 
space. OCI360 generated NO impact in cloud overall performance.

## Steps ##

1. Unzip oci360_master.zip, navigate to the root oci360_master directory, and connect as SYS, 
   DBA, or any User with Data Dictionary access:

   $ unzip oci360_master.zip
   $ cd oci360_master
   $ sqlplus / as sysdba

2. Execute OCI360.sql.

   SQL> @oci360.sql
   
3. Unzip output OCI360_<dbname>_<host>_YYYYMMDD_HH24MI.zip into a directory on your PC

4. Review main html file 00001_oci360_<dbname>_index.html

## Notes ##

1. As oci360 can run for a long time, in some systems it's recommend to execute it unattended:

   $ nohup sqlplus / as sysdba @oci360.sql &

2. If you need to execute OCI360 against all databases in host use then oci360.sh:

   $ unzip oci360.zip
   $ cd oci360
   $ sh oci360.sh
   
   note: using this script a password will be requested to zip the files.

3. If you need to execute only a portion of OCI360 (i.e. a column, section or range) use 
   these commands. Notice first parameter can be set to one section (i.e. 3b),
   one column (i.e. 3), a range of sections (i.e. 5c-6b) or range of columns (i.e. 5-7):

   SQL> @oci360.sql 3b
   
   note: valid column range for first parameter is 1 to 7. 

4. If the output file is encrypted, you need to decrypt it using openssl:

   $ openssl smime -decrypt -binary -in "encrypted_output_file" -inform DER -out "decrypted_zip_file" -inkey "private_key_file"

5. If the html file is encrypted and asks for a password, you need to get the key decrypting the "key.bin.enc" file inside the zip:

   $ openssl rsautl -decrypt -inkey "private_key_file" -in key.bin.enc

## Versions ##
* v1801 (2019-09-24) by Rodrigo Jorge