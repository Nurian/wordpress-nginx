# wordpress-nginx

This is the Version with Ubuntu 16.04 LTS and php7.1

```bash
set -a
source /var/docker-data/env/example.com.env
docker-compose pull
docker-compose -p $P_DOMAIN up -d
```
