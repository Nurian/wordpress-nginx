# wordpress-nginx

This is the new VErsion with Ubuntu 16.04 LTS

How to run:
docker run -d --restart=always -p 35921:80 -p 35920:22 -e "SSH_PASSWORD=MyPassword" -e "VIRTUAL_HOST=domain.tld" -e "LETSENCRYPT_HOST=domain.tld" -e "LETSENCRYPT_EMAIL=my-mail@gmail.com" --name domain.tld legendary/wordpress-nginx
