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


event_sw=0;
mode="";
reports=();

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
## test - null values
if [ $tmp_dir == "" ]; then
  tmp_dir="/tmp";
fi
web_dir="$tmp_dir/www"
conf_dir="$tmp_dir/conf"

if [ $log_file == "" ]; then
  log_file="/var/log/syslog";
fi

if [ $sites_nginx == "" ]; then
  sites_nginx="/etc/nginx/sites-enabled";
fi

if [ $sites_apache == "" ]; then
  sites_apache="/etc/apache2/sites-enabled";
fi

if [ $path_ssl == "" ]; then
  path_ssl="/etc/ssl";
fi

if [ $path_cert == "" ]; then
  path_cert="/etc/letsencrypt/live";
fi

## create temp directory
if [ ! -d $tmp_dir ]; then
 mkdir -p $tmp_dir;
fi

## create web directory
if [ ! -d "$web_dir/.well-known/acme-challenge" ]; then
 mkdir -p $web_dir/.well-known/acme-challenge;
 chown -R www-data:www-data $web_dir;
fi

## create conf directory
if [ ! -d $conf_dir ]; then
 mkdir -p $conf_dir;
fi

##
if [[ $opt != "nginx" ]] || [[ "$opt" == "apache" ]]; then
  find $sites_apache/* -maxdepth 0 -type l -printf '%f\n' >$tmp_dir/active_sites.inf 2>/dev/null;
  get_tools[${#get_tools[@]}]="apache2";
fi
if [[ $opt != "apache" ]] || [[ "$opt" == "nginx" ]]; then
  find $sites_nginx/* -maxdepth 0 -type l -printf '%f\n' >$tmp_dir/active_sites.inf 2>/dev/null;
  get_tools[${#get_tools[@]}]="nginx";
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
    echo  "$rdate $sname: ${reports[$rpt_index]}">>$log_file;
    echo   "${reports[$rpt_index]}";
    done
 exit 0;
}

##--@F exec task
function execTask(){
for ((xd=0; xd != ${#domains[@]}; xd++)); do
  local site_data=( $(echo -e ${domains[$xd]}|sed 's/ /\n /g') );
    site_name="${site_data[0]}";
    site_owner="${site_data[1]}";
    site_port="${site_data[2]}";
  case "$cmd" in
  ## create cert
  "--create" | "--create" )
    echo "ok1"
  ;;

  ## create cert
  "--update" | "--update" )
    echo "ok2"
  ;;

  ## create cert
  "--flist" | "--flist" )
    echo "ok3"
  ;;

  ## start defaults
  * )
  reports=()
  reports[${#reports[@]}]="error option!"
  makeErr;
    ;;
  esac

done

## if event - yes
if [ $event_sw != 0 ];then
  echo>/etc/ssl/crt-list.txt
  for ((xt=0; xt != ${#domains[@]}; xt++)); do
    local site_data=( $(echo -e ${domains[$xt]}|sed 's/ /\n /g') );
    echo "$path_ssl/${site_data[0]}.pem">>/etc/ssl/crt-list.txt
  done
fi
}

##--@F create configs
function createConf(){
## apache2 config
if [[ $opt != "nginx" ]] || [[ "$opt" == "apache" ]]; then
    echo >$conf_dir/$site_name.conf;
    echo -e '<VirtualHost *:'"$site_port"'>' >>$conf_dir/$site_name.conf;
    echo -e 'ServerName '"$site_name"'' >>$conf_dir/$site_name.conf;
    echo -e 'ServerAlias '"$site_name"'' >>$conf_dir/$site_name.conf;
    echo -e 'DocumentRoot '"$web_dir"'' >>$conf_dir/$site_name.conf;
    echo -e '\n' >>$conf_dir/$site_name.conf;
    echo -e '<Directory'"$web_dir"' >' >>$conf_dir/$site_name.conf;
    echo -e 'Options -Indexes +FollowSymLinks +MultiViews' >>$conf_dir/$site_name.conf;
    echo -e 'AllowOverride All' >>$conf_dir/$site_name.conf;
    echo -e 'Require all granted' >>$conf_dir/$site_name.conf;
    echo -e '</Directory>' >>$conf_dir/$site_name.conf;
    echo -e '\n' >>$conf_dir/$site_name.conf;
    echo -e 'ErrorLog ${APACHE_LOG_DIR}/error.log' >>$conf_dir/$site_name.conf;
    echo -e 'CustomLog ${APACHE_LOG_DIR}/access.log combined' >>$conf_dir/$site_name.conf;
    echo -e '</VirtualHost>' >>$conf_dir/$site_name.conf;
    ln -s $conf_dir/$site_name.conf $sites_apache/$site_name.conf
fi

## nginx config
if [[ $opt != "apache" ]] || [[ "$opt" == "nginx" ]]; then
    echo >$conf_dir/$site_name.conf;
    echo -e 'server { listen      0.0.0.0:'"$site_port"';' >>$conf_dir/$site_name.conf;
    echo -e 'server_name '"$site_name"';' >>$conf_dir/$site_name.conf;
    echo -e '\n' >>$conf_dir/$site_name.conf;
    echo -e 'location /.well-known/acme-challenge {' >>$conf_dir/$site_name.conf;
    echo -e '    allow all;' >>$conf_dir/$site_name.conf;
    echo -e '    autoindex off;' >>$conf_dir/$site_name.conf;
    echo -e '    default_type "text/plain";' >>$conf_dir/$site_name.conf;
    echo -e '    root '"$web_dir"';' >>$conf_dir/$site_name.conf;
    echo -e '}' >>$conf_dir/$site_name.conf;
    echo -e 'location = /.well-known {' >>$conf_dir/$site_name.conf;
    echo -e '    return 404;' >>$conf_dir/$site_name.conf;
    echo -e '}' >>$conf_dir/$site_name.conf;
    echo -e 'error_page 404 /404.html;' >>$conf_dir/$site_name.conf;
    echo -e 'error_page 500 502 503 504 /50x.html;' >>$conf_dir/$site_name.conf;
    echo -e '\n' >>$conf_dir/$site_name.conf;
    echo -e 'error_log /var/log/nginx/err-certbot.log;' >>$conf_dir/$site_name.conf;
    echo -e 'access_log /var/log/nginx/access-certbot.log;' >>$conf_dir/$site_name.conf;
    echo -e '}' >>$conf_dir/$site_name.conf;
    ln -s $conf_dir/$site_name.conf $sites_nginx/$site_name.conf
fi
}

##--@F create configs
function pHelp(){
echo "$sname:$version"
echo "please input pameters: avto4certbot.sh --create [apache & nginx]| --update [apache & nginx] | --flist [apache & nginx]";
echo "avto4certbot.sh --create; create new certificate or --create [apache & nginx]; create new certificate " 
echo "avto4certbot.sh --update; update certificates or --update [apache & nginx]; update [apache & nginx];"
echo "avto4certbot.sh --flist; update certificates from ssl or --flist [apache & nginx]; rescan list certificates;"
echo "avto4certbot.sh --help; this help"
echo "* examples:"
echo "  avtocertbot.sh --update apache"
echo "  or"
echo "  avtocertbot.sh --update nginx"
}

if [ "$opt" != "" ]; then
  getInfo;
  checkDep;
  execTask;
else
  pHelp;
fi

exit