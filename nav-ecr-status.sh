#!/bin/bash

###############################################################################
# nav-ecr
#
# Shows the recent images for each ECR repo
#
###############################################################################

# Command to use to look at what repositories are available
# aws ecr describe-repositories

header() {
    echo
    echo
    echo -n "👉👉👉  $(tput setaf 0)$(tput setab 7) "
    echo "  $1   $(tput sgr0)  👈👈👈"
}

show_status () {
    repo=$1
    header $repo
        # Get latest 3 entries
    aws ecr describe-images --repository-name $repo-$2 \
        --query 'reverse(sort_by(imageDetails,& imagePushedAt))[0:3]'| \
        jq ".[] | { repo: .repositoryName, tags: .imageTags, pushed: .imagePushedAt, size: .imageSizeInBytes, digest: .imageDigest }"
}


REPOS=(\
"navigator-data-ingest"
"navigator-document-preparser"
"navigator-pipeline-run-tests"
"navigator-document-parser"
"navigator-search-indexer"
)

for repo in "${REPOS[@]}"
do  
    show_status $repo staging
done
