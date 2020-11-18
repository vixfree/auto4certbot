#!/bin/bash
#
# renew certbot ssl certificates
#
logfile="/var/log/syslog";

if [ $(dehydrated -c -4|grep 'Certificate will not expire'|wc -l) != 0 ];
    then
	echo "$(date +%c) certbot(dehydrated): no certificates to upgrade...">>$logfile;
	exit;
    else
	/etc/scripts/sertbot/dehydrated/make_ssl-dehydrated.sh;
	/etc/init.d/haproxy restart;
	echo "$(date +%c) certbot(dehydrated): updating sertificate">>$logfile;
fi
