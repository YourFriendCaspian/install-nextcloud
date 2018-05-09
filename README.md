# c-rieger.de - install Nextcloud using shell
Install, optimize and harden your self hosted Nextcloud (based on Ubuntu 18.04 LTS 64Bit) using two shell scripts only.

The initial script (install-nextcloud.sh) will install and optimize your self hosted Nextcloud within few minutes fully automated. Your server will be built of:

    Fail2Ban (Nextcloud and SSH jails)
    MariaDB
    Nextcloud 13.0.2
    NGINX 1.14
    OpenSSL 1.1.0h
    PHP 7.2.5
    Redis-Server
    self signed certificates or Let's Encrypt SSL
    UFW (22, 80, 443)

The only precondition is to use Ubuntu 18.04 LTS 64Bit as your server OS.
At least (optionally) you may request a ssl certificate from letsencrypt by issuing the second script called "ssl-certificat.sh".

Ready to go? Let's start:

Find out more information: <a href="https://www.c-rieger.de/spawn-your-nextcloud-server-using-one-shell-script/" target='_blank'>Build your Nextcloud Server using shell scripts only</a>
