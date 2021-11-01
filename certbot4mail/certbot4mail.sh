#!/bin/bash
#
# необходимо для работы: nginx,certbot
# create new cert
path_ssl="/etc/ssl";
path_cert="/etc/letsencrypt/live";
source "/etc/scripts/certbot4mail/certbot4mail.conf";
log="/var/log/syslog";
#
cmd=$1;
#

function createCert() {
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
certbot certonly --webroot --agree-tos --email $adminmail -w $webcrt -d ${domains[$dmn]}
done
}

function renew() {
certbot renew;
valtrue=0;
rdate=$(date +%Y-%m-%d);
rtime=$(date +%H:%M);
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
     keydate=$(ls -l --time-style=long-iso $path_cert/${domains[$dmn]}/cert.pem |awk {'print$6'});
     keytime=$(ls -l --time-style=long-iso $path_cert/${domains[$dmn]}/cert.pem |awk {'print$7'});
     if [ "$keydate" = "$rdate" ] && [ "$keytime" = "$rtime" ];
        then
         ((valtrue++));
        cat $path_cert/${domains[$dmn]}/cert.pem > $path_ssl/private/${domains[$dmn]}.pem;
        cat $path_cert/${domains[$dmn]}/chain.pem >> $path_ssl/private/${domains[$dmn]}.pem;
        cat $path_cert/${domains[$dmn]}/fullchain.pem >> $path_ssl/private/${domains[$dmn]}.pem;
        cat $path_cert/${domains[$dmn]}/privkey.pem >> $path_ssl/private/${domains[$dmn]}.pem;
#
	cp -f $path_ssl/private/${domains[$pem_index]}.pem $path_ssl/certs/${domains[$pem_index]}.pem
    	cd $path_ssl/certs
    	chmod 600 ${domains[$pem_index]}.pem
	ln -sf ${domains[$pem_index]}.pem `openssl x509 -noout -hash < ${domains[$pem_index]}.pem`.0
        cd $path_ssl
        echo "$(date) - certbot4mail.sh: update cert for  ${domains[$dmn]}">> $log;
      fi
done
if [ $valtrue != 0 ];
   then
     :>/etc/ssl/crt-list.txt
        for ((icrt=0; icrt != ${#domains[@]}; icrt++))
         do
          echo "$path_ssl/${domains[$icrt]}.pem">>/etc/ssl/crt-list.txt
        done
/etc/init.d/dbmail restart;
/etc/init.d/stunnel4 restart;
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
echo "please input pameters: certbot4mail.sh --create | --update";
echo "certbot4mail.sh --create; create new certificate"
echo "certbot4mail.sh --update; update certificates;"
;;
esac