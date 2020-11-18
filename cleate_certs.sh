#!/bin/bash
# create new cert
domains=( "mydomain.ru" "dev.mydomain.ru" "webmail.mydomain.ru" );
adminmail="admin@mydomain.ru";

function createCert() {
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
certbot certonly --standalone -d ${domains[$dmn]} --non-interactive --agree-tos --email $adminmail  --http-01-port=55777
done
}

createCert;
