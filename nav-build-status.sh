#!/bin/bash

###############################################################################
# nav-build-status
#
# Shows the recent results of the github actions for each repo
#
###############################################################################

header() {
    echo
    echo
    echo -n "👉👉👉  $(tput setaf 0)$(tput setab 7) "
    echo "  $1   $(tput sgr0)  👈👈👈"
}

show_status () {
    repo=$1
    header $repo
    gh workflow view -R $repo CI
}

REPOS=(\
    "navigator" \
    "navigator-data-ingest" \
    "navigator-document-preparser" \
    "navigator-document-parser" \
    "navigator-search-indexer" \
    "navigator-pipeline-reporter" \
)

echo $REPOS

for repo in "${REPOS[@]}"
do
    show_status https://github.com/climatepolicyradar/$repo
done