#!/usr/bin/env python

# @Authors: Federico Landini, Lukas Burget
# @Emails: landini@fit.vutbr.cz, burget@fit.vutbr.cz
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

import numpy as np
from itertools import groupby
import random
import argparse
from types import SimpleNamespace

seed = 3
np.random.seed(seed)
random.seed(seed)  # Python random module.


def parse_arguments() -> SimpleNamespace:
    parser = argparse.ArgumentParser(description='Conversations generator')
    parser.add_argument('--stats-dir', type=str, required=True,
                        help='directory with statistics used to generate \
                        conversations.')
    parser.add_argument('--seg-list-file', type=str, required=True,
                        help='file containing VAD segments in Kaldi format.')
    parser.add_argument('--out-conv-dir', type=str, required=True,
                        help='directory where conversations will be saved.')
    parser.add_argument('--determine-spks', type=str, required=False,
                        default='fixed', choices=['fixed', 'maximum'],
                        help='backend framework')
    parser.add_argument('--num-spks', type=int, required=True,
                        help='number of speakers to have per conversation \
                        (depending on --determine-spks it is a fixed amount \
                        or the maximum).')
    parser.add_argument('--audio-amount', type=float, required=False,
                        default=-1, help='amount of hours of audio to \
                        generate. If not defined, each session is used once \
                        until all of them are used.')
    parser.add_argument('--rounds', type=int, required=False, default=-1,
                        help='amount of rounds where each conversation is \
                        used. For example 2 will mean that each conversation \
                        is used without replacement until using all of them \
                        and then the process is repeated one more time.')
    parser.add_argument('--sampling-frequency', type=int, required=False,
                        default=8000, help='data sampling frequency.')
    args = parser.parse_args()
    return args


