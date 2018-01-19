yum install httpd -y
systemctl start http
systemctl enable http

sed  's/^\([^#]\)/#\1/g' -i /etc/httpd/conf.d/welcome.conf
touch /var/www/html/index.html
systemctl restart  httpd

yum install mariadb -y
yum install mariadb-server -y
yum install mariadb-devel -y

##In [mysqld] section of /etc/my.cnf.d/server.cnf file add
##innodb_file_per_table=1

systemctl start mariadb
systemctl enable mariadb 

yum install php -y
yum install php-mysql -y
yum install php-gd -y
yum install php-mbstring -y
yum install php-posix -y
yum install php-bcmath -y
yum install php-xml -y
yum install bison-* -y
yum install flex -y
yum install flex-devel -y
yum install unzip -y
yum install mod_ssl -y
yum install perl-Config-IniFiles -y
yum install perl-Mail-Sender -y
yum install wget -y
yum install sreen -y
yum groupinstall "Development Tools" -y

echo "date.timezone =Europe/Warsaw" >> /etc/php.ini
systemctl restart httpd

mkdir /etc/lms
touch /etc/lms/lms.ini

echo "[database]" >> /etc/lms/lms.ini
echo "type = mysql" >> /etc/lms/lms.ini
echo "host = localhost" >> /etc/lms/lms.ini
echo "user = lms" >> /etc/lms/lms.ini
echo "password = password" >> /etc/lms/lms.ini
echo "database = lms" >> /etc/lms/lms.ini

echo "[directories]" >> /etc/lms/lms.ini
echo "sys_dir          = /var/www/html/lms" >> /etc/lms/lms.ini
echo "backup_dir       = /mnt/backup/lms" >> /etc/lms/lms.ini
echo "userpanel_dir  = /var/www/html/lms/userpanel" >> /etc/lms/lms.ini


mkdir /mnt/backup
mkdir /mnt/backup/lms
chown -R 48:48 /mnt/backup/lms
chmod -R 755 /mnt/backup/lms

useradd lms
echo "lms:password" |chpasswd
chown lms.lms /var/www/html/lms

su lms -c "cd /var/www/html; git clone https://github.com/lmsgit/lms.git"
su lms -c "cd /var/www/html/lms; curl -sS https://getcomposer.org/installer | php
su lms -c "cd /var/www/html/test/lms; composer.phar install"

chown -R 48:48 /var/www/html/lms/templates_c
chmod -R 755 /var/www/html/lms/templates_c
chown -R 48:48 /var/www/html/lms/backups
chmod -R 755 /var/www/html/lms/backups
chown -R 48:48 /var/www/html/lms/documents
chmod -R 755 /var/www/html/lms/documents
chown -R 48:48 /var/www/html/lms/img/xajax_js/deferred
chmod -R 755 /var/www/html/lms/img/xajax_js/deferred
chown 48:48 /var/www/html/lms/userpanel/templates_c
chmod 755 /var/www/html/lms/userpanel/templates_c

touch /etc/httpd/conf.d/lms.conf

echo "<VirtualHost *:80>" >> /etc/httpd/conf.d/lms.conf
echo "    ServerAdmin hostmaster@example.com" >> /etc/httpd/conf.d/lms.conf
echo "    DocumentRoot /var/www/html/lms" >> /etc/httpd/conf.d/lms.conf
echo "    ServerName lms.example.com" >> /etc/httpd/conf.d/lms.conf
echo "    ErrorLog logs/lms.example.com-error_log" >> /etc/httpd/conf.d/lms.conf
echo "    CustomLog logs/lms.example.com-access_log common" >> /etc/httpd/conf.d/lms.conf
echo "</VirtualHost>" >> /etc/httpd/conf.d/lms.conf

systemctl restart httpd.service

mysql -u root -p 

CREATE DATABASE lms CHARACTER SET utf8 COLLATE utf8_polish_ci;
GRANT USAGE ON lms.* TO lms@localhost;
GRANT ALL ON lms.* TO lms@localhost IDENTIFIED BY 'password';
flush privileges;
use lms;
source /var/www/html/lms/doc/lms.mysql
exit




