# install-nextcloud
Install, optimize and harden your self hosted Nextcloud (based on Ubuntu 16.04.x LTS 64Bit) using two shell scripts only.

The initial script called "install-nextcloud.sh" will install your self hosted Nextcloud within few minutes fully automated. Your server will be built of:

    MariaDB
    Nextcloud 13.0.1
    NGINX 1.14
    OpenSSL 1.1.0 h
    PHP 7.2.4
    Redis-Server

The only precondition for this script is to use Ubuntu 16.04.4 LTS 64Bit as your server OS.

If you have configured your Nextcloud afterwards in your preferred browser issue the second script called "optimizations.sh" to  optimize your Nextcloud instance (cache, previews, cron etc.) and install & configure fail2ban with ufw to harden your Nextcloud.

Cheers, Carsten Rieger IT-Services

Find out more information: <a href="https://www.c-rieger.de/spawn-your-nextcloud-server-using-one-shell-script/" target="_blank">Build your Nextcloud Server using shell scripts only</a>
