Recipe to generate simulated conversations using LibriSpeech.
The checkpoints correspond to a model trained with a set of 2480 hours where only background noises were used as data augmentation.
This model was used to produce the "SC LibriSpeech" results before fine-tuning in "MULTI-SPEAKER AND WIDE-BAND SIMULATED CONVERSATIONS AS TRAINING DATA FOR END-TO-END NEURAL DIARIZATION"

For more details, please refer to [From Simulated Mixtures to Simulated Conversations as Training Data for End-to-End Neural Diarization](https://arxiv.org/abs/2204.00890) and [MULTI-SPEAKER AND WIDE-BAND SIMULATED CONVERSATIONS AS TRAINING DATA FOR END-TO-END NEURAL DIARIZATION](https://arxiv.org/pdf/2211.06750.pdf)


## Usage
In `config_variables.sh` set the variables:
`KALDIDIR` with the path where you have Kaldi.
`WORKDIR` with the directory where you want to generate the recordings (bear in mind that the default 2480 hours can be more than 0.5TB).
`RTTMS_FILE` with the file that contains reference RTTMs from which to extract statistics about turns, pauses and overlaps. For example, those of recordings of DIHARD 3 development CTS.

Before generating the data, it needs to be prepared calling `prepareKaldidata_LibriSpeech.sh`

To run the data-generation recipe, execute `generate_data.sh`. It will calculate statistics from the RTTMs, define train and validation sets of speakers, define the conversations and generate their corresponding Kaldi-style data directories. Then, given the choice of augmentations (reverb and noises), it will generate the waveforms and produce their data directories.



## Citation
In case of using the software please cite:\
Federico Landini, Mireia Diez, Alicia Lozano-Diez, Lukáš Burget: [Multi-Speaker and Wide-Band Simulated Conversations as Training Data for End-to-End Neural Diarization](https://arxiv.org/abs/2211.06750)
```
@inproceedings{landini2023multi,
  title={Multi-Speaker and Wide-Band Simulated Conversations as Training Data for End-to-End Neural Diarization},
  author={Landini, Federico and Diez, Mireia and Lozano-Diez, Alicia and Burget, Luk{\'a}{\v{s}}},
  booktitle={ICASSP 2023-2023 IEEE International Conference on Acoustics, Speech and Signal Processing (ICASSP)},
  pages={1--5},
  year={2023},
  organization={IEEE}
}
```


## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.



## Contact
If you have any comment or question, please contact landini@fit.vutbr.cz
