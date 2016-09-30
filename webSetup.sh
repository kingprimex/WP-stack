#!/bin/bash

MYSQL=$(dpkg -l | grep mysql-server)
NGINX=$(dpkg -l | grep nginx)
PHP=$(dpkg -l | grep php-fpm)



if [ -z "$MYSQL" ]
then

`apt-get install -y python3 mysql-server`

fi

if [ -z "$NGINX" ]
then

`apt-get install -y nginx`

fi

if [ -z "$PHP" ]
then

`apt-get install -y php-fpm php-mysql`

fi

read -p "Please enter your site name: " siteName

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
 	access_log logs/$nginxVHaccess;
        error_log logs/$nginxVHerror error;
        location / {\n
        	try_files $uri $uri/ /index.php?q=$uri&$args;
	}\n
	\n
	location ~ \.php$ {\n
                try_files $uri =404;\n
                fastcgi_split_path_info ^(.+\.php)(/.+)$;\n
                fastcgi_pass unix:/var/run/php5-fpm.sock;\n
                fastcgi_index index.php;\n
                include fastcgi_params;\n
        }\n
}\n"

`touch /etc/nginx/sites-available/$siteName.conf && echo -e $nginxConf >> /etc/nginx/sites-available/$siteName.conf && ln -s /etc/nginx/sites-available/$siteName.conf /etc/nginx/sites-enabled/$siteName.conf`

`wget -O /tmp/wordpress.zip https://wordpress.org/latest.zip && unzip -q /tmp/wordpress.zip -d  /tmp/ && mv /tmp/wordpress /usr/share/nginx/html/$siteName`

read -p "Please enter your Mysql password: " rootpass
PASSWDDB="$(openssl rand -base64 12)"

mainDB="$siteName"_db
mainDB_user="$siteName"_user
mysql -uroot --password=${rootpass} -e "CREATE DATABASE \`$mainDB\`"
mysql -uroot --password=${rootpass} -e "CREATE USER \`$mainDB_user\`@localhost IDENTIFIED BY '$PASSWDDB'"
mysql -uroot --password=${rootpass} -e "GRANT ALL PRIVILEGES ON \`$mainDB\`.* TO \`$mainDB_user\`@localhost IDENTIFIED BY '$PASSWDDB'"


db_old="define('DB_NAME', 'database_name_here');"
user_old="define('DB_USER', 'username_here');"
passwd_old="define('DB_PASSWORD', 'password_here');"

db_new="define( 'DB_NAME', '"$mainDB"' );"
user_new="define( 'DB_USER', '"$mainDB_user"' );"
passwd_new="define( 'DB_PASSWORD', '"$PASSWDDB"' );"


`sed -i  -e "s/$db_old/$db_new/" -e "s/$user_old/$user_new/" -e "s/$passwd_old/$passwd_new/" ""$nginxRoot"/wp-config-sample.php" && mv ""$nginxRoot"/wp-config-sample.php" ""$nginxRoot"/wp-config.php"`


`/usr/sbin/nginx -s reload`
