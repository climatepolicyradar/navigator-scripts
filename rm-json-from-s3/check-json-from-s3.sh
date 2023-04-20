#!/bin/sh

# Assumes environment setup for AWS
# Removes json files where no corresponding npy file is found.
# Usage: Provide S3 prefix in env var below

PREFIX=cpr-staging-data-pipeline-cache/indexer_input/

# Start of script
#aws s3 ls ${PREFIX} | cut -c 32- | sort > full_files
# Assumes we have four dots
cat full_files  | cut -d '.' -f1-4 | sort | uniq > bare_files

for file in $(cat bare_files)
do
  json_found=$(grep "^${file}.json$" full_files)
  npy_found=$(grep "^${file}.npy$" full_files)

  #echo "$file, $json_found, |${npy_found}|"

  if [ -z $npy_found ]
  then
    echo Orphan: $file s3://$PREFIX$json_found 
  fi
done

