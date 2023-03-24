#!/bin/bash

while getopts ":d:e:" OPTION
do 
   case $OPTION in
       d)
        # this option specifies the documents csv
        export CSV_DOCS="$OPTARG"
        ;;
       e)
        # this option specifies the events csv
        export CSV_EVENTS="$OPTARG"
        ;;
       ?)
         echo "Usage: $(basename $0) -d <PATH_TO_DOCS_CSV> -e <PATH_TO_EVENTS_CSV>"
         exit 1
        ;;
     esac
done

if [[ -z "$CSV_DOCS" ]]; then
    echo "Usage: $(basename $0) -d <PATH_TO_DOCS_CSV> -e <PATH_TO_EVENTS_CSV>"
    exit 1
fi
if [[ -z "$CSV_EVENTS" ]]; then
    echo "Usage: $(basename $0) -d <PATH_TO_DOCS_CSV> -e <PATH_TO_EVENTS_CSV>"
    exit 1
fi

export API_HOST="http://localhost:8888"
export SUPERUSER_EMAIL="user@navigator.com"
SUPERUSER_PASSWORD="password"

clear

# ---------- Functions ----------

get_token() {
    curl -s \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$SUPERUSER_EMAIL&password=$SUPERUSER_PASSWORD" \
        ${API_HOST}/api/tokens | \
        jq ".access_token" | tr -d '"'
}

upload_csv() {
    TOKEN=$(get_token)
    URL=${API_HOST}/api/v1/admin/bulk-ingest/cclw/law-policy 
    echo Uploading to ${URL}
    curl -v \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "law_policy_csv=@${CSV_DOCS}" \
        -F "events_csv=@${CSV_EVENTS}" \
        ${URL}
}

# ---------- Script ----------

echo -n "👉👉👉  Uploading CSV"
set -x
upload_csv

set +x
echo -n "👉👉👉  Now go and check the log output!"
