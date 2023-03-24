#!/bin/bash

# Instructions on how the psql volume was created:
#    docker-compose up -d backend_db
#    psql  postgres
#      drop then  create database navigator
#    psql -f ~/Documents/dumps/prod_dump_2023_03_20.sql
#    psql
#      delete from public.user
#    docker-compose down
#    dkr-copy-volume.sh navigator-backend_db-data-backend prod-v10

set -euo pipefail

echo Script needs: 
echo "    - a NAVIGATOR_CODE_ROOT env var set to a folder containing checked out navigator projects"
echo "    - to have the navigator_scripts folder in your PATH"
echo "    - to have a prod-database volume"

cd "${NAVIGATOR_CODE_ROOT}/navigator-backend"
docker-compose down

docker volume rm navigator-backend_db-data-backend
dkr-copy-volume.sh prod-v10 navigator-backend_db-data-backend

make start
