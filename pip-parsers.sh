#!/bin/bash

# This script will create a "logs" directory underneath where it is run
# to store the logs

get_log() {
    aws logs get-log-events \
    --region ${AWS_REGION} \
    --log-group-name /aws/batch/job \
    --log-stream-name $1 \
    --query 'sort_by(events,& timestamp)[*]' | \
    jq -c ".[] | (.message)"
}

SINCE_DATE=$1
[ -z ${SINCE_DATE} ] && (echo "need a ISO datetime as an arg"; exit 1)

START=$(python -c "import dateutil.parser; print( int( round( dateutil.parser.parse(\"${SINCE_DATE}\").timestamp() * 1000 ) ) )")
echo "Start : ${SINCE_DATE} / ${START}"

output=$(mktemp)

aws logs describe-log-streams \
    --region ${AWS_REGION} \
    --order-by LastEventTime \
    --log-group-name /aws/batch/job \
    --query "logStreams[?creationTime > \`${START}\`].{logStreamName: logStreamName}" | \
    jq ".[] | (.logStreamName)"  | \
    tr -d '"' > $output

LOGS=$PWD/logs
[ -d $LOGS ] || mkdir $LOGS
TOTAL=$(wc -l $output)
echo "Writing $TOTAL file(s) to $LOGS"
echo 

for name in $(cat $output) 
do
    LOG="$LOGS/$(echo $name | sed -e 's/\//_/g')"
    grep -n $name $output 
    echo $name > $LOG
    get_log $name >> $LOG
done