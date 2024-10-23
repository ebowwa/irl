from moviepy.editor import VideoFileClip

def extract_and_resample_audio(video_path, output_audio_path, sample_rate=16000):
    """
    Extract audio from a video file and resample it to the specified sample rate.
    
    :param video_path: Path to the input video file (e.g., .MP4).
    :param output_audio_path: Path to save the output audio file (e.g., .wav).
    :param sample_rate: The target sample rate for the audio (default: 16000 Hz).
    """
    # Load the video file
    video = VideoFileClip(video_path)
    
    # Extract and resample the audio
    audio = video.audio.set_fps(sample_rate)
    
    # Save the audio as a WAV file with the specified codec
    audio.write_audiofile(output_audio_path, codec='pcm_s16le')

if __name__ == "__main__":
    # Define the input video and output audio paths
    video_path = "/Users/ebowwa/Downloads/DJI_20240930_140434_276_video.MP4"
    output_audio_path = "podcastoutput_file.wav"
    
    # Call the utility function to extract and resample the audio
    extract_and_resample_audio(video_path, output_audio_path)
