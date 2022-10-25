#!/bin/bash

arn=$1

jqp(){
  jq 'walk(if type == "string" and .[0:2] == "{\"" then .=(.|fromjson) else . end)' "$@"
}

output=$(mktemp)

aws stepfunctions get-execution-history \
    --execution-arn $arn \
    --query 'reverse(sort_by(events,& timestamp))[*]' | jqp > $output
    
cat $output | \
    jq ".[] | {id:.id, ts: .timestamp, type:.type} + \
    ( \
        ( select(.executionFailedEventDetails) | {executionFailedEventDetails} ) \
    )"

LOG_STREAM_NAME=$(cat $output | \
    jq ".[] | \
    ( \
        ( select(.executionFailedEventDetails) | (.executionFailedEventDetails.cause.Container.LogStreamName) ) \
    )" | tr -d '"')

echo "⚠️  Found errors in LOG_STREAM_NAME=$LOG_STREAM_NAME"
echo
echo "Do you wish to proceed to view the log?"
read 
aws logs get-log-events\
  --log-group-name /aws/batch/job \
  --log-stream-name $LOG_STREAM_NAME \
  --query 'sort_by(events,& timestamp)[*]' | \
  jq -c ".[] | (.message)"