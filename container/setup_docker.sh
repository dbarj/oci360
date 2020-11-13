#!/bin/bash -x
# v1.2

######################################################
#
# This script will create 2 docker containers:
# 1 - OCI360 engine with 18c XE database.
# 2 - Apache Webserver to expose oci360 output.
#
# To execute the stable version of this script, execute the line below:
# bash -c "$(curl -L https://raw.githubusercontent.com/dbarj/oci360/Development/container/setup_docker.sh)"
#
######################################################

set -eo pipefail
set -x

trap_err ()
{
  echo "Error on line $1 of \"setup_docker.sh\"."
  exit 1
}

trap 'trap_err $LINENO' ERR

# Directory Paths
v_master_directory="/u01"
[ -n "${OCI360_ROOT_DIR}" ] && v_master_directory="${OCI360_ROOT_DIR}"

v_db_dir="${v_master_directory}/oci360_database"
v_apache_dir="${v_master_directory}/oci360_apache"

# Container names
v_oci360_con_name="oci360-tool"
v_apache_con_name="oci360-apache"

# Don't change unless asked.
v_git_branch="Development"
v_oci360_uid=54322

# Check if root
[ "$(id -u -n)" != "root" ] && echo "Must be executed as root! Exiting..." && exit 1

# Check Linux server release.
v_major_version=$(rpm -q --queryformat '%{RELEASE}' rpm | grep -o [[:digit:]]*\$)

if [ $v_major_version -lt 7 ]
then
  set +x
  echo "Linux 6 or lower does not support latest versions of Docker."
  echo "You will need to deploy OCI360 manually. Check the wiki page."
  exit 1
fi

rpm -q yum-utils || yum -y install yum-utils
rpm -q git || yum -y install git

if [ $v_major_version -eq 7 ]
then
  rpm -q docker-engine || yum -y install docker-engine
else
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  rpm -q docker-ce || yum -y install docker-ce
fi

systemctl enable docker
systemctl start docker

loop_wait_proc ()
{
  set +x
  while kill -0 "$1"
  do
    echo "$(date '+%Y%m%d_%H%M%S'): Process is still running. Please wait."
    sleep 30
  done
  set -x
}

###########################
# Docker Image for 18c XE #
###########################

if [ $v_major_version -eq 8 ]
then
  # This is required on Linux 8 to allow the docker container to communicate with the internet.
  firewall-cmd --zone=public --add-masquerade --permanent
  firewall-cmd --reload
fi

if [ "$(docker images -q oracle/database:18.4.0-xe)" == "" ]
then
  rm -rf docker-images/
  git clone https://github.com/oracle/docker-images.git
  cd docker-images/OracleDatabase/SingleInstance/dockerfiles
  ./buildDockerImage.sh -v 18.4.0 -x &
  loop_wait_proc "$!"
  cd -
  rm -rf docker-images/
else
  echo "18c XE docker image already created."
fi

docker images
docker ps -a

# Those IDs cannot be changed as they must be aligned with the docker image.
# 54321 -> User: oracle
# 54322 -> User: oci360

if ! $(getent passwd oci360 > /dev/null)
then
  useradd -u ${v_oci360_uid} -g users -G docker oci360
else
  v_oci360_uid=$(id -u oci360)
fi

rm -rf "${v_db_dir}"

mkdir -p "${v_master_directory}"
mkdir -p "${v_db_dir}/oradata/"
mkdir -p "${v_db_dir}/setup/"
chown -R 54321:54321 "${v_db_dir}"

cd "${v_db_dir}/setup/"

wget https://raw.githubusercontent.com/dbarj/oci360/${v_git_branch}/container/enable_max_string.sql
wget https://raw.githubusercontent.com/dbarj/oci360/${v_git_branch}/container/create_oci360.sql
wget https://raw.githubusercontent.com/dbarj/oci360/${v_git_branch}/container/setup_oci360.sh

cd -

docker stop ${v_oci360_con_name} || true
docker rm ${v_oci360_con_name} || true

docker run \
--name ${v_oci360_con_name} \
--restart unless-stopped \
-d \
-p 1521:1521 \
-e ORACLE_CHARACTERSET=AL32UTF8 \
-e OCI360_BRANCH=${v_git_branch} \
-e OCI360_UID=${v_oci360_uid} \
-v ${v_db_dir}/oradata:/opt/oracle/oradata \
-v ${v_db_dir}/setup:/opt/oracle/scripts/setup \
-v ${v_master_directory}:/u01 \
oracle/database:18.4.0-xe

