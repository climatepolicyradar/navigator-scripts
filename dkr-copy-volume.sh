#!/bin/bash

###############################################################################
# See: docs/dkr-copy-volume.md
###############################################################################

SRC=$1
DEST=$2

test -z "${SRC}" && (echo "no source volume" ; exit 1)
test -z "${DEST}" && (echo "no destination volume" ; exit 1)

# Create volume if not existing
docker volume ls | grep ${DEST} || docker volume create --name ${DEST}

# Do the copy
docker run --rm -it -v ${SRC}:/from -v ${DEST}:/to alpine ash -c "cd /from ; cp -av . /to"

docker volume ls
