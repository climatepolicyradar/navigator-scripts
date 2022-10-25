#!/bin/bash

arn=$1

aws stepfunctions list-executions \
    --state-machine-arn $arn \
    --query 'reverse(sort_by(executions,& startDate))[0:10]' | \
    jq -c ".[] | (.executionArn),{ name: .name, start: .startDate, status: .status}"
