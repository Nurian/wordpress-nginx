FROM primehost/nginx
MAINTAINER Kevin Nordloh <mail@legendary-server.de>

# update before install
RUN apt-get update
RUN apt-get -y upgrade

# clean up unneeded packages
RUN apt-get --purge autoremove -y
RUN rm -r /usr/share/nginx/www

# Wordpress Initialization and Startup Script
ADD ./wordpress-start.sh /wordpress-start.sh
RUN chmod 755 /wordpress-start.sh

CMD ["/bin/bash", "/wordpress-start.sh"]
