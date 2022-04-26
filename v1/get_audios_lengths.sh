#!/usr/bin/env bash

AUDIO_DIR=$1
LIST=$2
OUT_FILE=$3

mkdir -p $(dirname $OUT_FILE)
rm -f $OUT_FILE
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [ ${LIST: -4} == ".scp" ]; then
		utt=$(cut -d "=" -f 1 <<< "$line")
		path=$(cut -d "=" -f 2 <<< "$line")
	else
		utt=$line
		path=$line
	fi

	length=$(sox $AUDIO_DIR/$path.* -n stat 2>&1 | sed -n 's#^Length (seconds):[^0-9]*\([0-9.]*\)$#\1#p')
	echo $utt" "$length >> $OUT_FILE
done < $LIST
