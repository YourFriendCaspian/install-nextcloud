# Carsten Rieger IT-Services
# SSL-CERTIFICATE.SH
# Version 1.0
# April 20th, 2018
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
function copy4SSL() {
cp /etc/nginx/conf.d/nextcloud.conf /etc/nginx/conf.d/nextcloud.conf.orig
cp /etc/nginx/ssl.conf /etc/nginx/ssl.conf.orig
cp /var/www/nextcloud/config/config.php /var/www/nextcloud/config/config.php.orig
}
function errorSSL() {
clear
echo "*** ERROR while requeting your certificate(s) ***"
echo ""
echo "Verify that both ports (80 + 443) are forwarded to this server!"
echo "And verify, your dyndns points to your IP either!"
echo "Then retry..."
}
add-apt-repository ppa:certbot/certbot -y
update_and_clean
apt install letsencrypt -y
declare -l DYNDNSNAME
declare -l YOURSERVERNAME
YOURSERVERNAME=$(hostname)
read -p "Your domain: " DYNDNSNAME
letsencrypt certonly -a webroot --webroot-path=/var/www/letsencrypt --rsa-key-size 4096 -d $DYNDNSNAME
if [ ! -d "/etc/letsencrypt/live" ]; then
errorSSL
else
copy4SSL
sed -i '/ssl-cert-snakeoil/d' /etc/nginx/ssl.conf
sed -i "s/server_name.*;/server_name $DYNDNSNAME;/" /etc/nginx/conf.d/nextcloud.conf
sed -in 's/YOUR.DEDYN.IO/'$DYNDNSNAME'/' /etc/nginx/ssl.conf
sed -i s/\#\ssl/\ssl/g /etc/nginx/ssl.conf
sed -i s/ssl_dhparam/\#ssl_dhparam/g /etc/nginx/ssl.conf
sudo -u www-data sed -in 's/'$YOURSERVERNAME'/'$DYNDNSNAME'/' /var/www/nextcloud/config/config.php
restart_all_services
clear
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo " Call: https://$DYNDNSNAME and enjoy your Nextcloud"
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
fi
exit 0