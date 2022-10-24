#!/bin/bash

###############################################################################
# dkr-copy-volume
#
# Copies one docker volume to another - used for copying the postgres volume 
# `navigator_db-data-backend`
#
# EXAMPLE:
#   dk-copy-volume prod-database navigator_db-data-backend
#
# References: 
#   https://github.com/moby/moby/issues/31154#issuecomment-360531460
#   https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes
#
###############################################################################
SRC=$1
DEST=$2

test -z "${SRC}" && (echo "no source volume" ; exit 1)
test -z "${DEST}" && (echo "no destination volume" ; exit 1)

# Create bolume if not existing
docker volume ls | grep ${DEST} || docker volume create --name ${DEST}

# Do the copy
docker run --rm -it -v ${SRC}:/from -v ${DEST}:/to alpine ash -c "cd /from ; cp -av . /to"

docker volume ls
