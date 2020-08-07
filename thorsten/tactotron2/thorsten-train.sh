#!/bin/bash
BASEDIR=/tmp/tts

mkdir $BASEDIR
cd $BASEDIR
git clone https://github.com/thorstenMueller/TTS_recipes.git

# Download and extract "thorsten" dataset
python3 -m venv $BASEDIR
source /tmp/tts/bin/activate
pip install pip --upgrade
pip install gdown

cd $BASEDIR
gdown https://drive.google.com/uc?id=1yKJM1LAOQpRVojKunD9r8WN_p5KzBxjc -O thorsten-dataset.tgz
tar -xvzf thorsten-dataset.tgz

# Prepare shuffled training and validate data (90% train, 10% val)
shuf LJSpeech-1.1/metadata.csv > LJSpeech-1.1/metadata_shuf.csv
head -n 20400 LJSpeech-1.1/metadata_shuf.csv > LJSpeech-1.1/metadata_train.csv
tail -n 2268 LJSpeech-1.1/metadata_shuf.csv > LJSpeech-1.1/metadata_val.csv

# Install Mozilla TTS repo and dependencies
sudo apt-get install espeak
git clone --single-branch --branch dev https://github.com/mozilla/TTS
cd $BASEDIR/TTS
python setup.py develop

# Add german phoneme cleaner by @repodiac
cd $BASEDIR
git clone https://github.com/repodiac/german_transliterate
cd german_transliterate
pip install -e .

cd $BASEDIR/TTS/mozilla_voice_tts/tts/utils/text
sed '/import re/a from german_transliterate.core import GermanTransliterate' cleaners.py >> cleaners-new.py
mv cleaners-new.py cleaners.py
echo -e "\ndef german_phoneme_cleaners(text):" >> cleaners.py
echo -e "\treturn GermanTransliterate(replace={';': ',', ':': ' '}, sep_abbreviation=' -- ').transliterate(text)" >> cleaners.py

# Run training
cd $BASEDIR/TTS/mozilla_voice_tts/bin/
CUDA_VISIBLE_DEVICES="0" python train_tts.py --config_path $BASEDIR/TTS_recipes/thorsten/tactotron2/model-config.json