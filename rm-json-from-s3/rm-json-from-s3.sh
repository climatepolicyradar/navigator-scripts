#!/bin/sh

# Removes json files where no corresponding npy file is found.
# Usage: Provide S3 prefix in env var below

PREFIX=cpr-staging-data-pipeline-cache/indexer_input/

# Start of script
aws s3 ls ${PREFIX} | cut -c 32- | sort > full_files
cat full_files  | cut -d '.' -f1-4 | sort | uniq > bare_files
echo -n "aws s3 rm " >  files_to_remove

for file in $(cat bare_files)
do
  json_found=$(grep "${file}.json" full_files)
  npy_found=$(grep "${file}.npy" full_files)

  echo $file, $json_found, $npy_found
  if [ -z $npy_found ]
  then
    echo -n "$PREFIX/$json_found " >> files_to_remove
  fi
done

echo Done
