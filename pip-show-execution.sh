#!/bin/bash

arn=$1

jqp(){
  jq 'walk(if type == "string" and .[0:2] == "{\"" then .=(.|fromjson) else . end)' "$@"
}

output=$(mktemp)

aws stepfunctions get-execution-history \
    --execution-arn $arn \
    --query 'reverse(sort_by(events,& timestamp))[*]' | jqp 