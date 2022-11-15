#!/usr/bin/env bash

# @Authors: Federico Landini, Mireia Diez
# @Emails: landini@fit.vutbr.cz, mireia@fit.vutbr.cz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Scripts for artificially creating conversations out of LibriSpeech

DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

. $DIR/config_variables.sh

LISTS_DIR=$WORKDIR/lists
mkdir -p $LISTS_DIR

LIST_FILE_TR=$LISTS_DIR/alltrain.str
LIST_FILE_VAL=$LISTS_DIR/dev_clean.str
SEG_LIST_FILE=$LISTS_DIR/librispeech
CONV_VAL_LIST=$LISTS_DIR/conv_list_val
CONV_TR_LIST=$LISTS_DIR/conv_list_tr
STATS_DIR=$WORKDIR/stats

CONV_DIR=$WORKDIR/conversations
CONV_TR_DIR=$CONV_DIR/train
CONV_VAL_DIR=$CONV_DIR/validation

COMMON_DATA_TR_DIR=$WORKDIR/data/train
COMMON_DATA_VAL_DIR=$WORKDIR/data/validation

SET_DIR=$WORKDIR/$use_rirs$use_noises
WAVS_TR_DIR=$SET_DIR/train/wavs
DATA_TR_DIR=$SET_DIR/train/data
WAVS_VAL_DIR=$SET_DIR/validation/wavs
DATA_VAL_DIR=$SET_DIR/validation/data

DATA_VAL_SUBSET_DIR=$SET_DIR/validation/data_subset
DATA_TEST3h_DIR=$SET_DIR/test3h/data


if [ ! -f $STATS_DIR ]; then
    echo "Processing RTTMs to obtain statistics about turns"
    mkdir -p $STATS_DIR

    # TODO: Replace awk by python
    # awk determines the type of overlap between pairs of consecutive segments.
    # For each case, the length of the overlap is calculated. The categories are: 
    # 'takeover', when, after the overlap, the second speaker keeps speaking
    # 'interrupt', when, after the overlap, the second speaker stops
    # 'both', when both speakers end the overlap simultaneously
    cat $RTTMS_FILE | awk '{if(NR==1 || !match($2,file)){endt=$4+$5;file=$2}else{if(endt>$4){if($4+$5>endt){print "takeover",-(endt-$4);endt=$4+$5}else{if(endt>$4+$5){print "interrupt",-(endt-$4)}else{print "both",-$5}}}else{endt=$4+$5}}}' > $STATS_DIR/overlaps_info.txt

    DISTSNAME=newspk_samespk_pause_distribution_overlap_distribution
    # TODO: Replace awk by python
    # awk determines the nature of consecutive segments and calculates lengths
    # 'same spk', when the segments belong to the same speaker (length of the pause)
    # 'new spk', when the segments belong to different speakers (length of the pause)
    # 'overlap', when segments overlap (length of the overlap)
    cat $RTTMS_FILE | awk '{if(NR==1 ||!match($2,file)){file=$2;spk=$8;init=$4;end=$4+$5}else{if(match($8,spk)){print "same spk, pause",$4-end;init=$4;end=$4+$5}else{if($4>end){print "new spk, pause",$4-end;end=$4+$5;init=$4;spk=$8}else{if($4+$5>end){print "overlap",end-$4;end=$4+$5;init=$4;spk=$8}else{print "overlap",$5}}}}}' > $STATS_DIR/$DISTSNAME.txt
    grep "same spk, pause" $STATS_DIR/$DISTSNAME.txt | awk '{printf "%.2f\n", $NF}' | \
        sort -n | uniq -c > $STATS_DIR/same_spk_pause.txt
    grep "new spk, pause"  $STATS_DIR/$DISTSNAME.txt | awk '{printf "%.2f\n", $NF}' | \
        sort -n | uniq -c > $STATS_DIR/diff_spk_pause.txt
    grep "same spk, pause" $STATS_DIR/$DISTSNAME.txt | awk '{$NF=""; print}' | \
        sort -n | uniq -c > $STATS_DIR/diff_spk_pause_vs_overlap.txt
    cat $STATS_DIR/overlaps_info.txt | awk '{printf "%.2f\n", -$2}' | \
        sort -n | uniq -c > $STATS_DIR/diff_spk_overlap.txt
    echo "----- STATISTICS GENERATED -----"
