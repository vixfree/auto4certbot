#!/bin/bash
# create new cert
src="/etc/scripts/autocertbot/certbot.conf"

function createCert() {
certbot register --agree-tos -m $adminmail;
/etc/init.d/haproxy stop;

for ((dmn=0; dmn != ${#domains[@]}; dmn++))
    do
      certbot certonly --preferred-challenges http --standalone -d ${domains[$dmn]};
    done
/etc/init.d/haproxy start;
}

createCert;
