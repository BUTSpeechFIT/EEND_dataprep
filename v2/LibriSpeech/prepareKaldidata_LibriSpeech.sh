#!/usr/bin/env bash
. ./path.sh

DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

orig_path=`pwd` ; cd $KALDI_ROOT/egs/librispeech/s5
# format the data as Kaldi data directories
for part in dev-clean test-clean dev-other test-other train-clean-100 train-clean-360 train-other-500; do
    if [ ! -d $DIR/Kaldidatadir/$(echo $part | sed s/-/_/g) ]; then
        # use underscore-separated names in data directories.
        local/data_prep.sh $LSDIR/LibriSpeech/$part $DIR/Kaldidatadir/$(echo $part | sed s/-/_/g)
        for file in spk2gender spk2utt text utt2spk wav.scp; do
            sed -i 's/lbi-//g' $DIR/Kaldidatadir/$(echo $part | sed s/-/_/g)/$file
        done
    fi
done
cd $orig_path


if [ ! -d $DIR/Kaldidatadir/alltrain ]; then
    mkdir -p $DIR/Kaldidatadir/alltrain

    orig_path=`pwd` ; cd $KALDI_ROOT/egs/librispeech/s5
    utils/combine_data.sh $DIR/Kaldidatadir/alltrain \
        $DIR/Kaldidatadir/train_clean_100 \
        $DIR/Kaldidatadir/train_clean_360 $DIR/Kaldidatadir/train_other_500
    cd $orig_path
fi


for set in dev_clean alltrain; do
    if [ ! -d $DIR/Kaldidatadir/"$set"_persession ]; then
        mkdir -p $DIR/Kaldidatadir/"$set"_persession/wavs
        while read line; do
            spk_session=$(echo $line | awk '{print $1}')
            utterances=$(grep $spk_session $DIR/Kaldidatadir/"$set"/wav.scp | awk '{print $6}' | paste -sd " " -)
            sox $utterances $DIR/Kaldidatadir/"$set"_persession/wavs/$spk_session.flac
            spk=$(echo $spk_session | awk -F"-" '{print $1}')
            session=$(echo $spk_session | awk -F"-" '{print $2}')
            echo $spk_session" "$spk >> $DIR/Kaldidatadir/"$set"_persession/utt2spk
            echo $spk_session" flac -c -d -s "$DIR/Kaldidatadir/"$set"_persession/wavs/$spk_session.flac" |" >> $DIR/Kaldidatadir/"$set"_persession/wav.scp
        done < $DIR/Kaldidatadir/"$set"/spk2utt
        $KALDI_ROOT/egs/wsj/s5/utils/utt2spk_to_spk2utt.pl $DIR/Kaldidatadir/"$set"_persession/utt2spk > $DIR/Kaldidatadir/"$set"_persession/spk2utt
    fi
done
