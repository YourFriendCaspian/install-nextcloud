# install-nextcloud
Scripts to install and optimize Nextcloud (based on Ubuntu 16.04.x LTS 64Bit) with NGINX, MariaDB, PHP, Redis-Server, fail2ban and ufw

https://www.c-rieger.de/spawn-your-nextcloud-server-using-one-shell-script/

The first script (install-nextcloud.sh) will span your Server based on Ubuntu 16.04.4 LTS 64Bit
The server based on:
- NGINX 1.14.x
- PHP 7.4.x
- MariaDB
- Redis_Server
- Nextcloud 13.0.x

The second script (optimizations.sh) will tune and harden your Server:
- PHP cache, redis for Nextcloud, Nextcloud cronjob ...
- install fail2ban and create jails
- install ufw and configure port 80 and 443 (web) and 22 for SSH (change to your requirements aftwerwards)

Cheers, Carsten Rieger IT-Services
