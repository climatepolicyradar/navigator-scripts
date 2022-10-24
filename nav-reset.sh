#!/bin/bash

###############################################################################
# nav-reset
#
# In the main `navigator` repo this will stop the containers and remove the
# postgres volume. Ready for a fresh restart.
#
###############################################################################
cd $(git rev-parse --show-toplevel)
make stop; docker-compose down; docker volume rm navigator_db-data-backend
