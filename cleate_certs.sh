#!/bin/bash
# create new cert
domains=( "nixtech.ru" "qbpro.ru" "support.qbpro.ru" "webmail.qbpro.ru" );
adminmail="stvixfree@gmail.com";

function createCert() {
for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
certbot certonly --standalone -d ${domains[$dmn]} --non-interactive --agree-tos --email $adminmail  --http-01-port=55777
done
}

createCert;
