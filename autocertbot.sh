#!/bin/bash
# script convert end make ssl sert for https
# info - script auto update cert for sites
# version 1.10.1
# author Koshuba V.O.- 2021
# master@qbpro.ru
# 
path_certbot="/etc/letsencrypt/live";
path_ssl="/etc/ssl/private";
source certbot.conf;
log="/var/log/syslog";
#
cmd=$1;
#
## if keys update certbot - recreate keys for sites
function makekeys() {
valtrue=0;
rdate=$(date +%Y-%m-%d);
rtime=$(date +%H:%M);
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
     keydate=$(ls -l --time-style=long-iso $path_certbot/${domains[$dmn]}/cert.pem |awk {'print$6'});
     keytime=$(ls -l --time-style=long-iso $path_certbot/${domains[$dmn]}/cert.pem |awk {'print$7'});
     if [ "$keydate" = "$rdate" ] && [ "$keytime" = "$rtime" ];
        then
         ((valtrue++));
        cat $path_certbot/${domains[$dmn]}/cert.pem > $path_ssl/${domains[$dmn]}.pem;
        cat $path_certbot/${domains[$dmn]}/chain.pem >> $path_ssl/${domains[$dmn]}.pem;
        cat $path_certbot/${domains[$dmn]}/fullchain.pem >> $path_ssl/${domains[$dmn]}.pem;
        cat $path_certbot/${domains[$dmn]}/privkey.pem >> $path_ssl/${domains[$dmn]}.pem;
        echo "$rdate - $rtime - autocertbot: recreate cert for  ${domains[$dmn]}">> $log;
      fi
done
if [ $valtrue != 0 ];
   then
     :>/etc/ssl/crt-list.txt
        for ((icrt=0; icrt != ${#domains[@]}; icrt++))
         do
          echo "$path_ssl/${domains[$icrt]}.pem">>/etc/ssl/crt-list.txt
        done
fi
}

function renew() {
/etc/init.d/haproxy stop;
    certbot renew;
    makekeys;
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