docker logs -f ${v_oci360_con_name} &
v_pid=$!

set +x
while :
do
  v_out=$(docker logs ${v_oci360_con_name} 2>&1 >/dev/null)
  grep -qF 'DATABASE IS READY TO USE!' <<< "$v_out" && break || true
  if grep -qF 'DATABASE SETUP WAS NOT SUCCESSFUL!' <<< "$v_out" ||
     grep -qE 'Error on line [0-9]+ of "setup_oci360.sh".' <<< "$v_out"
  then
    echo "Error while creating the ${v_oci360_con_name} container. Check docker logs."
    exit 1
  fi
  echo "$(date '+%Y%m%d_%H%M%S'): Process is still running. Please wait."
  sleep 30
done
set -x

kill ${v_pid}

###########################
# Docker Image for APACHE #
###########################

rm -rf "${v_apache_dir}"
mkdir -p "${v_apache_dir}"

docker stop ${v_apache_con_name} || true
docker rm ${v_apache_con_name} || true

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

cat << 'EOF' > "${v_master_directory}/www/.htaccess"
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

chmod -R g-rwx "${v_apache_dir}"
chmod -R o-rwx "${v_apache_dir}"

touch "${v_apache_dir}/.htpasswd"

docker run \
-dit \
--name ${v_apache_con_name} \
--restart unless-stopped \
-p 443:443 \
-v "${v_master_directory}/www":/usr/local/apache2/htdocs/oci360 \
-v "${v_apache_dir}/httpd.conf":/usr/local/apache2/conf/httpd.conf \
-v "${v_apache_dir}/httpd-ssl.conf":/usr/local/apache2/conf/extra/httpd-ssl.conf \
-v "${v_apache_dir}/ssl/server.crt":/usr/local/apache2/conf/server.crt \
-v "${v_apache_dir}/ssl/server.key":/usr/local/apache2/conf/server.key \
-v "${v_apache_dir}/.htpasswd":/etc/httpd/.htpasswd \
httpd:2.4

v_http_pass="$(openssl rand -hex 6)"

docker exec -it ${v_apache_con_name} htpasswd -b /etc/httpd/.htpasswd oci360 ${v_http_pass}

chmod 644 "${v_apache_dir}/.htpasswd"

# Enable port 443
firewall-cmd --add-service=https || true
firewall-cmd --permanent --add-service=https || true

###############
# Info OCI360 #
###############

set +x

echo "
########################################
########################################

The instructions below will be saved on \"${v_master_directory}/INSTRUCTIONS.txt\".

OCI360 install/upgrade finished successfully.

To run OCI360, first setup the tenancy credentials on \"${v_master_directory}/.oci/config\" file.

Then, connect locally in this compute as oci360 user (\"sudo su - oci360\") or ROOT and test oci-cli:

[oci360@localhost ]$ docker exec -it --user oci360 ${v_oci360_con_name} bash -c 'export OCI_CLI_AUTH=instance_principal; cd /tmp/; /u01/oci360_tool/app/sh/oci_json_export.sh Comp-Instances'

If the command above produce a JSON output with all your compute instances, everything is set correctly.

Finally, call the OCI360 tool:

[oci360@localhost ]$ docker exec -it --user oci360 ${v_oci360_con_name} bash /u01/oci360_tool/scripts/oci360_run.sh

Optionally, you can add a crontab job for this collection to run every X hours (eg for 6 hours):

00 */6 * * * docker exec -it --user oci360 ${v_oci360_con_name} bash /u01/oci360_tool/scripts/oci360_run.sh

To access the OCI360 output, you can either:

- Connect on https://localhost/oci360/
 * User: oci360
 * Pass: ${v_http_pass}

- Download and open the zip file from ${v_master_directory}/oci360_tool/out/processed/

To change OCI360 website password, run:
[oci360@localhost ]$ docker exec -it ${v_apache_con_name} htpasswd -b /etc/httpd/.htpasswd oci360 *new_password*

########################################
########################################
" | tee ${v_master_directory}/INSTRUCTIONS.txt

chmod 600 ${v_master_directory}/INSTRUCTIONS.txt

exit 0
#####