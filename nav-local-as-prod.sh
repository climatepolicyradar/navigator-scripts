#!/bin/bash

echo Script needs: 
echo "    - to be run in the root of the backed repo."
echo "    - to have a prod-database volume"

docker-compose down
docker volume rm navigator-backend_db-data-backend 
dkr-copy-volume.sh prod-database navigator-backend_db-data-backend 
make start
