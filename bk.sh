#!/usr/bin/env bash
# Put an auto-timestamp on a file backup.

if [[ ! $1 ]]; then
    echo "Usage: $0 file"
    exit 1
fi


DIR=$(pwd)

DATE=$(TZ="UTC"  date --iso-8601='seconds')

#echo $DATE $DIR
if [ -f "$DIR"/"$1"  ]; then
  cp -aux "$DIR"/"$1" "$DIR"/"$1"."$DATE"
else
  echo "File does not exist, check path."
fi

exit 0
