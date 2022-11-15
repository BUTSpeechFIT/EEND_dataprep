#!/usr/bin/env bash
. ./path.sh

DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

WAV_DIR=<VoxPopuli audios dir>

if [ ! -d $DIR/Kaldidatadir/all ]; then
	mkdir -p $DIR/Kaldidatadir/all
	find $WAV_DIR -type f | sed "s $WAV_DIR/  g" | sed 's/....$//' > $DIR/Kaldidatadir/all/files.txt
	awk -v WAV_DIR=$WAV_DIR -F"/" '{print $1"_"$2"_"$3" "WAV_DIR"/"$0".wav"}' $DIR/Kaldidatadir/all/files.txt > $DIR/Kaldidatadir/all/wav.scp
	awk -F"/" '{print $1"_"$2"_"$3" "$1"_"$2}' $DIR/Kaldidatadir/all/files.txt > $DIR/Kaldidatadir/all/utt2spk
	$KALDI_ROOT/egs/wsj/s5/utils/utt2spk_to_spk2utt.pl $DIR/Kaldidatadir/all/utt2spk > $DIR/Kaldidatadir/all/spk2utt
fi


if [ ! -d $DIR/Kaldidatadir/train ]; then
	mkdir -p $DIR/Kaldidatadir/train $DIR/Kaldidatadir/validation
	awk '{print $1}' $DIR/Kaldidatadir/all/spk2utt | sort -u > $DIR/Kaldidatadir/all/speakers
	shuf --random-source=<(yes 3) $DIR/Kaldidatadir/all/speakers > $DIR/Kaldidatadir/all/speakers"_shuf"
	
	# Leave 5% of speakers for validation
	head -n 123 $DIR/Kaldidatadir/all/speakers"_shuf" > $DIR/Kaldidatadir/validation/speakers
	tail -n $(($(wc -l $DIR/Kaldidatadir/all/speakers"_shuf" | awk '{print $1}') - 123)) $DIR/Kaldidatadir/all/speakers"_shuf" > $DIR/Kaldidatadir/train/speakers

	grep -f $DIR/Kaldidatadir/validation/speakers $DIR/Kaldidatadir/all/wav.scp | sort -u > $DIR/Kaldidatadir/validation/wav.scp
	grep -f $DIR/Kaldidatadir/validation/speakers $DIR/Kaldidatadir/all/spk2utt | sort -u > $DIR/Kaldidatadir/validation/spk2utt
	grep -f $DIR/Kaldidatadir/validation/speakers $DIR/Kaldidatadir/all/utt2spk | sort -u > $DIR/Kaldidatadir/validation/utt2spk
	grep -f $DIR/Kaldidatadir/train/speakers $DIR/Kaldidatadir/all/wav.scp | sort -u > $DIR/Kaldidatadir/train/wav.scp
	grep -f $DIR/Kaldidatadir/train/speakers $DIR/Kaldidatadir/all/spk2utt | sort -u > $DIR/Kaldidatadir/train/spk2utt
	grep -f $DIR/Kaldidatadir/train/speakers $DIR/Kaldidatadir/all/utt2spk | sort -u > $DIR/Kaldidatadir/train/utt2spk
fi
