#!/bin/bash

# This script is designed to be source'ed into your current shell
#
export CSV_FILE="/home/peter/Documents/csv/cclw-2023-10-09-docs.csv"
export CSV_EVENTS="/home/peter/Documents/csv/cclw-2023-10-09-events.csv"

#export API_HOST="http://localhost:8888"
export API_HOST="https://app.dev.climatepolicyradar.org"

# ---------- Functions ----------
get_token() {
    curl -s \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$SUPERUSER_EMAIL&password=$SUPERUSER_PASSWORD" \
        ${API_HOST}/api/tokens | \
        jq ".access_token" | tr -d '"'
}

validate_csv() {
    TOKEN=$(get_token)
    URL=${API_HOST}/api/v1/admin/bulk-ingest/validate/cclw
    echo Validating from ${URL}
    curl -v \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "law_policy_csv=@${CSV_FILE}" \
        -F "events_csv=@${CSV_EVENTS}" \
        ${URL}
}

upload_csv() {
    TOKEN=$(get_token)
    URL=${API_HOST}/api/v1/admin/bulk-ingest/cclw
    echo Uploading to ${URL}
    curl -v \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "law_policy_csv=@${CSV_FILE}" \
        -F "events_csv=@${CSV_EVENTS}" \
        ${URL}
}


if [ -z $SUPERUSER_PASSWORD $SUPERUSER_EMAIL ] ;
then
    echo env not right
else
    echo The following functions are now available:
    echo "    👉  validate_csv"
    echo "    👉  upload_csv"
    echo ""
    echo "These use teh env vars: "
    echo "    👉  API_HOST: $API_HOST"
    echo "    👉  CSV_FILE: $CSV_FILE"
    echo "    👉  CSV_EVENTS: $CSV_EVENTS"
fi
