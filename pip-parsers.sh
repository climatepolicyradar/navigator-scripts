#!/bin/bash
# 1666196298769,
# 1667490915000
#
# 	Last event time 
# parser_job-177eea0/default/50b3476f458448b997000e5de9538c2e	
# 2022-10-21 23:10:46 (UTC+01:00)
# Create: 2022-10-21 23:06:57 (UTC+01:00)

get_log() {
    aws logs get-log-events \
    --region ${AWS_REGION} \
    --log-group-name /aws/batch/job \
    --log-stream-name $1 \
    --query 'sort_by(events,& timestamp)[*]' | \
    jq -c ".[] | (.message)"
}

HOUR_AGO=$(python -c "from datetime import datetime; n = int(round(datetime.now().timestamp())); print(1000*(n-2*60*60))")
output=$(mktemp)

aws logs describe-log-streams \
    --region ${AWS_REGION} \
    --order-by LastEventTime \
    --log-group-name /aws/batch/job \
    --query "logStreams[?creationTime > \`${HOUR_AGO}\`].{logStreamName: logStreamName}" | \
    jq ".[] | (.logStreamName)"  | \
    tr -d '"' > $output

LOGS=$PWD/logs
[ -d $LOGS ] || mkdir $LOGS
echo Writting to $LOGS
for name in $(cat $output) 
do
    LOG="$LOGS/$(echo $name | sed -e 's/\//_/g')"
    echo $name > $LOG
    get_log $name >> $LOG
done