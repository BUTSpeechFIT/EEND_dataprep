#!/usr/bin/env bash
. ./path.sh

DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

LIST=$DIR/VoxCeleb2_30s_10dB.txt
# This directory contains one raw file before cutting segments. Change if necessary
RAW_DIR=<raw directory>

if [ ! -d $DIR/Kaldidatadir/all ]; then
	mkdir -p $DIR/Kaldidatadir/all
	awk -v RAW_DIR=$RAW_DIR '{print $1" ffmpeg -f s16le -ar 16k -ac 1 -i "RAW_DIR"/"$1".raw -f wav pipe:1 |"}' $LIST > $DIR/Kaldidatadir/all/wav.scp
	awk -F"/" '{print $0" "$1"/"$2"/"$3"/"$4}' $LIST > $DIR/Kaldidatadir/all/utt2spk
	$KALDI_ROOT/egs/wsj/s5/utils/utt2spk_to_spk2utt.pl $DIR/Kaldidatadir/all/utt2spk > $DIR/Kaldidatadir/all/spk2utt
fi


if [ ! -d $DIR/Kaldidatadir/train ]; then
	mkdir -p $DIR/Kaldidatadir/train $DIR/Kaldidatadir/validation
	awk -F"/" '{print $4}' $LIST | sort -u > $DIR/Kaldidatadir/all/speakers
	shuf --random-source=<(yes 3) $DIR/Kaldidatadir/all/speakers > $DIR/Kaldidatadir/all/speakers"_shuf"
	# Leave 5% of speakers for validation
	head -n 291 $DIR/Kaldidatadir/all/speakers"_shuf" > $DIR/Kaldidatadir/validation/speakers
	tail -n $(($(wc -l $DIR/Kaldidatadir/all/speakers"_shuf" | awk '{print $1}') - 291)) $DIR/Kaldidatadir/all/speakers"_shuf" > $DIR/Kaldidatadir/train/speakers

	grep -f $DIR/Kaldidatadir/validation/speakers $DIR/Kaldidatadir/all/wav.scp | sort -u > $DIR/Kaldidatadir/validation/wav.scp
	grep -f $DIR/Kaldidatadir/validation/speakers $DIR/Kaldidatadir/all/spk2utt | sort -u > $DIR/Kaldidatadir/validation/spk2utt
	grep -f $DIR/Kaldidatadir/validation/speakers $DIR/Kaldidatadir/all/utt2spk | sort -u > $DIR/Kaldidatadir/validation/utt2spk
	grep -f $DIR/Kaldidatadir/train/speakers $DIR/Kaldidatadir/all/wav.scp | sort -u > $DIR/Kaldidatadir/train/wav.scp
	grep -f $DIR/Kaldidatadir/train/speakers $DIR/Kaldidatadir/all/spk2utt | sort -u > $DIR/Kaldidatadir/train/spk2utt
	grep -f $DIR/Kaldidatadir/train/speakers $DIR/Kaldidatadir/all/utt2spk | sort -u > $DIR/Kaldidatadir/train/utt2spk
fi
