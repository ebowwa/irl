import nemo.collections.asr as nemo_asr

# Step 1: Load the ASR model from Hugging Face
model_name = 'WhissleAI/speech-tagger_en_ner_emotion'
asr_model = nemo_asr.models.EncDecCTCModel.from_pretrained(model_name)

# Step 2: Provide the path to your audio file
audio_file_path = '/Users/ebowwa/Downloads/DJI_20240930_140434_276_video.MP4'

# Step 3: Transcribe the audio
transcription = asr_model.transcribe(paths2audio_files=[audio_file_path])
print(f'Transcription: {transcription[0]}')
