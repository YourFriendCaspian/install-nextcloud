# install-nextcloud
Install, optimize and harden your self hosted Nextcloud (based on Ubuntu 16.04.x LTS 64Bit) using two shell scripts only.

The initial script (install-nextcloud.sh) will install and optimize your self hosted Nextcloud within few minutes fully automated. Your server will be built of:

    Fail2Ban (nextcloud and ssh jails)
    MariaDB
    Nextcloud 13.0.1
    NGINX 1.14
    OpenSSL 1.1.0 h
    PHP 7.2.4
    Redis-Server
    self signed certificates or Let's Encrypt SSL
    UFW (22,80,443)

The only precondition for both scripts is to use Ubuntu 16.04.4 LTS 64Bit as your server OS.
At least (optionally) you may request a ssl certificate from letsencrypt by issuing the second script called "ssl-certificat.sh".

Ready to go? Let's start:

Find out more information: <a href="https://www.c-rieger.de/spawn-your-nextcloud-server-using-one-shell-script/" target='_blank'>Build your Nextcloud Server using shell scripts only</a>
