#!/usr/bin/env bash

use_rirs=--no-use-rirs
#use_rirs=--use-rirs

#use_noises=--no-use-noises
use_noises=--use-noises

SNRS='5:10:15:20'
SAMPLINGFREQ=8000
DETSPKS="fixed"
NUMSPKS=2

NUMSPKSTEST=638

KALDIDIR=<Kaldi directory>

DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
AUDIOAMOUNTTR=2480.6
AUDIOAMOUNTVAL=-1
WORKDIR=<Output directory>
 
RTTMS_FILE=<A single rttm file with all segments of DIHARD 3 dev full cts>

HITACHI_EEND_DIR=<Directory where you have https://github.com/hitachi-speech/EEND>

SEG_FILE=$HITACHI_EEND_DIR/egs/callhome/v1/exp/segmentation_1a/tdnn_stats_asr_sad_1a/segmentation_swb_sre_comb_whole/segments
SPK2UTT=$HITACHI_EEND_DIR/egs/callhome/v1/data/swb_sre_comb/spk2utt
WAV_SCP=$HITACHI_EEND_DIR/egs/callhome/v1/data/swb_sre_comb/wav.scp
RIRS_SCP=$HITACHI_EEND_DIR/egs/callhome/v1/data/simu_rirs_8k/wav.scp
NOISES_SCP=$HITACHI_EEND_DIR/egs/callhome/v1/data/musan_noise_bg/wav.scp
