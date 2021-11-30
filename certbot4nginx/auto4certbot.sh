#!/bin/bash
#
# необходимы для работы: nginx,certbot
# create new cert
path_ssl="/etc/ssl";
path_cert="/etc/letsencrypt/live";
source "/etc/scripts/auto4certbot/auto4certbot.conf";
log="/var/log/syslog";
#
cmd=$1;
#

function createCert() {
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
eval local dreg="(" $(echo -e ${domains[$dmn]}) ")";
certbot certonly --webroot -w $webcrt -d ${dreg[0]}
done
}

function renew() {
certbot renew;
valtrue=0;
rdate=$(date +%Y-%m-%d);
rtime=$(date +%H:%M);
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
    eval local dreg="(" $(echo -e ${domains[$dmn]}) ")";
     keydate=$(ls -l --time-style=long-iso $path_cert/${dreg[0]}/cert.pem |awk {'print$6'});
     keytime=$(ls -l --time-style=long-iso $path_cert/${dreg[0]}/cert.pem |awk {'print$7'});
     if [ "$keydate" = "$rdate" ] && [ "$keytime" = "$rtime" ];
        then
         ((valtrue++));
        cat $path_cert/${dreg[0]}/cert.pem > $path_ssl/private/${dreg[0]}.pem;
        cat $path_cert/${dreg[0]}/chain.pem >> $path_ssl/private/${dreg[0]}.pem;
        cat $path_cert/${dreg[0]}/fullchain.pem >> $path_ssl/private/${dreg[0]}.pem;
        cat $path_cert/${dreg[0]}/privkey.pem >> $path_ssl/private/${dreg[0]}.pem;
#
	cp -f $path_ssl/private/${dreg[0]}.pem $path_ssl/certs/${dreg[0]}.pem
    	cd $path_ssl/certs
    	chmod 600 ${dreg[0]}.pem
	ln -sf ${dreg[0]}.pem `openssl x509 -noout -hash < ${dreg[0]}.pem`.0
        cd $path_ssl
        echo "$(date) - auto4certbot.sh: update cert for  ${domains[$dmn]}">> $log;
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
echo "please input pameters: auto4certbot.sh --create | --update";
echo "auto4certbot.sh --create; create new certificate"
echo "auto4certbot.sh --update; update certificates;"
;;
esac
