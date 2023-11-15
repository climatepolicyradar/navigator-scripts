#!/bin/bash

# This script is designed to be source'ed into your current shell
#
export CSV_FILE="/home/peter/Documents/csv/unfccc-documents-2023-11-15.csv"
export CSV_COLS="/home/peter/Documents/csv/unfccc-collections-2023-11-15.csv"

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
    URL=${API_HOST}/api/v1/admin/bulk-ingest/validate/unfccc
    echo Validating from ${URL}
    curl -v \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "unfccc_data_csv=@${CSV_FILE}" \
        -F "collection_csv=@${CSV_COLS}" \
        ${URL}
}

upload_csv() {
    TOKEN=$(get_token)
    URL=${API_HOST}/api/v1/admin/bulk-ingest/unfccc
    echo Uploading to ${URL}
    curl -v \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "unfccc_data_csv=@${CSV_FILE}" \
        -F "collection_csv=@${CSV_COLS}" \
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
    echo "    👉  CSV_COLS: $CSV_COLS"
fi
