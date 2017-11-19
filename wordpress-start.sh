#!/bin/bash

# Create custom ssh_user with sudo privileges
useradd -m -d /home/$PRIMEHOST_USER -G root -s /bin/bash $PRIMEHOST_USER \
	&& usermod -a -G $PRIMEHOST_USER $PRIMEHOST_USER \
	&& usermod -a -G sudo $PRIMEHOST_USER

# Set passwords for the ssh_user and root
echo "$PRIMEHOST_USER:$PRIMEHOST_PASSWORD" | chpasswd
echo "root:$PRIMEHOST_PASSWORD" | chpasswd

# Custom user for nginx and php
sed -i s/www-data/$PRIMEHOST_USER/g /etc/nginx/nginx.conf
sed -i s/www-data/$PRIMEHOST_USER/g /etc/php/7.0/fpm/pool.d/www.conf

if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
# Download wordpress
cd /usr/share/nginx/ \
   && curl -o latest.tar.gz -fSL "https://wordpress.org/latest.tar.gz" \
   && tar xvf latest.tar.gz
# Move to correct folder and cleanup
mv /usr/share/nginx/wordpress/* /usr/share/nginx/www/. \
    && chown -R $PRIMEHOST_USER:$PRIMEHOST_USER /usr/share/nginx/www \
    && rm -r /usr/share/nginx/wordpress \
    && rm latest.tar.gz
fi

# install wordpress cli
sudo -u $PRIMEHOST_USER bash << EOF
cd /usr/share/nginx/www/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
EOF

# create wp shortcut for wp-cli 
mv wp-cli.phar /usr/local/bin/wp

# setup db connection and create admin user
sudo -u $PRIMEHOST_USER bash << EOF
wp config create --dbname=wordpress --dbuser=root --dbhost=${DOMAIN}-db --dbpass=$PRIMEHOST_PASSWORD
sed -i -e '/table_prefix/a\
$_SERVER[HTTPS] = on;' /usr/share/nginx/www/wp-config.php
wp core install --url=${DOMAIN} --title=${DOMAIN} --admin_user=$PRIMEHOST_USER --admin_password=$PRIMEHOST_PASSWORD --admin_email=$P_MAIL
EOF

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
