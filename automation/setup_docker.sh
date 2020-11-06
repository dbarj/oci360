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

docker exec -it --user oci360 oci360 bash /u01/oci360_tool/scripts/oci360_run.sh

###########################
# Docker Image for APACHE #
###########################

docker stop oci360-apache || true
docker rm oci360-apache || true

docker run --rm httpd:2.4 cat /usr/local/apache2/conf/httpd.conf > ${v_apache_dir}/httpd.conf

docker run \
-dit \
--name oci360-apache \
-p 80:80 \
-p 443:443 \
-v "${v_master_directory}/www":/usr/local/apache2/htdocs/ \
-v "${v_apache_dir}/apache2/ssl":/etc/apache2/ssl \
httpd:2.4

mkdir -p ${v_apache_dir}/apache2/ssl
openssl req -x509 -nodes -days 1095 -newkey rsa:2048 -out ${v_apache_dir}/apache2/ssl/server.crt -keyout ${v_apache_dir}/apache2/ssl/server.key

COPY cert.pem /usr/local/apache2/conf/server.crt
COPY key.pem /usr/local/apache2/conf/server.key

EXPOSE 443

SERVER_NAME=oci360.example.com


sed -i "s%#ServerName www.example.com:80%ServerName ${SERVER_NAME}:80%" conf/httpd.conf
sed -i "s%#\(Include conf/extra/httpd-ssl.conf\)%\1%" conf/httpd.conf
sed -i "s%#\(LoadModule ssl_module modules/mod_ssl.so\)%\1%" conf/httpd.conf
sed -i "s%#\(LoadModule socache_shmcb_module modules/mod_socache_shmcb.so\)%\1%" conf/httpd.conf
sed -i "s%ServerName www.example.com:443%ServerName ${SERVER_NAME}:443%" conf/extra/httpd-ssl.conf


a2enmod ssl

# Enable port 80 and 443
firewall-cmd --add-service=http
firewall-cmd --add-service=https
firewall-cmd --permanent --add-service=http

crontab -l > mycron
echo '00 */6 * * * docker exec -it --user oci360 oci360 bash /u01/oci360_tool/scripts/oci360_run.sh' >> mycron
crontab mycron
rm -f mycron

exit 0
#####