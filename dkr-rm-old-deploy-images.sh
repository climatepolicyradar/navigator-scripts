#!/bin/bash

###############################################################################
# dkr-rm-old-deploy-images
#
# Removes all but the latest deployed docker images. Having the latest ones
# locally is advantageous as it speeds up deployment.
###############################################################################
docker images | grep amazonaws.com | grep -v latest | cut -c 152-162 | xargs docker rmi
