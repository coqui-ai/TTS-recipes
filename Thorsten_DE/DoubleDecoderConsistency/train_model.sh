# Written by Thorsten Müller and Erogol in august 2020.
# Further details on dataset can be found here: https://github.com/thorstenMueller/deep-learning-german-tts

#!/bin/bash

# prepare directory structure
BASEDIR=/tmp/tts
mkdir $BASEDIR
cd $BASEDIR

# create venv
python3 -m venv .
source ./bin/activate
pip install pip --upgrade

# download Thorsten_DE dataset
pip install gdown
gdown --id 1yKJM1LAOQpRVojKunD9r8WN_p5KzBxjc -O dataset.tgz
tar -xzvf dataset.tgz
mv LJSpeech-1.1 Dataset

# Prepare shuffled training and validate data (90% train, 10% val)
shuf Dataset/metadata.csv > Dataset/metadata_shuf.csv
head -n 20400 Dataset/metadata_shuf.csv > Dataset/metadata_train.csv
tail -n 2268 Dataset/metadata_shuf.csv > Dataset/metadata_val.csv

# get TTS to your local
git clone https://github.com/mozilla/TTS

# install deps
sudo apt-get install espeak-ng
pip install soundfile

# checkout a specific version
cd TTS
git checkout 3424181
pip install -r requirements.txt
python setup.py develop
cd ..

# Add german phoneme cleaner by @repodiac
git clone https://github.com/repodiac/german_transliterate
cd german_transliterate
pip install -e .
cd ..

cd TTS/mozilla_voice_tts/tts/utils/text
sed '/import re/a from german_transliterate.core import GermanTransliterate' cleaners.py >> cleaners-new.py
mv cleaners-new.py cleaners.py
echo -e "\ndef german_phoneme_cleaners(text):" >> cleaners.py
echo -e "\treturn GermanTransliterate(replace={';': ',', ':': ' '}, sep_abbreviation=' -- ').transliterate(text)" >> cleaners.py


# compute dataset mean and variance for normalization
# IMPORTANT: Copy model-config.json and vocoder-config.json to BASEDIR
cd $BASEDIR
python TTS/mozilla_voice_tts/bin/compute_statistics.py --config_path model_config.json --out_path ./

# training ....
# change the GPU id if needed
CUDA_VISIBLE_DEVICES="0" python TTS/mozilla_voice_tts/bin/train_tts.py --config_path model_config.json

# train vocoder ...
CUDA_VISIBLE_DEVICES="0" python TTS/mozilla_voice_tts/bin/train_vocoder.py --config_path vocoder_config.json
