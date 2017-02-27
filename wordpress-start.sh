#!/bin/bash
  chown -R www-data:www-data /usr/share/nginx/www/

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