if __name__ == '__main__':
    args = parse_arguments()

    seg_list = np.loadtxt(args.seg_list_file, dtype=object)
    seg_list[:, 2:] = (
        seg_list[:, 2:].astype(float)*args.sampling_frequency).astype(int)

    same_spk_pause_dist = np.loadtxt(
        args.stats_dir + '/same_spk_pause.txt', dtype=float)
    same_spk_pause_dist = same_spk_pause_dist[
        same_spk_pause_dist[:, 1] < 7.0
        ]  # forbid too long pauses (which are unlikely anyway)
    same_spk_pause_dist[:, 0] /= same_spk_pause_dist[:, 0].sum()

    diff_spk_pause_dist = np.loadtxt(
        args.stats_dir + '/diff_spk_pause.txt', dtype=float)
    diff_spk_pause_dist = diff_spk_pause_dist[
        diff_spk_pause_dist[:, 1] < 7.0
        ]  # forbid too long pauses (which are unlikely anyway)
    diff_spk_pause_dist[:, 0] /= diff_spk_pause_dist[:, 0].sum()

    diff_spk_overlap_dist = np.loadtxt(
        args.stats_dir + '/diff_spk_overlap.txt', dtype=float)
    diff_spk_overlap_dist = diff_spk_overlap_dist[
        diff_spk_overlap_dist[:, 1] < 7.0
        ]  # forbid too long overlaps (which are unlikely anyway)
    diff_spk_overlap_dist[:, 0] /= diff_spk_overlap_dist[:, 0].sum()

    with open(args.stats_dir + '/diff_spk_pause.txt') as f:
        lines = [line.rstrip() for line in f]
    spk_pause = sum([int(line.split(' ')[-2]) for line in lines])
    with open(args.stats_dir + '/diff_spk_overlap.txt') as f:
        lines = [line.rstrip() for line in f]
    overlap = sum([int(line.split(' ')[-2]) for line in lines])
    diff_spk_pause_vs_overlap_prob = spk_pause / (spk_pause + overlap)

    session_split = np.split(seg_list, np.nonzero(
        seg_list[1:, 1] != seg_list[:-1, 1])[0]+1)  # split by session name
    groupbyspeaker = groupby(session_split, lambda e: e[0][0])
    speakers = [list(sessions) for spk, sessions in groupbyspeaker]

    if args.rounds != -1:
        roundcounter = args.rounds
    else:
        roundcounter = -1

    audio_generated_so_far = 0
    while (args.audio_amount == -1) or \
            (audio_generated_so_far < args.audio_amount) or \
            (args.rounds != -1 and roundcounter > 0):
        while len(speakers):
            print(str(len(speakers)) + " speakers remaining", end='\r')
            print(end='\x1b[2K')
            if args.determine_spks == 'fixed':
                nspks = int(args.num_spks)
            else:
                max_speakers = int(args.num_spks)
                p_nspk = 1./np.arange(1, max_speakers+1)
                p_nspk[0] = 0.0  # excluding recodings with only one speaker
                p_nspk /= p_nspk.sum()
                nspks = min(np.random.choice(
                    max_speakers, p=p_nspk)+1, len(speakers))
            if len(speakers) <= nspks:
                # np.random.choice fails sometimes with just few speakers
                break
            selected_speakers = random.sample(speakers, nspks)
            selected_sessions = [spk.pop() for spk in selected_speakers]
            for spk in selected_speakers:
                if not len(spk):
                    speakers.remove(spk)  # remove speaker if sessions consumed

            spk_turns = np.repeat(
                range(nspks), [len(s) for s in selected_sessions])
            np.random.shuffle(spk_turns)
            conversation = np.empty((
                len(spk_turns), selected_sessions[0].shape[1]), dtype=object)
            for s in range(len(selected_sessions)):
                conversation[spk_turns == s] = selected_sessions[s]

            seg_out_positions = np.zeros_like(spk_turns)
            speakers_last_frame = np.zeros(nspks, dtype=int)
            last_seg_end = 0
            for i, spk in enumerate(spk_turns):
                if i == 0 or spk == spk_turns[i-1]:
                    # not a speaker turn
                    gap = np.random.choice(
                        same_spk_pause_dist[:, 1], p=same_spk_pause_dist[:, 0])
                elif np.random.binomial(1, diff_spk_pause_vs_overlap_prob):
                    # speaker turn with pause
                    gap = np.random.choice(
                        diff_spk_pause_dist[:, 1], p=diff_spk_pause_dist[:, 0])
                else:
                    # speaker turn with overlap
                    gap = -np.random.choice(diff_spk_overlap_dist[:, 1],
                                            p=diff_spk_overlap_dist[:, 0])
                gap = int(gap*args.sampling_frequency)
                seg_out_positions[i] = max(
                    last_seg_end + gap, speakers_last_frame[spk])
                speakers_last_frame[spk] = seg_out_positions[i] + \
                    conversation[i, 3] - \
                    conversation[i, 2]  # add segment duration
                last_seg_end = max(speakers_last_frame[spk], last_seg_end)

            total_num_samples = max(
                conversation[:, 3] - conversation[:, 2] + seg_out_positions)
            assert(total_num_samples == last_seg_end)
            conversation = np.hstack(
                [conversation, seg_out_positions[:, np.newaxis]])
            np.savetxt(args.out_conv_dir+'/'+'_'.join(
                [s[0, 1] for s in selected_sessions]
                )+'.conv', conversation, fmt='%s')

            audio_generated_so_far += (
                total_num_samples / args.sampling_frequency) / 3600
            if (args.audio_amount != -1) and (
                    audio_generated_so_far >= args.audio_amount):
                break  # reached the necessary amount of audio

        if args.audio_amount == -1 and roundcounter > 0:
            roundcounter -= 1
            if roundcounter <= 0:
                break  # reached the amount of rounds
            session_split = np.split(seg_list, np.nonzero(
                seg_list[1:, 1] != seg_list[:-1, 1]
                )[0]+1)  # split by session name
            groupbyspeaker = groupby(session_split, lambda e: e[0][0])
            speakers = [list(sessions) for spk, sessions in groupbyspeaker]
        elif args.audio_amount == -1:
            break  # and exit
        else:
            # redefine variables to go over the cycle again until
            # obtaining the expected amount of hours
            session_split = np.split(seg_list, np.nonzero(
                seg_list[1:, 1] != seg_list[:-1, 1])[0]+1
                )  # split by session name
            groupbyspeaker = groupby(session_split, lambda e: e[0][0])
            speakers = [list(sessions) for spk, sessions in groupbyspeaker]
