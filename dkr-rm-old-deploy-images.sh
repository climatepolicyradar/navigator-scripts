#!/bin/bash

###############################################################################
# See docs/dkr-rm-old-deploy-images.md
###############################################################################
docker images | grep amazonaws.com | grep -v latest | cut -c 150-162 | xargs docker rmi
