# End-to-End Neural Diarization data preparation

Recipe for generating training data for diarization by Brno University of Technology. \
The recipe uses telephone recordings from Switchboard and NIST SRE evaluations to generate the conversations. This follows the [data setup proposed by Hitachi](https://github.com/hitachi-speech/EEND/blob/b851eecd8d7a966487ed3e4ff934a1581a73cc9e/egs/callhome/v1/run_prepare_shared_eda.sh). Our recipe optionally adds reverberation and/or background noises.

For more details, please refer to [From Simulated Mixtures to Simulated Conversations as Training Data for End-to-End Neural Diarization](https://arxiv.org/abs/2204.00890)


## Usage
In `config_variables.sh` set the variables:
`KALDIDIR` with the path where you have Kaldi.
`WORKDIR` with the directory where you want to generate the recordings (bear in mind that the default 2480 hours can be more than 0.5TB).
`RTTMS_FILE` with the file that contains reference RTTMs from which to extract statistics about turns, pauses and overlaps. For example, those of recordings of DIHARD 3 development CTS.
`HITACHI_EEND_DIR` with the directory where you have https://github.com/hitachi-speech/EEND Note that you will need to run the stage 0 of https://github.com/hitachi-speech/EEND/blob/master/egs/callhome/v1/run_prepare_shared_eda.sh to generate the Kaldi-style data paths and VAD labels for Switchboard and SRE sets.

To run the data-generation recipe, execute `generate_data.sh`. It will calculate statistics from the RTTMs, define train and validation sets of speakers, define the conversations and generate their corresponding Kaldi-style data directories. Then, given the choice of augmentations (reverb and noises), it will generate the waveforms and produce their data directories.



## Citation
In case of using the software please cite:\
Federico Landini, Alicia Lozano-Diez, Mireia Diez, Lukáš Burget: [From Simulated Mixtures to Simulated Conversations as Training Data for End-to-End Neural Diarization](https://arxiv.org/abs/2204.00890)
```
@inproceedings{landini22_interspeech,
  author={Federico Landini and Alicia Lozano-Diez and Mireia Diez and Lukáš Burget},
  title={{From Simulated Mixtures to Simulated Conversations as Training Data for End-to-End Neural Diarization}},
  year=2022,
  booktitle={Proc. Interspeech 2022},
  pages={5095--5099},
  doi={10.21437/Interspeech.2022-10451}
}
```


## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.



## Contact
If you have any comment or question, please contact landini@fit.vutbr.cz
