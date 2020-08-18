# download Thorsten_DE dataset
pip install gdown
gdown --id 1yKJM1LAOQpRVojKunD9r8WN_p5KzBxjc -O dataset.tgz
tar -xzvf dataset.tgz
mv LJSpeech-1.1 Dataset

# get TTS to your local
git clone https://github.com/mozilla/TTS

# install deps
sudo apt-get install espeak
pip install soundfile

# checkout a specific version
cd TTS
git checkout 3424181
pip install -r requirements.txt
python setup.py develop
cd ..

# compute dataset mean and variance for normalization
python TTS/mozilla_voice_tts/bin/compute_statistics.py --config_path model_config.json --out_path ./

# training ....
# change the GPU id if needed
CUDA_VISIBLE_DEVICES="0" python TTS/mozilla_voice_tts/bin/train_tts.py --config_path model_config.json

# train vocoder ...
CUDA_VISIBLE_DEVICES="0" python TTS/mozilla_voice_tts/bin/train_vocoder.py --config_path vocoder_config.json