fi


if [ ! -f $SEG_LIST_FILE"_tr" ]; then
    echo "Processing segments"    
    # process segments train
    cat $SEG_FILE_TR | awk '{print $2" "$3" "$4}' | awk -F"-" '{print $1" "$1"-"$2}' > $LIST_FILE_TR
    # process segments validation
    cat $SEG_FILE_VAL | awk '{print $2" "$3" "$4}' | awk -F"-" '{print $1" "$1"-"$2}' > $LIST_FILE_VAL

    cat $LIST_FILE_TR > $SEG_LIST_FILE"_tr"
    cat $LIST_FILE_VAL > $SEG_LIST_FILE"_val"
    echo "----- SEGMENTS PROCESSED -----"
fi


if [ ! -d $CONV_VAL_DIR ]; then
    echo "Generating conversations for the validation set"
    mkdir -p $CONV_VAL_DIR
    python3 $DIR/conv_generator.py --stats-dir $STATS_DIR \
        --seg-list-file $SEG_LIST_FILE"_val" --out-conv-dir $CONV_VAL_DIR \
        --determine-spks $DETSPKS --num-spks $NUMSPKS \
        --audio-amount $AUDIOAMOUNTVAL --sampling-frequency $SAMPLINGFREQ
    echo "----- VALIDATION CONVERSATIONS GENERATED -----"
fi


if [ ! -d $CONV_TR_DIR ]; then
    echo "Generating conversations for the train set"
    mkdir -p $CONV_TR_DIR
    python3 $DIR/conv_generator.py --stats-dir $STATS_DIR \
        --seg-list-file $SEG_LIST_FILE"_tr" --out-conv-dir $CONV_TR_DIR \
        --determine-spks $DETSPKS --num-spks $NUMSPKS \
        --audio-amount $AUDIOAMOUNTTR --sampling-frequency $SAMPLINGFREQ
    echo "----- TRAIN CONVERSATIONS GENERATED -----"
fi


if [[ ! -d $WAVS_TR_DIR ]]; then
    echo "Creating sublists of the train set"
    # Create sublists of the train set (useful to launch parallel jobs)
    if [[ ! -d $LISTS_DIR/convtrsublists ]]; then
        find $CONV_VAL_DIR -iname "*.conv" | \
            xargs -n 1 basename -s .conv > $CONV_VAL_LIST
        find $CONV_TR_DIR -iname "*.conv" | \
            xargs -n 1 basename -s .conv > $CONV_TR_LIST
        mkdir -p $LISTS_DIR/convtrsublists
        split -l 500 -d "$CONV_TR_LIST" "$LISTS_DIR/convtrsublists/conv.lst_"
    fi

    mkdir -p $WAVS_TR_DIR $WAVS_VAL_DIR
    for f in `find $LISTS_DIR/convtrsublists/conv.lst_*`; do
        echo "python $DIR/conv2wav.py --conversations-list-filename $f --input-wav-scp $WAV_SCP_TR --in-conv-dir $CONV_TR_DIR --out-wav-dir $WAVS_TR_DIR $use_rirs --rirs-wav-scp $RIRS_SCP $use_noises --noises-wav-scp $NOISES_SCP --noises-snrs $SNRS --sampling-frequency $SAMPLINGFREQ" >> $SET_DIR/conv2wav.task
    done
    echo "python $DIR/conv2wav.py --conversations-list-filename $CONV_VAL_LIST --input-wav-scp $WAV_SCP_VAL --in-conv-dir $CONV_VAL_DIR --out-wav-dir $WAVS_VAL_DIR $use_rirs --rirs-wav-scp $RIRS_SCP $use_noises --noises-wav-scp $NOISES_SCP --noises-snrs $SNRS --sampling-frequency $SAMPLINGFREQ" >> $SET_DIR/conv2wav.task
    # Modify this if you want to run the task script in parallel.
    # Note that if you run in parallel, you have to make sure that this step
    # finished correctly before executing the rest.
    bash $SET_DIR/conv2wav.task &> $SET_DIR/conv2wav.out
fi


