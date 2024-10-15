from moviepy.editor import VideoFileClip

# Load the MP4 file
video = VideoFileClip("/Users/ebowwa/Downloads/DJI_20240930_140434_276_video.MP4")

# Extract and resample the audio to 16kHz
audio = video.audio.set_fps(16000)

# Save the audio as a WAV file
audio.write_audiofile("podcastoutput_file.wav", codec='pcm_s16le')
