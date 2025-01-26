### package scripts for auto update all certs
### avto4certbot:0.5.0
Если возникает ошибка: "Peer's Certificate issuer is not recognized"
используейте параметр: git -c http.sslVerify=false clone ...

--
begin edit avto4certbot.conf
```
please input pameters: avto4certbot.sh --create [apache & nginx && proxy]| --update [apache & nginx] | --flist [apache & nginx]
avto4certbot.sh --create; create new certificate or --create [apache & nginx && proxy]; create new certificate 
avto4certbot.sh --update; update certificates or --update [apache & nginx && proxy]; update [apache & nginx];
avto4certbot.sh --flist; update certificates from ssl or --flist [apache & nginx && proxy]; rescan list certificates;
avto4certbot.sh --help; this help
* examples:
  avtocertbot.sh --update apache
  or
  avtocertbot.sh --update nginx
  or
  avtocertbot.sh --update apache proxy
```
--
example crontab:

```
## autocertbot
24 01 * * * root /etc/scripts/avto4certbot/avto4certbot.sh --update
```
