#!/usr/bin/env bash

for id in $(docker ps -q)
do
    if [[ $(docker port "${id}") == *"${1}"* ]]; then
        echo "stopping container ${id}"
        docker stop "${id}" && docker rm "${id}"
    fi
done

# Run the following on terminal:
# /path/to/dkr-rm-container-by-port.sh EXPOSED_PORT