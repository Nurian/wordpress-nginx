#!/bin/bash

# Create custom ssh_user with sudo privileges
useradd -m -d /home/$PRIMEHOST_USER -G root -s /bin/bash $PRIMEHOST_USER \
	&& usermod -a -G $PRIMEHOST_USER $PRIMEHOST_USER \
	&& usermod -a -G sudo $PRIMEHOST_USER

# Set passwords for the ssh_user and root
echo "$PRIMEHOST_USER:$PRIMEHOST_PASSWORD" | chpasswd
echo "root:$PRIMEHOST_PASSWORD" | chpasswd

# Download wordpress
cd /usr/share/nginx/ \
   && curl -o latest.tar.gz -fSL "https://wordpress.org/latest.tar.gz" \
   && tar xvf latest.tar.gz

# Move to correct folder and cleanup
mv /usr/share/nginx/wordpress/* /usr/share/nginx/www/. \
    && chown -R www-data:www-data /usr/share/nginx/www \
    && chmod -R 775 /usr/share/nginx/www \
    && rm -r /usr/share/nginx/wordpress \
    && rm latest.tar.gz

# Databse Setup
if [ ! -f /wordpress-db-pw.txt ]; then

    # Databse Stuff
    mysqladmin -u root password $MYSQL_PASSWORD
    mysql -uroot -p$PRIMEHOST_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$PRIMEHOST_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$PRIMEHOST_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'mysql' IDENTIFIED BY '$PRIMEHOST_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld
fi

if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
    WORDPRESS_DB="wordpress"
    WORDPRESS_PASSWORD=`cat /wordpress-db-pw.txt`
    WORDPRESS_DB_USER="root"
    WORDPRESS_DB_HOST="db.${DOMAIN}"
    sed -e "s/database_name_here/$WORDPRESS_DB/
    s/username_here/root/
    s/password_here/$PRIMEHOST_PASSWORD/
    s/localhost/mysql/
    /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

    # Download nginx helper plugin
    curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
    unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins

    # Activate nginx plugin and set up pretty permalink structure once logged in
    cat << ENDL >> /usr/share/nginx/www/wp-config.php
    \$plugins = get_option( 'active_plugins' );
    if ( count( \$plugins ) === 0 ) {
    require_once(ABSPATH .'/wp-admin/includes/plugin.php');
    \$wp_rewrite->set_permalink_structure( '/%postname%/' );
    \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
    foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    }
    }
    }
ENDL

# Add https proxy support for wordpres
sed -i -e '/WP_DEBUG/a\
$_SERVER[HTTPS] = on;' /usr/share/nginx/www/wp-config.php

    chown -R www-data:www-data /usr/share/nginx/www/
    dos2unix /usr/share/nginx/www/wp-config.php

fi


# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
