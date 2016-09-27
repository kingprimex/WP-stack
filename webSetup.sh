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

