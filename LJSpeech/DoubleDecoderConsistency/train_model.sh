# download LJSpeech dataset
wget http://data.keithito.com/data/speech/LJSpeech-1.1.tar.bz2
# decompress
tar -xjf LJSpeech-1.1.tar.bz2
# create train-val splits
shuf LJSpeech-1.1/metadata.csv > LJSpeech-1.1/metadata_shuf.csv
head -n 12000 LJSpeech-1.1/metadata_shuf.csv > LJSpeech-1.1/metadata_train.csv
tail -n 1100 LJSpeech-1.1/metadata_shuf.csv > LJSpeech-1.1/metadata_val.csv
# get TTS to your local
git clone https://github.com/coqui-ai/TTS
# install deps
sudo apt-get install espeak
pip install soundfile
# checkout a specific version
cd TTS
git checkout b1935c97
python setup.py install
cd ..
# compute dataset mean and variance for normalization
python TTS/compute_statistics.py --config_path model_config.json --out_path ./
# training ....
# change the GPU id if needed 
CUDA_VISIBLE_DEVICES="0" python TTS/train.py --config_path model_config.json
# train vocoder ...
CUDA_VISIBLE_DEVICES="0" python TTS/vocoder/train.py --config_path vocoder_config.json
