#!/bin/bash
#
# author: Koshuba V.O.
# license: GPL 2.0
# create 2022
#
version="0.2.9";
sname="certbot4mail";
# необходимы для работы: nginx,certbot
# create new cert
path_ssl="/etc/ssl";
path_cert="/etc/letsencrypt/live";
source "/etc/scripts/certbot4mail/certbot4mail.conf";
## - nginx
nginx_enable="/etc/nginx/sites-enabled";
nginx_available="/etc/nginx/sites-available";
##
www_root="/tmp/letsencrypt";
##
path_tmp="/tmp/certbot";
##
log="/var/log/syslog";
#
cmd=$1;
#-list enable sites
scan_list=();
#

function createCert() {
#
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
eval local dreg="(" $(echo -e ${domains[$dmn]}) ")";
    if [ "$cmd" == "--create" ];
        then
            certbot -m "${dreg[1]}";
        else
            certbot --update-registration -m "${dreg[1]}" -d "${dreg[0]}" ;
    fi
##
## example manual: certbot certonly --webroot --webroot-path /tmp/letsencrypt/ -d mydomen.ru
certbot certonly --webroot --webroot-path $www_root/ -d ${dreg[0]}
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
# to postfix
	if [ ! -d $path_ssl/manual ]; then
	    mkdir -p $path_ssl/manual;
	fi
        cat $path_cert/${dreg[0]}/fullchain.pem >> $path_ssl/manual/fullchain.pem;
        cat $path_cert/${dreg[0]}/privkey.pem >> $path_ssl/manual/privkey.pem;
#

        cp -f $path_ssl/private/${dreg[0]}.pem $path_ssl/certs/${dreg[0]}.pem
        cd $path_ssl/certs
        chmod 600 ${dreg[0]}.pem
        ln -sf ${dreg[0]}.pem `openssl x509 -noout -hash < ${dreg[0]}.pem`.0
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
fi
}


