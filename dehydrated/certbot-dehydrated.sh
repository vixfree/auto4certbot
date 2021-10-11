#!/bin/bash
# script convert end make ssl sert for https
# info - https://sysadmin.pm/dehydrated-letsencrypt/
#
path_ssl="/etc/ssl/private";
path_certbot="/var/lib/dehydrated/certs";
src="/etc/scripts/autocertbot/certbot.conf"

function makeSslPem() {
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
    cat $path_certbot/${domains[$dmn]}/cert.pem > $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/chain.pem >> $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/fullchain.pem >> $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/privkey.pem >> $path_ssl/${domains[$dmn]}.pem;
done
makePemList;
}

function makePemList() {
:>/etc/ssl/crt-list.txt
for ((icrt=0; icrt != ${#domains[@]}; icrt++))
    do
    echo "$path_ssl/${domains[$icrt]}.pem">>/etc/ssl/crt-list.txt
done
}

function checkCert() {
if [ $(dehydrated -c -4|grep 'Certificate will not expire'|wc -l) != 0 ];
    then
        echo "$(date +%c) certbot(dehydrated): no certificates to upgrade...">>$logfile;
        exit;
    else
        makeSslPem;
        /etc/init.d/haproxy restart;
        echo "$(date +%c) certbot(dehydrated): updating sertificate">>$logfile;
fi
}



## create sets.pem
checkCert;


