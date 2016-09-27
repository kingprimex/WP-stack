#!/bin/bash

MYSQL=$(dpkg -l | grep mysql-server)
NGINX=$(dpkg -l | grep nginx)
PHP=$(dpkg -l | grep php5)



if [ "$MYSQL" == "" ]
then

`apt-get install -y mysql-server`

fi

if [ "$NGINX" == "" ]
then

`apt-get install -y nginx`

fi

if [ "$PHP" == "" ]
then

`apt-get install -y php5 php5-mysql php5-dev php5-curl php5-common`

fi

read -p "Please enter your site name: " siteName

echo "127.0.0.1 $siteName" >> /etc/hosts

nginxRoot="/usr/share/nginx/html/$siteName"
nginxConf="server { \n
        listen 80;\n
        root /usr/share/nginx/html/$siteName;\n
        index index.html index.htm;\n

        server_name $siteName;\n

        location / {\n
                try_files \$uri \$uri/ =404;\n
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

wp_conf="define( 'DB_NAME', '"$mainDB"' );\n

define( 'DB_USER', '"$mainDB_user"' );\n

define( 'DB_PASSWORD', '"$PASSWDDB"' );\n

define( 'DB_HOST', 'localhost' );\n"

`mv /usr/share/nginx/html/$siteName/wp-config-sample.php /usr/share/nginx/html/$siteName/wp-config.php && echo -e $wp_conf >> /usr/share/nginx/html/$siteName/wp-config.php`


`/usr/sbin/nginx -s reload`
