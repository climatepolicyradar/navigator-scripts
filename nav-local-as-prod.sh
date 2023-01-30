#!/bin/bash

set -euo pipefail

echo Script needs: 
echo "    - to be run in the root of the backed repo."
echo "    - to have a prod-database volume"

make stop
docker rm navigator-backend_backend_1 navigator-backend_backend_db_1 || echo Skipped
docker volume rm navigator-backend_db-data-backend 
dkr-copy-volume.sh prod-database navigator-backend_db-data-backend 
make start_backendonly
    
