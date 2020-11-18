#!/bin/bash
# script convert end make ssl sert for https
# info - https://sysadmin.pm/dehydrated-letsencrypt/
#
path_ssl="/etc/ssl/private";
path_certbot="/var/lib/dehydrated/certs";
domains=( "mydomain.ru" "webmail.mydomain.ru" "dev.mydomain.ru" );

function makeSslPem() {
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
    cat $path_certbot/${domains[$dmn]}/cert.pem > $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/chain.pem >> $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/fullchain.pem >> $path_ssl/${domains[$dmn]}.pem;
    cat $path_certbot/${domains[$dmn]}/privkey.pem >> $path_ssl/${domains[$dmn]}.pem;
done
}

function makePemList() {
:>/etc/ssl/crt-list.txt
for ((icrt=0; icrt != ${#domains[@]}; icrt++))
    do
    echo "$path_ssl/${domains[$icrt]}.pem">>/etc/ssl/crt-list.txt
done
}

## create sets.pem
makeSslPem;
makePemList;