function toSSL() {
if [ -d $path_cert ];
    then
        for ((dmn=0; dmn != ${#domains[@]}; dmn++))
            do
                eval local dreg="(" $(echo -e ${domains[$dmn]}) ")";
                ((valtrue++));
                cat $path_cert/${dreg[0]}/cert.pem > $path_ssl/private/${dreg[0]}.pem;
                cat $path_cert/${dreg[0]}/chain.pem >> $path_ssl/private/${dreg[0]}.pem;
                cat $path_cert/${dreg[0]}/fullchain.pem >> $path_ssl/private/${dreg[0]}.pem;
                cat $path_cert/${dreg[0]}/privkey.pem >> $path_ssl/private/${dreg[0]}.pem;
# to postfix
		if [ ! -d $path_ssl/manual ]; then
		    mkdir -p $path_ssl/manual;
		fi
    		cat $path_cert/${dreg[0]}/fullchain.pem >> $path_ssl/manual/fullchain.pem;
    		cat $path_cert/${dreg[0]}/privkey.pem >> $path_ssl/manual/privkey.pem;
#
                cp -f $path_ssl/private/${dreg[0]}.pem $path_ssl/certs/${dreg[0]}.pem
                cd $path_ssl/certs
                chmod 600 ${dreg[0]}.pem
                ln -sf ${dreg[0]}.pem `openssl x509 -noout -hash < ${dreg[0]}.pem`.0
                cd $path_ssl
                echo "$(date) - certbot4mail.sh: update certlist for  ${domains[$dmn]}">> $log;
        done
        if [ $valtrue != 0 ];
            then
                echo >/etc/ssl/crt-list.txt
            for ((icrt=0; icrt != ${#domains[@]}; icrt++))
                do
                eval local dcrt="(" $(echo -e ${domains[$icrt]}) ")";
                echo "$path_ssl/private/${dcrt[0]}.pem">>/etc/ssl/crt-list.txt
            done
        fi
    else
        echo "Ошибка - отсутствует $path_cert!"
fi
}

function downSite(){
sudo systemctl stop nginx.service;

eval list_www="(" $(find $nginx_enable/* -maxdepth 0 -type l -printf '%f\n') ")";
for ((dwx=0; dwx != ${#list_www[@]}; dwx++))
    do
      rm $nginx_enable/${list_www[dwx]};
done
}

function upSite(){
sudo systemctl stop nginx.service;
eval cert_bot="(" $(find $nginx_enable/* -maxdepth 0 -type l -printf '%f\n') ")";
for ((cr=0; cr != ${#cert_bot[@]}; cr++))
    do
      rm $nginx_enable/${cert_bot[cr]};
done
for ((dnm=0; dnm != ${#domains[@]}; dnm++))
    do
eval local dcert="(" $(echo -e ${domains[$dnm]}) ")";
    sitename="${dcert[0]}";
    siteport="${dcert[2]}";
    createConf;
done
sudo systemctl start nginx.service;
}


function createConf(){
if [ ! -d $path_tmp ];
  then
    mkdir -p $path_tmp;
fi

if [ ! -d $www_root ];
  then
    mkdir -p $www_root/.well-known/acme-challenge;
chown -R www-data:www-data $www_root;
fi
    echo >$path_tmp/$sitename.conf;
    echo -e 'server { listen      0.0.0.0:'"$siteport"';' >>$path_tmp/$sitename.conf;
    echo -e '\n' >>$path_tmp/$sitename.conf;
    echo -e 'server_name '"$sitename"';' >>$path_tmp/$sitename.conf;
    echo -e '\n' >>$path_tmp/$sitename.conf;
    echo -e 'location /.well-known/acme-challenge {' >>$path_tmp/$sitename.conf;
    echo -e '    allow all;' >>$path_tmp/$sitename.conf;
    echo -e '    autoindex off;' >>$path_tmp/$sitename.conf;
    echo -e '    default_type "text/plain";' >>$path_tmp/$sitename.conf;
    echo -e '    root '"$www_root"';' >>$path_tmp/$sitename.conf;
    echo -e '}' >>$path_tmp/$sitename.conf;
    echo -e '\n' >>$path_tmp/$sitename.conf;
    echo -e 'location = /.well-known {' >>$path_tmp/$sitename.conf;
    echo -e '    return 404;' >>$path_tmp/$sitename.conf;
    echo -e '}' >>$path_tmp/$sitename.conf;
    echo -e '\n' >>$path_tmp/$sitename.conf;
    echo -e 'error_page 404 /404.html;' >>$path_tmp/$sitename.conf;
    echo -e 'error_page 500 502 503 504 /50x.html;' >>$path_tmp/$sitename.conf;
    echo -e '\n' >>$path_tmp/$sitename.conf;
    echo -e 'error_log /var/log/nginx/err-certbot.log;' >>$path_tmp/$sitename.conf;
    echo -e 'access_log /var/log/nginx/access-certbot.log;' >>$path_tmp/$sitename.conf;
    echo -e '}' >>$path_tmp/$sitename.conf;
ln -s $path_tmp/$sitename.conf $nginx_enable/$sitename.conf
}

function restartMail(){
/etc/init.d/dbmail restart;
/etc/init.d/stunnel4 restart;
/etc/init.d/postfix restart;
}


case "$cmd" in

## create cert
"--create" | "--create" )

downSite;
createCert;
upSite;
toSSL;
downSite;
restartMail;
;;

## update cert
"--update" | "--update" )

downSite;
renew;
upSite;
toSSL;
downSite;
restartMail;
;;

## update cert force
"--flist" | "--flist" )
toSSL;
restartMail;
;;

## start defaults

* )
echo "please input pameters: certbot4mail.sh --create | --update | --flist";
echo "certbot4mail.sh --create; create new certificate"
echo "certbot4mail.sh --update; update certificates;"
echo "certbot4mail.sh --flist; update certificates from ssl;"
;;
esac

exit
