#######################################################
# Carsten Rieger IT-Services
# INSTALL-NEXTCLOUD.SH
# Version 1.3
# April 23rd, 2018
# version 1.3: Nextcloud will silently be installed
# version 1.2: changed the process of creating the NC
#              db/user, added mysql_secure_installation
# version 1.1: added functions
# Version 1.0: initial script
#######################################################
#!/bin/bash
###global function to update and cleanup the environment
function update_and_clean() {
apt update
apt upgrade -y
apt autoclean -y
apt autoremove -y
}
###global function to restart all cloud services
function restart_all_services() {
/usr/sbin/service nginx restart
/usr/sbin/service mysql restart
/usr/sbin/service redis-server restart
/usr/sbin/service php7.2-fpm restart
}
cd /usr/local/src
update_and_clean
###prepare the server environment
apt install software-properties-common python-software-properties zip unzip screen curl ffmpeg libfile-fcntllock-perl -y
apt remove nginx nginx-common nginx-full -y --allow-change-held-packages
###add the neccessary sources
sed -i '$adeb http://nginx.org/packages/ubuntu/ xenial nginx' /etc/apt/sources.list
sed -i '$adeb-src http://nginx.org/packages/ubuntu/ xenial nginx' /etc/apt/sources.list
wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key
update_and_clean
###instal NGINX
apt install nginx -y
###enable NGINX autostart
systemctl enable nginx.service
### prepare the NGINX
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && touch /etc/nginx/nginx.conf
cat <<EOF >/etc/nginx/nginx.conf
user www-data;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events {
worker_connections 1024;
multi_accept on;
use epoll;
}
http {
server_names_hash_bucket_size 64;
upstream php-handler {
server unix:/run/php/php7.2-fpm.sock;
}
include /etc/nginx/mime.types;
#include /etc/nginx/proxy.conf;
#include /etc/nginx/ssl.conf;
#include /etc/nginx/header.conf;
#include /etc/nginx/optimization.conf;
default_type application/octet-stream;
log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" \$status \$body_bytes_sent "\$http_referer" "\$http_user_agent" "\$http_x_forwarded_for" "\$host" sn="\$server_name" rt=\$request_time ua="\$upstream_addr" us="\$upstream_status" ut="\$upstream_response_time" ul="\$upstream_response_length" cs=\$upstream_cache_status' ;
access_log /var/log/nginx/access.log main;
sendfile on;
send_timeout 3600;
tcp_nopush on;
tcp_nodelay on;
open_file_cache max=500 inactive=10m;
open_file_cache_errors on;
keepalive_timeout 65;
reset_timedout_connection on;
server_tokens off;
resolver 208.67.222.222;
resolver_timeout 10s;
include /etc/nginx/conf.d/*.conf;
}
EOF
###restart NGINX
service nginx restart
###create folders
mkdir -p /var/nc_data /var/www/letsencrypt /usr/local/tmp/cache /usr/local/tmp/sessions /usr/local/tmp/apc /upload_tmp
###apply permissions
chown -R www-data:www-data /upload_tmp /var/nc_data /var/www
chown -R www-data:root /usr/local/tmp/sessions /usr/local/tmp/cache /usr/local/tmp/apc
### prepare the environment for PHP
apt install language-pack-en-base -y
sudo LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php -y
update_and_clean
###install PHP
apt install php7.2-fpm php7.2-gd php7.2-mysql php7.2-curl php7.2-xml php7.2-zip php7.2-intl php7.2-mbstring php7.2-json php7.2-bz2 php7.2-ldap php-apcu imagemagick php-imagick -y
###adjust PHP
cp /etc/php/7.2/fpm/pool.d/www.conf /etc/php/7.2/fpm/pool.d/www.conf.bak
cp /etc/php/7.2/cli/php.ini /etc/php/7.2/cli/php.ini.bak
cp /etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini.bak
cp /etc/php/7.2/fpm/php-fpm.conf /etc/php/7.2/fpm/php-fpm.conf.bak
sed -i "s/;env\[HOSTNAME\] = /env[HOSTNAME] = /" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;env\[TMP\] = /env[TMP] = /" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;env\[TMPDIR\] = /env[TMPDIR] = /" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;env\[TEMP\] = /env[TEMP] = /" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;env\[PATH\] = /env[PATH] = /" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/pm.max_children = .*/pm.max_children = 240/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/pm.start_servers = .*/pm.start_servers = 20/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/pm.min_spare_servers = .*/pm.min_spare_servers = 10/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/pm.max_spare_servers = .*/pm.max_spare_servers = 20/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;pm.max_requests = 500/pm.max_requests = 500/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/output_buffering =.*/output_buffering = 'Off'/" /etc/php/7.2/cli/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 1800/" /etc/php/7.2/cli/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/7.2/cli/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10240M/" /etc/php/7.2/cli/php.ini
sed -i "s/;upload_tmp_dir =.*/upload_tmp_dir = \/upload_tmp/" /etc/php/7.2/cli/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10240M/" /etc/php/7.2/cli/php.ini
sed -i "s/max_file_uploads =.*/max_file_uploads = 100/" /etc/php/7.2/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/7.2/cli/php.ini
sed -i "s/;session.cookie_secure.*/session.cookie_secure = True/" /etc/php/7.2/cli/php.ini
sed -i "s/;session.save_path =.*/session.save_path = \"N;700;\/usr\/local\/tmp\/sessions\"/" /etc/php/7.2/cli/php.ini
sed -i '$aapc.enable_cli = 1' /etc/php/7.2/cli/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/output_buffering =.*/output_buffering = 'Off'/" /etc/php/7.2/fpm/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 1800/" /etc/php/7.2/fpm/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/7.2/fpm/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10240M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;upload_tmp_dir =.*/upload_tmp_dir = \/upload_tmp/" /etc/php/7.2/fpm/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10240M/" /etc/php/7.2/fpm/php.ini
sed -i "s/max_file_uploads =.*/max_file_uploads = 100/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/7.2/fpm/php.ini
sed -i "s/;session.cookie_secure.*/session.cookie_secure = True/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.enable_cli=.*/opcache.enable_cli=1/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=128/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=1/" /etc/php/7.2/fpm/php.ini
sed -i "s/;opcache.save_comments=.*/opcache.save_comments=1/" /etc/php/7.2/fpm/php.ini
sed -i "s/;session.save_path =.*/session.save_path = \"N;700;\/usr\/local\/tmp\/sessions\"/" /etc/php/7.2/fpm/php.ini
sed -i "s/;emergency_restart_threshold =.*/emergency_restart_threshold = 10/" /etc/php/7.2/fpm/php-fpm.conf
sed -i "s/;emergency_restart_interval =.*/emergency_restart_interval = 1m/" /etc/php/7.2/fpm/php-fpm.conf
sed -i "s/;process_control_timeout =.*/process_control_timeout = 10s/" /etc/php/7.2/fpm/php-fpm.conf
sed -i '$aapc.enabled=1' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.file_update_protection=2' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.optimization=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.shm_size=256M' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.include_once_override=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.shm_segments=1' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.ttl=7200' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.user_ttl=7200' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.gc_ttl=3600' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.num_files_hint=1024' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.enable_cli=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.max_file_size=5M' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.cache_by_default=1' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.use_request_time=1' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.slam_defense=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.mmap_file_mask=/usr/local/tmp/apc.XXXXXX' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.stat_ctime=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.canonicalize=1' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.write_lock=1' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.report_autofilter=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.rfc1867=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.rfc1867_prefix =upload_' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.rfc1867_name=APC_UPLOAD_PROGRESS' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.rfc1867_freq=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.rfc1867_ttl=3600' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.lazy_classes=0' /etc/php/7.2/fpm/php.ini
sed -i '$aapc.lazy_functions=0' /etc/php/7.2/fpm/php.ini
sed -i "s/09,39.*/# &/" /etc/cron.d/php
(crontab -l ; echo "09,39 * * * * /usr/lib/php/sessionclean 2>&1") | crontab -u root -
sed -i '$atmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,noexec,mode=1777 0 0' /etc/fstab
sed -i '$atmpfs /var/tmp tmpfs defaults,noatime,nosuid,nodev,noexec,mode=1777 0 0' /etc/fstab
sed -i '$atmpfs /usr/local/tmp/apc tmpfs defaults,uid=33,size=300M,noatime,nosuid,nodev,noexec,mode=1777 0 0' /etc/fstab
sed -i '$atmpfs /usr/local/tmp/cache tmpfs defaults,uid=33,size=300M,noatime,nosuid,nodev,noexec,mode=1777 0 0' /etc/fstab
sed -i '$atmpfs /usr/local/tmp/sessions tmpfs defaults,uid=33,size=300M,noatime,nosuid,nodev,noexec,mode=1777 0 0' /etc/fstab
###make use of RAMDISK
mount -a
###restart PHP and NGINX
service php7.2-fpm restart
service nginx restart
###install MariaDB
apt install mariadb-server -y
###configure MariaDB
mv /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
touch /etc/mysql/my.cnf
cat <<EOF >/etc/mysql/my.cnf
[server]
skip-name-resolve
innodb_buffer_pool_size = 128M
innodb_buffer_pool_instances = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 32M
innodb_max_dirty_pages_pct = 90
query_cache_type = 1
query_cache_limit = 2M
query_cache_min_res_unit = 2k
query_cache_size = 64M
tmp_table_size= 64M
max_heap_table_size= 64M
slow-query-log = 1
slow-query-log-file = /var/log/mysql/slow.log
long_query_time = 1

[client-server]
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mariadb.conf.d/

[client]
default-character-set = utf8mb4

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
binlog_format = MIXED
innodb_large_prefix=on
innodb_file_format=barracuda
innodb_file_per_table=1
EOF
clear
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "The Nextcloud-DB username and the Nextcloud-DB password - Attention: case-sensitive:"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Keep both in mind - you will be asked for while finishing the Nextcloud-Wizard!"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
read -p "Nextcloud DB-Username: " NEXTCLOUDDBUSER
echo "Your Nextcloud-DB user: "$NEXTCLOUDDBUSER
echo ""
read -p "Nextcloud DB-Password: " NEXTCLOUDDBPASSWORD
echo "Your Nextcloud-DB password: "$NEXTCLOUDDBPASSWORD
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
###restart MariaDB server andconnect to MariaDB
service mysql restart && mysql -uroot <<EOF
###create Nextclouds DB and User
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER $NEXTCLOUDDBUSER@localhost identified by '$NEXTCLOUDDBPASSWORD';
GRANT ALL PRIVILEGES on nextcloud.* to $NEXTCLOUDDBUSER@localhost;
FLUSH privileges;
EOF
###harden your MariDB server
mysql_secure_installation
update_and_clean
###install Redis-Server
apt install redis-server php-redis -y
cp /etc/redis/redis.conf /etc/redis/redis.conf.bak
###adjust Redis_Server
sed -i "s/port 6379/port 0/" /etc/redis/redis.conf
sed -i s/\#\ unixsocket/\unixsocket/g /etc/redis/redis.conf
sed -i "s/unixsocketperm 700/unixsocketperm 770/" /etc/redis/redis.conf
sed -i "s/# maxclients 10000/maxclients 512/" /etc/redis/redis.conf
usermod -a -G redis www-data
cp /etc/sysctl.conf /etc/sysctl.conf.bak && sed -i '$avm.overcommit_memory = 1' /etc/sysctl.conf
cp /etc/rc.local /etc/rc.local.bak && sed -i '$i \sysctl -w net.core.somaxconn=65535' /etc/rc.local
###install self signed certificates
apt install ssl-cert -y
###prepare NGINX for Nextcloud and SSL
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
touch /etc/nginx/conf.d/default.conf
cat <<EOF >/etc/nginx/conf.d/nextcloud.conf
server {
server_name YOUR.DEDYN.IO;
listen 80 default_server;
location ^~ /.well-known/acme-challenge {
proxy_pass http://127.0.0.1:81;
proxy_set_header Host \$host;
}
location / {
return 301 https://\$host\$request_uri;
}
}
server {
server_name YOUR.DEDYN.IO;
listen 443 ssl http2 default_server;
root /var/www/nextcloud/;
access_log /var/log/nginx/nextcloud.access.log main;
error_log /var/log/nginx/nextcloud.error.log warn;
location = /robots.txt {
allow all;
log_not_found off;
access_log off;
}
location = /.well-known/carddav {
return 301 \$scheme://\$host/remote.php/dav;
}
location = /.well-known/caldav {
return 301 \$scheme://\$host/remote.php/dav;
}
client_max_body_size 10240M;
location / {
rewrite ^ /index.php\$uri;
}
location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
deny all;
}
location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
deny all;
}
location ~ \.(?:flv|mp4|mov|m4a)\$ {
mp4;
mp4_buffer_size 100m;
mp4_max_buffer_size 1024m;
fastcgi_split_path_info ^(.+\.php)(/.*)\$;
include fastcgi_params;
include php_optimization.conf;
fastcgi_pass php-handler;
fastcgi_param HTTPS on;
}
location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:\$|/) {
fastcgi_split_path_info ^(.+\.php)(/.*)\$;
include fastcgi_params;
include php_optimization.conf;
fastcgi_pass php-handler;
fastcgi_param HTTPS on;
}
location ~ ^/(?:updater|ocs-provider)(?:\$|/) {
try_files \$uri/ =404;
index index.php;
}
location ~ \.(?:css|js|woff|svg|gif|png|html|ttf|ico|jpg|jpeg)\$ {
try_files \$uri /index.php\$uri\$is_args\$args;
access_log off;
expires 360d;
}
}
EOF
touch /etc/nginx/conf.d/letsencrypt.conf
cat <<EOF >/etc/nginx/conf.d/letsencrypt.conf
server {
server_name 127.0.0.1;
listen 127.0.0.1:81 default_server;
charset utf-8;
access_log /var/log/nginx/le.access.log main;
error_log /var/log/nginx/le.error.log warn;
location ^~ /.well-known/acme-challenge {
default_type text/plain;
root /var/www/letsencrypt;
}
}
EOF
touch /etc/nginx/ssl.conf
cat <<EOF >/etc/nginx/ssl.conf
ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
ssl_trusted_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
#ssl_certificate /etc/letsencrypt/live/YOUR.DEDYN.IO/fullchain.pem;
#ssl_certificate_key /etc/letsencrypt/live/YOUR.DEDYN.IO/privkey.pem;
#ssl_trusted_certificate /etc/letsencrypt/live/YOUR.DEDYN.IO/fullchain.pem;
#ssl_dhparam /etc/ssl/certs/dhparam.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;
ssl_protocols TLSv1.2;
ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK:!AES128';
ssl_prefer_server_ciphers on;
ssl_ecdh_curve secp384r1;
#ssl_stapling on;
#ssl_stapling_verify on;
EOF
touch /etc/nginx/proxy.conf
cat <<EOF >/etc/nginx/proxy.conf
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-Host \$host;
proxy_set_header X-Forwarded-Protocol \$scheme;
proxy_set_header X-Forwarded-For \$remote_addr;
proxy_set_header X-Forwarded-Port \$server_port;
proxy_set_header X-Forwarded-Server \$host;
proxy_connect_timeout 3600;
proxy_send_timeout 3600;
proxy_read_timeout 3600;
proxy_redirect off;
EOF
touch /etc/nginx/header.conf
cat <<EOF >/etc/nginx/header.conf
add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
add_header X-Robots-Tag none;
add_header X-Download-Options noopen;
add_header X-Permitted-Cross-Domain-Policies none;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "same-origin" always;
EOF
touch /etc/nginx/optimization.conf
cat <<EOF >/etc/nginx/optimization.conf
fastcgi_read_timeout 3600;
fastcgi_buffers 64 64K;
fastcgi_buffer_size 256k;
fastcgi_busy_buffers_size 3840K;
fastcgi_cache_key \$http_cookie$request_method$host$request_uri;
fastcgi_cache_use_stale error timeout invalid_header http_500;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
gzip on;
gzip_vary on;
gzip_comp_level 4;
gzip_min_length 256;
gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
gzip_disable "MSIE [1-6]\.";
EOF
touch /etc/nginx/php_optimization.conf
cat <<EOF >/etc/nginx/php_optimization.conf
fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
fastcgi_param PATH_INFO \$fastcgi_path_info;
fastcgi_param modHeadersAvailable true;
fastcgi_param front_controller_active true;
fastcgi_intercept_errors on;
fastcgi_request_buffering off;
fastcgi_cache_valid 404 1m;
fastcgi_cache_valid any 1h;
fastcgi_cache_methods GET HEAD;
EOF
sed -i s/\#\include/\include/g /etc/nginx/nginx.conf
sed -i "s/server_name YOUR.DEDYN.IO;/server_name $(hostname);/" /etc/nginx/conf.d/nextcloud.conf
###create Nextclouds cronjob
(crontab -u www-data -l ; echo "*/15 * * * * php -f /var/www/nextcloud/cron.php > /dev/null 2>&1") | crontab -u www-data -
###restart NGINX
service nginx restart
###Download Nextclouds latest release and extract it
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjf latest.tar.bz2 -C /var/www
###apply permissions
chown -R www-data:www-data /var/www/
rm latest.tar.bz2
update_and_clean
restart_all_services
clear
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "The Nextcloud-Administrator and Password - Attention: password is case-sensitive:"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "Your Nextcloud-DB user: "$NEXTCLOUDDBUSER
echo ""
echo "Your Nextcloud-DB password: "$NEXTCLOUDDBPASSWORD
echo ""
read -p "Enter your Nextcloud Administrator: " NEXTCLOUDADMINUSER
echo "Your Nextcloud Administrator: "$NEXTCLOUDADMINUSER
echo ""
read -p "Enter your Nextcloud Administrator password: " NEXTCLOUDADMINUSERPASSWORD
echo "Your Nextcloud Administrator password: "$NEXTCLOUDADMINUSERPASSWORD
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo " NEXTCLOUD will now be installed silently - be patient ..."
sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "nextcloud"  --database-user "$NEXTCLOUDDBUSER" --database-pass "$NEXTCLOUDDBPASSWORD" --admin-user "$NEXTCLOUDADMINUSER" --admin-pass "$NEXTCLOUDADMINUSERPASSWORD" --data-dir "/var/nc_data"
declare -l YOURSERVERNAME
###read the current hostname
YOURSERVERNAME=$(hostname)
sudo -u www-data cp /var/www/nextcloud/config/config.php /var/www/nextcloud/config/config.php.bak
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value=$YOURSERVERNAME
sudo -u www-data sed -in 's/http:\/\/localhost/https:\/\/'$YOURSERVERNAME'/' /var/www/nextcloud/config/config.php
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo " Open your browser and call: https://$YOURSERVERNAME"
echo""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
exit 0
