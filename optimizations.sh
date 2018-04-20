#######################################################
# Carsten Rieger IT-Services
# OPTIMIZATIONS.SH
# Version 1.1
# April 19th, 2018
# version 1.1: added functions
# Version 1.0: initial script
#######################################################
#!/bin/bash
function update_and_clean() {
apt update
apt upgrade -y
apt autoclean -y
apt autoremove -y
}
function restart_all_services() {
/usr/sbin/service nginx restart
/usr/sbin/service mysql restart
/usr/sbin/service redis-server restart
/usr/sbin/service php7.2-fpm restart
}
function nextcloud_scan_data() {
sudo -u www-data php /var/www/nextcloud/occ files:scan --all
sudo -u www-data php /var/www/nextcloud/occ files:scan-app-data
fail2ban-client status nextcloud
ufw status verbose
}
cp /var/www/nextcloud/.user.ini /var/www/nextcloud/.user.ini.bak
sudo -u www-data sed -i "s/upload_max_filesize=.*/upload_max_filesize=10240M/" /var/www/nextcloud/.user.ini
sudo -u www-data sed -i "s/post_max_size=.*/post_max_size=10240M/" /var/www/nextcloud/.user.ini
sudo -u www-data sed -i "s/output_buffering=.*/output_buffering='Off'/" /var/www/nextcloud/.user.ini
sudo -u www-data cp /var/www/nextcloud/config/config.php /var/www/nextcloud/config/config.php.bak
sudo -u www-data php /var/www/nextcloud/occ background:cron
sed -i '/);/d' /var/www/nextcloud/config/config.php
cat <<EOF >>/var/www/nextcloud/config/config.php
'activity_expire_days' => 14,
'auth.bruteforce.protection.enabled' => true,
'blacklisted_files' =>
array (
0 => '.htaccess',
1 => 'Thumbs.db',
2 => 'thumbs.db',
),
'cron_log' => true,
'enable_previews' => true,
'enabledPreviewProviders' =>
array (
0 => 'OC\\Preview\\PNG',
1 => 'OC\\Preview\\JPEG',
2 => 'OC\\Preview\\GIF',
3 => 'OC\\Preview\\BMP',
4 => 'OC\\Preview\\XBitmap',
5 => 'OC\\Preview\\Movie',
6 => 'OC\\Preview\\PDF',
7 => 'OC\\Preview\\MP3',
8 => 'OC\\Preview\\TXT',
9 => 'OC\\Preview\\MarkDown',
),
'filesystem_check_changes' => 0,
'filelocking.enabled' => 'true',
'htaccess.RewriteBase' => '/',
'integrity.check.disabled' => false,
'knowledgebaseenabled' => false,
'logtimezone' => 'Europe/Berlin',
'log_rotate_size' => 104857600,
'memcache.local' => '\\OC\\Memcache\\APCu',
'memcache.locking' => '\\OC\\Memcache\\Redis',
'preview_max_x' => 1024,
'preview_max_y' => 768,
'preview_max_scale_factor' => 1,
'redis' =>
array (
'host' => '/var/run/redis/redis.sock',
'port' => 0,
'timeout' => 0.0,
),
'quota_include_external_storage' => false,
'share_folder' => '/Shares',
'skeletondirectory' => '',
'trashbin_retention_obligation' => 'auto, 7',
);
EOF
restart_all_services
update_and_clean
apt install fail2ban -y
touch /etc/fail2ban/filter.d/nextcloud.conf
cat <<EOF >/etc/fail2ban/filter.d/nextcloud.conf
[Definition]
failregex=^{"reqId":".*","remoteAddr":".*","app":"core","message":"Login failed: '.*' \(Remote IP: '<HOST>'\)","level":2,"time":".*"}\$
^{"reqId":".*","level":2,"time":".*","remoteAddr":".*","app":"core".*","message":"Login failed: '.*' \(Remote IP: '<HOST>'\)".*}\$
^.*\"remoteAddr\":\"<HOST>\".*Trusted domain error.*\$
EOF
touch /etc/fail2ban/jail.d/nextcloud.local
cat <<EOF >/etc/fail2ban/jail.d/nextcloud.local
[nextcloud]
backend = auto
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 36000
findtime = 36000
logpath = /var/nc_data/nextcloud.log
EOF
update_and_clean
apt install ufw -y
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw enable
/usr/sbin/service ufw restart
/usr/sbin/service fail2ban restart
/usr/sbin/service redis-server restart
redis-cli -s /var/run/redis/redis.sock <<EOF
FLUSHALL
quit
EOF
restart_all_services
nextcloud_scan_data
exit 0
