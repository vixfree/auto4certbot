#!/bin/bash
#
# author: Koshuba V.O.
# license: GPL 2.0
# create 2022
#
version="0.5.0";
sname="avto4certbot";

# script path
path_script=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd );
source "$path_script/avto4certbot.conf";

##--@S static values
# depends
pkgdep=("curl" "certbot" "letsencrypt") # packages
get_tools=("curl" "certbot" "letsencrypt")

# - options
cmd=$1;

# - for LAMP server
opt=$2;

#--@F Get info area
function getInfo() {
if [ ! -d $tmp_dir ]; then
 mkdir -p $tmp_dir;
fi

if [[ $opt != "nginx" ]] || [[ "$opt" == "apache" ]]; then
  find $sites_apache/* -maxdepth 0 -type l -printf '%f\n' >$tmp_dir/active_sites.inf;
fi
if [[ $opt != "apache" ]] || [[ "$opt" == "nginx" ]]; then
  find $sites_nginx/* -maxdepth 0 -type l -printf '%f\n' >$tmp_dir/active_sites.inf;
fi
}

#--@F Check the program dependency
function checkDep() {
    # - msg debug
    echo "check depends..."
    if [ ! "$lang" ]; then
        lang="C.UTF-8"
    fi
    for ((itools = 0; itools != ${#get_tools[@]}; itools++)); do
        checktool=$(whereis -b ${get_tools[$itools]} | awk '/^'${get_tools[$itools]}':/{print $2}')
        if [[ $checktool = "" ]]; then
            sudo apt install ${pkgdep[$itools]}
        fi
        checktool=$(whereis -b ${get_tools[$itools]} | awk '/^'${get_tools[$itools]}':/{print $2}')
        if [[ $checktool != "" ]]; then
            eval get_${get_tools[$itools]}=$(whereis -b ${get_tools[$itools]} | awk '/^'${get_tools[$itools]}':/{print $2}')
            list_tools[${#list_tools[@]}]="$(whereis -b ${get_tools[$itools]} | awk '/^'${get_tools[$itools]}':/{print $2}')"
        else
            ## lang messages if yes then lang else us...
            reports=()
            reports[${#reports[@]}]="Sorry, there are no required packages to work, please install:${pkgdep[@]}"
            makeErr
            exit
        fi
    done
}

##--@F make all errors
function makeErr() {
for ((rpt_index=0; rpt_index != ${#reports[@]}; rpt_index++))
    do
    echo  "$rdate $sname: ${reports[$rpt_index]}">>$log;
    echo   "${reports[$rpt_index]}";
    done
 exit 0;
}

function createCert() {
#
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
eval local dreg="(" $(echo -e ${domains[$dmn]}) ")";
    if [ "$cmd" == "--create" ];
        then
            certbot -m "${dreg[1]}";
        else
            certbot --update-registration -m "${dreg[1]}";
    fi
##
## example manual: certbot certonly --webroot --webroot-path /tmp/letsencrypt -d mydomen.ru
certbot certonly --webroot --webroot-path $www_root -d ${dreg[0]}
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
     if [[ "$keydate" = "$rdate" ]] && [[ "$keytime" = "$rtime" ]]; then
         ((valtrue++));
		if [ -d $path_cert/${dreg[0]} ]; then
		cat $path_cert/${dreg[0]}/privkey.pem > $path_ssl/private/privkey_${dreg[0]}.pem;
		cat $path_cert/${dreg[0]}/fullchain.pem > $path_ssl/private/fullchain_${dreg[0]}.pem;
    		cat $path_cert/${dreg[0]}/fullchain.pem > $path_ssl/private/${dreg[0]}.pem;
    		cat $path_cert/${dreg[0]}/privkey.pem >> $path_ssl/private/${dreg[0]}.pem;
#
    		cp -f $path_ssl/private/${dreg[0]}.pem $path_ssl/certs/${dreg[0]}.pem
    		cd $path_ssl/certs
    		chmod 600 ${dreg[0]}.pem
    		ln -sf ${dreg[0]}.pem `openssl x509 -noout -hash < ${dreg[0]}.pem`.0
    		cd $path_ssl
    		echo "$(date) - $sname: update cert for  ${domains[$dmn]}">> $log;
		fi
      fi
done
if [ $valtrue != 0 ];then
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
		if [ -d $path_cert/${dreg[0]} ]; then
		cat $path_cert/${dreg[0]}/privkey.pem > $path_ssl/private/privkey_${dreg[0]}.pem;
		cat $path_cert/${dreg[0]}/fullchain.pem > $path_ssl/private/fullchain_${dreg[0]}.pem;
    		cat $path_cert/${dreg[0]}/fullchain.pem > $path_ssl/private/${dreg[0]}.pem;
    		cat $path_cert/${dreg[0]}/privkey.pem >> $path_ssl/private/${dreg[0]}.pem;
#
                cp -f $path_ssl/private/${dreg[0]}.pem $path_ssl/certs/${dreg[0]}.pem
                cd $path_ssl/certs
                chmod 600 ${dreg[0]}.pem
                ln -sf ${dreg[0]}.pem `openssl x509 -noout -hash < ${dreg[0]}.pem`.0
                cd $path_ssl
                echo "$(date) - $sname: update certlist for  ${domains[$dmn]}">> $log;
		fi
        done
        if [ $valtrue != 0 ]; then
                echo >/etc/ssl/crt-list.txt
            for ((icrt=0; icrt != ${#domains[@]}; icrt++))
                do
                eval local dcrt="(" $(echo -e ${domains[$icrt]}) ")";
                echo "$path_ssl/private/${dcrt[0]}.pem">>/etc/ssl/crt-list.txt
            done
        fi
    else
        echo "Ошибка - отсутствует $path_cert!"
	echo "$(date) - $sname: Ошибка - отсутствует $path_cert!">> $log;
fi
}

function downSite(){
sudo systemctl stop nginx.service;
eval list_www="(" $(find $nginx_enable/* -maxdepth 0 -type l -printf '%f\n' 2>/dev/null) ")";

if [ ${#list_www[@]} != 0 ]; then
for ((dwx=0; dwx != ${#list_www[@]}; dwx++))
    do
      rm $nginx_enable/${list_www[dwx]};
done
fi
}

function upSite(){
sudo systemctl stop nginx.service;
eval cert_bot="(" $(find $nginx_enable/* -maxdepth 0 -type l -printf '%f\n' 2>/dev/null) ")";
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

function restoreSite() {
sudo systemctl stop nginx.service;
eval list_www="(" $(find $nginx_enable/* -maxdepth 0 -type l -printf '%f\n' 2>/dev/null) ")";

if [ ${#list_www[@]} != 0 ]; then
for ((dwx=0; dwx != ${#list_www[@]}; dwx++))
    do
      rm $nginx_enable/${list_www[dwx]};
done
fi
for ((dwx=0; dwx != ${#enable_www[@]}; dwx++))
    do
	ln -s $nginx_available/${enable_www[dwx]} $nginx_enable/${enable_www[dwx]};
done
sudo systemctl start nginx.service;
}

function createConf(){
  if [ ! -d $path_tmp/conf ]; then
      mkdir -p $path_tmp/conf;
  fi

  if [ ! -d $www_root ]; then
      mkdir -p $www_root/.well-known/acme-challenge;
      chown -R www-data:www-data $www_root;
  fi

## apache2 config
if [[ $opt != "nginx" ]] || [[ "$opt" == "apache" ]]; then
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
fi

## nginx config
if [[ $opt != "apache" ]] || [[ "$opt" == "nginx" ]]; then
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
fi
}

case "$cmd" in

## create cert
"--create" | "--create" )

downSite;
upSite;
createCert;
toSSL;
downSite;
if [ "$opt" == "srv" ]; then
restartService;
else
restoreSite;
fi

;;

## update cert
"--update" | "--update" )

downSite;
upSite;
renew;
downSite;
if [[ "$opt" == "srv" ]] && [[ $valtrue != 0 ]]; then
 restartService;
else
 restoreSite;
fi

;;

## update cert
"--test" | "--test" )
if [ "$opt" != "" ]; then
  getInfo;
else
  echo "no parameter specified - nginx or apache?"
  echo "avtocertbot.sh --test apache"
fi

;;

## update cert force
"--flist" | "--flist" )
toSSL;
if [ "$opt" == "srv" ]; then
restartService;
fi

;;

## start defaults

* )
checkDep;
echo "$sname:$version"
echo "please input pameters: avto4certbot.sh --create [apache & nginx]| --update [apache & nginx] | --flist [apache & nginx]";
echo "avto4certbot.sh --create; create new certificate or --create [apache & nginx]; create new certificate " 
echo "avto4certbot.sh --update; update certificates or --update [apache & nginx]; update [apache & nginx];"
echo "avto4certbot.sh --flist; update certificates from ssl or --flist [apache & nginx]; rescan list certificates;"
;;
esac

exit
