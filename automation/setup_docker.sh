#!/bin/bash -x

# To execute the latest version of this script, execute the line below instead:
# bash -x -c "$(curl -L https://raw.githubusercontent.com/dbarj/oci360/master/automation/setup_docker.sh)"
# v1.0

set -eo pipefail

v_master_directory="/u01"
v_db_dir="${v_master_directory}/oci360_database"
v_apache_dir="${v_master_directory}/oci360_apache"

yum -y install yum-utils
yum -y install docker-engine
yum -y install git

systemctl enable docker
systemctl start docker

###########################
# Docker Image for 18c XE #
###########################

rm -rf docker-images/
git clone https://github.com/oracle/docker-images.git
cd docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildDockerImage.sh -v 18.4.0 -x

docker images
docker ps

# 54321 -> User: oracle
# 54322 -> User: oci360

if ! $(getent passwd oci360 > /dev/null)
then
  useradd -u 54322 -g users -G docker oci360
fi

rm -rf "${v_db_dir}/oradata/"

mkdir -p "${v_master_directory}"
mkdir -p "${v_db_dir}/oradata/"
mkdir -p "${v_db_dir}/setup/"
chown -R 54321:54321 "${v_db_dir}"

cd "${v_db_dir}/setup/"

wget https://raw.githubusercontent.com/dbarj/oci360/v20.07/automation/enable_max_string.sql
wget https://raw.githubusercontent.com/dbarj/oci360/v20.07/automation/create_oci360.sql
wget https://raw.githubusercontent.com/dbarj/oci360/v20.07/automation/setup_oci360.sh

cd -

docker stop oci360 || true
docker rm oci360 || true

docker run --name oci360 \
-d \
-p 1521:1521 \
-e ORACLE_PWD=oracle \
-e ORACLE_CHARACTERSET=AL32UTF8 \
-v ${v_db_dir}/oradata:/opt/oracle/oradata \
-v ${v_db_dir}/setup:/opt/oracle/scripts/setup \
-v ${v_master_directory}:/u01 \
oracle/database:18.4.0-xe

docker logs -f oci360 &
v_pid=$!

while :
do
  v_out=$(docker logs oci360)
  grep -qF 'DATABASE IS READY TO USE!' <<< "$v_out" && break || true
  if $(grep -qF 'DATABASE SETUP WAS NOT SUCCESSFUL!' <<< "$v_out")
  then
    echo "Error while creating the oci360 container. Check docker logs."
    exit 1
  fi
  echo 'Waiting Database creation.'
  sleep 30
done

kill ${v_pid}

###########################
# Docker Image for APACHE #
###########################

rm -rf "${v_apache_dir}"
mkdir -p "${v_apache_dir}"

docker stop oci360-apache || true
docker rm oci360-apache || true

docker run --rm httpd:2.4 cat /usr/local/apache2/conf/httpd.conf > "${v_apache_dir}/httpd.conf"
docker run --rm httpd:2.4 cat /usr/local/apache2/conf/extra/httpd-ssl.conf > "${v_apache_dir}/httpd-ssl.conf"

cat << 'EOF' >> "${v_apache_dir}/httpd.conf"
Alias /oci360 "/usr/local/apache2/htdocs/oci360/"
<Directory "/usr/local/apache2/htdocs/oci360>
  Options +Indexes
  AllowOverride All
  Require all granted
  Order allow,deny
  Allow from all
</Directory>
EOF

cat << 'EOF' > "${v_apache_dir}/.htaccess"
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /etc/httpd/.htpasswd
Require valid-user
EOF

SERVER_NAME=oci360.example.com

sed -i "s%#ServerName www.example.com:80%ServerName ${SERVER_NAME}:80%" "${v_apache_dir}/httpd.conf"
sed -i "s%#\(Include conf/extra/httpd-ssl.conf\)%\1%" "${v_apache_dir}/httpd.conf"
sed -i "s%#\(LoadModule ssl_module modules/mod_ssl.so\)%\1%" "${v_apache_dir}/httpd.conf"
sed -i "s%#\(LoadModule socache_shmcb_module modules/mod_socache_shmcb.so\)%\1%" "${v_apache_dir}/httpd.conf"
sed -i "s%ServerName www.example.com:443%ServerName ${SERVER_NAME}:443%" "${v_apache_dir}/httpd-ssl.conf"

mkdir -p "${v_apache_dir}/ssl"

openssl req \
-x509 \
-nodes \
-days 1095 \
-newkey rsa:2048 \
-out "${v_apache_dir}/ssl/server.crt" \
-keyout "${v_apache_dir}/ssl/server.key" \
-subj "/C=BR/ST=RJ/L=RJ/O=OCI360/CN=${SERVER_NAME}"

touch "${v_apache_dir}/.htpasswd"

docker run \
-dit \
--name oci360-apache \
-p 443:443 \
-v "${v_master_directory}/www":/usr/local/apache2/htdocs/oci360 \
-v "${v_apache_dir}/httpd.conf":/usr/local/apache2/conf/httpd.conf \
-v "${v_apache_dir}/httpd-ssl.conf":/usr/local/apache2/conf/extra/httpd-ssl.conf \
-v "${v_apache_dir}/ssl/server.crt":/usr/local/apache2/conf/server.crt \
-v "${v_apache_dir}/ssl/server.key":/usr/local/apache2/conf/server.key \
-v "${v_apache_dir}/.htpasswd":/etc/httpd/.htpasswd \
httpd:2.4

v_http_pass="welcome1.$(openssl rand -hex 2)"

docker exec -it oci360-apache htpasswd -b /etc/httpd/.htpasswd oci360 ${v_http_pass}

docker stop oci360-apache
docker start oci360-apache

# Enable port 443
firewall-cmd --add-service=https
firewall-cmd --permanent --add-service=https

###############
# Call OCI360 #
###############

echo "
########################################

OCI360 install/upgrade finished successfully.

To run OCI360, first setup the tenancy credentials on ${v_master_directory}/.oci/config file.

Then, connect as oci360 user and run:

[oci360]$ docker exec -it --user oci360 oci360 bash /u01/oci360_tool/scripts/oci360_run.sh

Optionally, you can add a crontab job for this collection:

00 */6 * * * docker exec -it --user oci360 oci360 bash /u01/oci360_tool/scripts/oci360_run.sh

To access the output, you can either connect on:

- Connect on https://localhost:443/oci360/
 * User: oci360
 * Pass: welcome1

- Download and open the zip file from ${v_master_directory}/oci360_tool/out/processed/

To change OCI360 website password, run:
[oci360]$ docker exec -it oci360-apache htpasswd -b /etc/httpd/.htpasswd oci360 *new_password*

########################################
" | tee ${v_master_directory}/INSTRUCTIONS.txt

exit 0
#####