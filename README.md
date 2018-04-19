# install-nextcloud
Scripts to install and optimize Nextcloud (based on Ubuntu 16.04.x LTS 64Bit) with NGINX, MariaDB, PHP, Redis-Server, fail2ban and ufw

This install-nextcloud.sh script will install your self hosted Nextcloud within few minutes and fully automated. Your server will be built consisting of:

    MariaDB
    Nextcloud 13.0.1
    NGINX 1.14
    OpenSSL 1.1.0 h
    PHP 7.2.4
    Redis-Server

The only precondition for this script is to use Ubuntu 16.04.4 LTS 64Bit as your server OS.
If you have configured your Nextcloud you have the opportunity to issue the second script (optimizations.sh), which will optimize your Nextcloud (cache, previews, cron etc.) and install + configure fail2ban and ufw to harden your Nextcloud.

Cheers, Carsten Rieger IT-Services

<a href="https://www.c-rieger.de/spawn-your-nextcloud-server-using-one-shell-script/" target="_blank">Build your Nextcloud Server using one shell scrip</a>
