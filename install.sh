#!/bin/bash

#  Author : Dariusz Kowalczyk
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License Version 2 as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#####config###
enable_ssl=no

FQDN=lms.example.com
userpanelFQDN=boa.example.com
WEBMASTER_EMAIL=hostmaster@example.com
LMS_DIR=/var/www/html/lms

backup_dir=/mnt/backup/lms

shell_user=lms
shell_group=lms
shell_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)

lms_db_host=localhost
lms_db_user=lms
lms_db_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
lms_db=lms

#####install#####
yum install httpd -y

sed  's/^\([^#]\)/#\1/g' -i /etc/httpd/conf.d/welcome.conf
touch /var/www/html/index.html

yum install mariadb -y
yum install mariadb-server -y
yum install mariadb-devel -y

cat <<EOF > /etc/my.cnf.d/server.cnf
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]

innodb_file_per_table=1

# this is only for embedded server
[embedded]

# This group is only read by MariaDB-5.5 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mysqld-5.5]

# These two groups are only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

[mariadb-5.5]
EOF

systemctl start mariadb
systemctl enable mariadb 

yum install bison-* -y
yum install flex -y
yum install flex-devel -y
yum install unzip -y
yum install mod_ssl -y
yum install perl-Config-IniFiles -y
yum install perl-Mail-Sender -y
yum install wget -y
yum install policycoreutils-python -y
yum install setroubleshoot -y 
yum install epel-release -y 
yum install python-certbot-apache -y
yum groupinstall "Development Tools" -y

yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum install yum-utils -y
yum-config-manager --enable remi-php73   [Install PHP 7.3]
yum install php -y
yum install php-mysql -y
yum install php-gd -y
yum install php-mbstring -y
yum install php-posix -y
yum install php-bcmath -y
yum install php-xml -y
yum install php-imap -y
yum install php-soap -y
yum install php-pecl-zip libzip5 -y

echo "date.timezone =Europe/Warsaw" >> /etc/php.ini

mkdir /etc/lms

cat <<EOF > /etc/lms/lms.ini
[database]
type = mysql
host = $lms_db_host
user = $lms_db_user
password = $lms_db_password
database = $lms_db

[directories]
sys_dir = $LMS_DIR
backup_dir = $backup_dir
userpanel_dir = $LMS_DIR/userpanel
EOF

mkdir -p $backup_dir
chown -R 48:48 $backup_dir
chmod -R 755 $backup_dir

useradd $shell_user
echo "$shell_user:$shell_password" |chpasswd
mkdir $LMS_DIR
chown $shell_user.$shell_group $LMS_DIR

su $shell_user -c "cd /var/www/html; git clone https://github.com/lmsgit/lms.git"
su $shell_user -c "cd $LMS_DIR; curl -sS https://getcomposer.org/installer | php"
su $shell_user -c "cd $LMS_DIR; $LMS_DIR/composer.phar install"

chown -R 48:48 $LMS_DIR/templates_c
chmod -R 755 $LMS_DIR/templates_c
chown -R 48:48 $LMS_DIR/backups
chmod -R 755 $LMS_DIR/backups
chown -R 48:48 $LMS_DIR/documents
chmod -R 755 $LMS_DIR/documents
#chown -R 48:48 $LMS_DIR/img/xajax_js/deferred
#chmod -R 755 $LMS_DIR/img/xajax_js/deferred
chown 48:48 $LMS_DIR/userpanel/templates_c
chmod 755 $LMS_DIR/userpanel/templates_c

mkdir -p $LMS_DIR/img/xajax_js/deferred
chown -R 48:48 $LMS_DIR/img/xajax_js/deferred
chmod -R 755 $LMS_DIR/img/xajax_js/deferred
mkdir -p $LMS_DIR/js/xajax_js/deferred
chown -R 48:48 $LMS_DIR/js/xajax_js/deferred
chmod -R 755 $LMS_DIR/js/xajax_js/deferred


cat <<EOF > /etc/httpd/conf.d/lms.conf
<VirtualHost *:80>
ServerAdmin $WEBMASTER_EMAIL
DocumentRoot /var/www/html/lms
ServerName $FQDN
ErrorLog logs/$FQDN-error_log
CustomLog logs/$FQDN-access_log common
</VirtualHost>
EOF

cat <<EOF > /etc/httpd/conf.d/userpanel.conf
<VirtualHost *:80>
ServerAdmin $WEBMASTER_EMAIL
DocumentRoot /var/www/html/lms/userpanel
ServerName $userpanelFQDN
ErrorLog logs/$userpanelFQDN-error_log
CustomLog logs/$userpanelFQDN-access_log common
</VirtualHost>
EOF

mysql -u root -e "CREATE DATABASE $lms_db CHARACTER SET utf8 COLLATE utf8_polish_ci;"
mysql -u root -e "GRANT USAGE ON $lms_db.* TO $lms_db_user@$lms_db_host;"
mysql -u root -e "GRANT ALL ON $lms_db.* TO $lms_db_user@$lms_db_host IDENTIFIED BY '$lms_db_password';"
mysql -u root -e "flush privileges;"
mysql -u root -e "use $lms_db; source $LMS_DIR/doc/lms.mysql;"

mysql_secure_installation

systemctl restart httpd.service
systemctl enable httpd.service

firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --permanent --add-service=http

selinux_status=$(getenforce)

if [ $selinux_status == Enforcing ]
then
  wget http://127.0.0.1
  wget http://$FQDN
  ausearch -c 'httpd' --raw | audit2allow -M my-httpd
  semodule -i my-httpd.pp
fi

if [ $enable_ssl == yes ]
then
  certbot --apache -d $FQDN
  systemctl restart httpd.service
  firewall-cmd --zone=public --add-service=https
  firewall-cmd --zone=public --permanent --add-service=https
else
  echo "If you want using SSL encryption later, run:"
  echo 
  echo "certbot --apache -d $FQDN"
  echo "systemctl restart httpd.service"
  echo "firewall-cmd --zone=public --add-service=https"
  echo "firewall-cmd --zone=public --permanent --add-service=https"
fi

echo
echo "LMS DIR $LMS_DIR"
echo "LMS shell user account: $shell_user"
echo "LMS shell user password: $shell_password" 
echo ""