if [[ ! -d $COMMON_DATA_TR_DIR ]]; then
    echo "Generating general Kaldi-style data directory for train"
    mkdir -p $COMMON_DATA_TR_DIR
    for f in $(<$CONV_TR_LIST); do
       awk -v sampling_frequency=$SAMPLINGFREQ '{printf "SPEAKER %s 1 %.3f %.3f <NA> <NA> %s <NA> <NA>\n", FILENAME, $5/sampling_frequency, ($4-$3)/sampling_frequency, $1}' $CONV_TR_DIR/$f.conv
    done > $COMMON_DATA_TR_DIR/rttm

    awk -F"/" '{print $NF}' $COMMON_DATA_TR_DIR/rttm | sed 's/.conv//g' | \
        awk '{printf "%s_%s_%06d_%06d %s %f %f\n", $7, $1, $3*100, ($3+$4)*100, $1, $3, $3+$4}' > $COMMON_DATA_TR_DIR/segments
    awk -F"/" '{print $NF}' $COMMON_DATA_TR_DIR/rttm | sed 's/.conv//g' | \
        awk '{printf "%s_%s_%06d_%06d %s\n", $7, $1, $3*100, ($3+$4)*100, $7}' > $COMMON_DATA_TR_DIR/utt2spk
    $KALDIDIR/egs/wsj/s5/utils/utt2spk_to_spk2utt.pl $COMMON_DATA_TR_DIR/utt2spk > $COMMON_DATA_TR_DIR/spk2utt
    echo "----- TRAIN KALDI DIR GENERATED -----"
fi


if [[ ! -d $DATA_TR_DIR ]]; then
    echo "Generating augmentation-specific Kaldi-style data directory for train"
    mkdir -p $DATA_TR_DIR
    for ff in rttm segments spk2utt utt2spk; do
        ln -s $COMMON_DATA_TR_DIR/$ff $DATA_TR_DIR/$ff
    done
    ls $WAVS_TR_DIR | awk -F'.' -v path=$WAVS_TR_DIR '{print $1" "path"/"$1".wav"}' > $DATA_TR_DIR/wav.scp
    echo "----- TRAIN AUGMENTED KALDI DIR GENERATED -----"
fi


if [[ ! -d $COMMON_DATA_VAL_DIR ]]; then
    echo "Generating general Kaldi-style data directory for validation"
    mkdir -p $COMMON_DATA_VAL_DIR
    for f in $(<$CONV_VAL_LIST); do
       awk -v sampling_frequency=$SAMPLINGFREQ '{printf "SPEAKER %s 1 %.3f %.3f <NA> <NA> %s <NA> <NA>\n", FILENAME, $5/sampling_frequency, ($4-$3)/sampling_frequency, $1}' $CONV_VAL_DIR/$f.conv
    done > $COMMON_DATA_VAL_DIR/rttm

    awk -F"/" '{print $NF}' $COMMON_DATA_VAL_DIR/rttm | sed 's/.conv//g' | \
        awk '{printf "%s_%s_%06d_%06d %s %f %f\n", $7, $1, $3*100, ($3+$4)*100, $1, $3, $3+$4}' > $COMMON_DATA_VAL_DIR/segments
    awk -F"/" '{print $NF}' $COMMON_DATA_VAL_DIR/rttm | sed 's/.conv//g' | \
        awk '{printf "%s_%s_%06d_%06d %s\n", $7, $1, $3*100, ($3+$4)*100, $7}' > $COMMON_DATA_VAL_DIR/utt2spk
    $KALDIDIR/egs/wsj/s5/utils/utt2spk_to_spk2utt.pl $COMMON_DATA_VAL_DIR/utt2spk > $COMMON_DATA_VAL_DIR/spk2utt
    echo "----- VALIDATION AUGMENTED KALDI DIR GENERATED -----"
fi


if [[ ! -d $DATA_VAL_DIR ]]; then
    echo "Generating augmentation-specific Kaldi-style data directory for validation"
    mkdir -p $DATA_VAL_DIR
    for ff in rttm segments spk2utt utt2spk; do
        ln -s $COMMON_DATA_VAL_DIR/$ff $DATA_VAL_DIR/$ff
    done
    ls $WAVS_VAL_DIR | awk -F'.' -v path=$WAVS_VAL_DIR '{print $1" "path"/"$1".wav"}' > $DATA_VAL_DIR/wav.scp
    echo "----- VALIDATION AUGMENTED KALDI DIR GENERATED -----"
