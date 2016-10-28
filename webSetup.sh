#!/bin/bash


if ($# -ne 2) 
then
	`echo please enter your desired site name`
	exit 0
fi
siteName=$2

MYSQL=$(dpkg -l | grep mysql-server)
NGINX=$(dpkg -l | grep nginx)
PHP=$(dpkg -l | grep php-fpm)

MYSQLPASS="wp123"
MYSQLDATABASE="wordpress"
SERVERNAMEORIP="example.com"

#you may need to enter a password for mysql-server
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQLPASS}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQLPASS}"



if [ -z "$MYSQL" ]
then

echo "Installing Mysql Server" 
`apt-get install -y python3 mariadb-server mariadb-client`
echo "Mysql Server has been installed"
/etc/init.d/mysql start

fi

if [ -z "$NGINX" ]
then

echo "Installing NGINX Server"
`apt-get install -y nginx`
echo "Installed NGINX Server"
/etc/init.d/nginx start

fi

if [ -z "$PHP" ]
then

echo "Installing PHP Server"
`apt-get install -y php-fpm php-mysql`
echo "Installed PHP Server"
fi

#read -p "Please enter your site name: " siteName

echo "127.0.0.1 $siteName" >> /etc/hosts

nginxRoot="/usr/share/nginx/html/$siteName"
nginxVHerror="$siteName".error;
nginxVHaccess="$siteName".access;
nginxConf="server { \n
	\n
        listen 80;\n
        root /usr/share/nginx/html/$siteName;\n
        index index.php index.html index.htm;\n
        server_name $siteName;\n
	\n
 	access_log /var/log/nginx/$nginxVHaccess;\n
        error_log /var/log/nginx/$nginxVHerror error;\n
        location / {\n
        	try_files \$uri \$uri/ /index.php?q=\$uri&\$args;\n
	}\n
	\n
	
	location ~ \.php$ {\n
	try_files \$uri=404;\n
        include snippets/fastcgi-php.conf;\n
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;\n
    }

}\n"


sed -i "s/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s/^;listen.owner = www-data/listen.owner = www-data/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/^;listen.group = www-data/listen.group = www-data/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/^;listen.mode = 0660/listen.mode = 0660/" /etc/php5/fpm/pool.d/www.conf

/etc/init.d/php7.0-fpm start


`touch /etc/nginx/sites-available/$siteName.conf && echo -e $nginxConf >> /etc/nginx/sites-available/$siteName.conf && ln -s /etc/nginx/sites-available/$siteName.conf /etc/nginx/sites-enabled/$siteName.conf`

`wget -O /tmp/wordpress.zip https://wordpress.org/latest.zip && unzip -q /tmp/wordpress.zip -d  /tmp/ && mv /tmp/wordpress /usr/share/nginx/html/$siteName`

PASSWDDB="$(openssl rand -base64 12)"

mainDB="$siteName"_db
mainDB_user="$siteName"_user

mysql -uroot -p$MYSQLPASS -e "CREATE DATABASE \`$mainDB\`"
mysql -uroot -p$MYSQLPASS -e "CREATE USER \`$mainDB_user\`@localhost IDENTIFIED BY '$PASSWDDB'"
mysql -uroot -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON \`$mainDB\`.* TO \`$mainDB_user\`@localhost IDENTIFIED BY '$PASSWDDB'"
mysql -uroot -p$MYSQLPASS -e "FLUSH PRIVILEGES"

db_old="define('DB_NAME', 'database_name_here');"
user_old="define('DB_USER', 'username_here');"
passwd_old="define('DB_PASSWORD', 'password_here');"

db_new="define( 'DB_NAME', '"$mainDB"' );"
user_new="define( 'DB_USER', '"$mainDB_user"' );"
passwd_new="define( 'DB_PASSWORD', '"$PASSWDDB"' );"


`sed -i  -e "s/$db_old/$db_new/" -e "s/$user_old/$user_new/" -e "s/$passwd_old/$passwd_new/" ""$nginxRoot"/wp-config-sample.php" && mv ""$nginxRoot"/wp-config-sample.php" ""$nginxRoot"/wp-config.php"`


`/usr/sbin/nginx -s reload`
