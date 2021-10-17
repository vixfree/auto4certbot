#!/bin/bash
# script convert end make ssl sert for https
# info - 
#
path_certbot="/etc/letsencrypt/live";
path_ssl="/etc/ssl/private";
source certbot.conf;
logfile="/var/log/syslog";
#
cmd=$1;
#

function makesslkey() {
:>/etc/ssl/crt-list.txt
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
    cat $path_certbot/${domains[$dmn]}/cert.pem > $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/chain.pem >> $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/fullchain.pem >> $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/privkey.pem >> $path_ssl/${domains[$dmn]}.pem;
done
for ((icrt=0; icrt != ${#domains[@]}; icrt++))
    do
    echo "$path_ssl/${domains[$icrt]}.pem">>/etc/ssl/crt-list.txt
done
}

function renew() {
/etc/init.d/haproxy stop;
    certbot renew;
/etc/init.d/haproxy start;
}

function createCert() {
certbot register --agree-tos -m $adminmail;
/etc/init.d/haproxy stop;

for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
      certbot certonly --preferred-challenges http --standalone -d ${domains[$dmn]};
    done
/etc/init.d/haproxy start;
}


case "$cmd" in

## create cert
"--create" | "--create" )
createCert;
;;

## update cert
"--update" | "--update" )
renew;
;;

## start defaults

* )
echo "please input pameters: autocertbot.sh --create | --update";
echo "autocertbot.sh --create; create new certificate"
echo "autocertbot.sh --update; update certificates;"
;;
esac