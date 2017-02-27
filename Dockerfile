FROM primehost/nginx
MAINTAINER Kevin Nordloh <mail@legendary-server.de>

# update before install
RUN apt-get update
RUN apt-get -y upgrade

RUN apt-get -y install mysql-server

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# clean up unneeded packages
RUN apt-get --purge autoremove -y

# Install Wordpress
ADD http://wordpress.org/latest.tar.gz /usr/share/nginx/latest.tar.gz
RUN cd /usr/share/nginx/ \
    && tar xvf latest.tar.gz \
    && rm latest.tar.gz

RUN mv /usr/share/nginx/wordpress /usr/share/nginx/www \
    && chown -R www-data:www-data /usr/share/nginx/www \
    && chmod -R 775 /usr/share/nginx/www

# Wordpress Initialization and Startup Script
ADD ./wordpress-start.sh /wordpress-start.sh
RUN chmod 755 /wordpress-start.sh

CMD ["/bin/bash", "/wordpress-start.sh"]