fi


if [[ ! -f $SET_DIR/get_lengths.task ]]; then
    echo "Obtaining lengths of files"
    mkdir -p $SET_DIR/durations
    mkdir -p $LISTS_DIR/convsubsublists
    split -l 50 -d "$CONV_TR_LIST" "$LISTS_DIR/convsubsublists/train_"
    for f in `find $LISTS_DIR/convsubsublists/train_*`; do
        subname=${f##*/}
        echo "$DIR/get_audios_lengths.sh $WAVS_TR_DIR $f $SET_DIR/durations/duration_$subname" >> $SET_DIR/get_lengths.task
    done

    split -l 50 -d "$CONV_VAL_LIST" "$LISTS_DIR/convsubsublists/validation_"
    for f in `find $LISTS_DIR/convsubsublists/validation_*`; do
        subname=${f##*/}
        echo "$DIR/get_audios_lengths.sh $WAVS_VAL_DIR $f $SET_DIR/durations/duration_$subname" >> $SET_DIR/get_lengths.task
    done
    # Modify this if you want to run the task script in parallel
    # Note that if you run in parallel, you have to make sure that this step
    # finished correctly before executing the rest.
    bash $SET_DIR/get_lengths.task &> $SET_DIR/get_lengths.out
    echo "----- LENGTHS OF FILES OBTAINED -----"
fi

cat $SET_DIR/durations/duration_train_* | sort > $DATA_TR_DIR/reco2dur
cat $SET_DIR/durations/duration_validation_* | sort > $DATA_VAL_DIR/reco2dur

if [[ ! -d $DATA_VAL_SUBSET_DIR ]]; then
    echo "Defining validation set"
    mkdir -p $DATA_VAL_SUBSET_DIR
        
    # Taking 2.1 hours for validation
    sort $DATA_VAL_DIR/reco2dur | shuf --random-source=<(yes 3) |
        awk 'BEGIN{sum=0}{sum+=$2 ; if(sum/3600 < 2.1){print $0}}' > $DATA_VAL_SUBSET_DIR/reco2dur
    awk '{print $1}' $DATA_VAL_SUBSET_DIR/reco2dur | awk '!seen[$0]++' > $DATA_VAL_SUBSET_DIR/recordings

    for ff in rttm segments spk2utt utt2spk wav.scp; do
        grep -f $DATA_VAL_SUBSET_DIR/recordings $DATA_VAL_DIR/$ff > $DATA_VAL_SUBSET_DIR/$ff
    done
    echo "----- VALIDATION SET DEFINED -----"
fi


if [[ ! -d $DATA_TEST3h_DIR ]]; then
    echo "Defining test set"
    mkdir -p $DATA_TEST3h_DIR

    # Taking 3 hours for test set
    comm -23 <(sort $DATA_VAL_DIR/reco2dur) <(sort $DATA_VAL_SUBSET_DIR/reco2dur) | \
        sort | shuf --random-source=<(yes 3) | \
        awk 'BEGIN{sum=0}{sum+=$2 ; if(sum/3600 < 3){print $0}}' > $DATA_TEST3h_DIR/reco2dur
        
    awk '{print $1}' $DATA_TEST3h_DIR/reco2dur | awk '!seen[$0]++' > $DATA_TEST3h_DIR/recordings

    for ff in rttm segments spk2utt utt2spk wav.scp; do
        grep -f $DATA_TEST3h_DIR/recordings $DATA_VAL_DIR/$ff | \
        awk '!seen[$0]++' > $DATA_TEST3h_DIR/$ff
    done
    echo "----- TEST SET DEFINED -----"
fi

# Remove full path from rttms filename
for directory in $DATA_TEST3h_DIR $DATA_VAL_DIR $DATA_VAL_SUBSET_DIR; do
    sed -i "s $CONV_VAL_DIR/  g" $directory/rttm
    sed -i 's .conv  g' $directory/rttm
done
for directory in $DATA_TR_DIR; do
    sed -i "s $CONV_TR_DIR/  g" $directory/rttm
    sed -i 's .conv  g' $directory/rttm
done

echo "----- END -----"
