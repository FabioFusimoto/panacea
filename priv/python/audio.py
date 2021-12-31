import numpy as np
import pyaudio

def devices():
    p = pyaudio.PyAudio()

    devices = []

    for i in range(p.get_device_count()):
        devices.append(p.get_device_info_by_index(i))

    return devices

def record_audio_frames(device_index, record_time):
    p = pyaudio.PyAudio()
    default_frames = 512
    record_time_in_seconds = record_time / 1000
  
    device_info = p.get_device_info_by_index(device_index)
    channel_count = device_info["maxInputChannels"] if (device_info["maxOutputChannels"] < device_info["maxInputChannels"]) else device_info["maxOutputChannels"]
    sample_rate = int(device_info["defaultSampleRate"])

    stream = p.open(format = pyaudio.paInt16,
                    channels = channel_count,
                    rate = sample_rate,
                    input = True,
                    frames_per_buffer = default_frames,
                    input_device_index = device_index,
                    as_loopback = True)

    recorded_frames = np.array([])
    for i in range(0, int(sample_rate * record_time_in_seconds / default_frames)):
        raw_frame = stream.read(default_frames)
        audio_frame = np.frombuffer(raw_frame, dtype=np.int16)
        recorded_frames = np.append(recorded_frames, audio_frame)

    stream.stop_stream()
    stream.close()
    p.terminate()

    return recorded_frames, sample_rate

def spectrum(device_index, record_time, threshold_frequencies):
    try:
        recorded_frames, sample_rate = record_audio_frames(device_index, record_time)
        fft = np.fft.fft(recorded_frames)
        middle = int(fft.size / 2)
        positive_fft = fft[:middle]
        positive_fft = np.abs(positive_fft)/len(positive_fft)

        freqs = np.fft.fftfreq(len(fft)) * 2 * sample_rate
        positive_freqs = freqs[:middle]

        power_spectrum = []
        for i, f in enumerate(threshold_frequencies):
            if i == 0:
                upper_limit = np.searchsorted(positive_freqs, f)
                fft_slice = positive_fft[:upper_limit]
                power_spectrum.append([f, float(np.sum(fft_slice))])
            else:
                lower_limit = np.searchsorted(positive_freqs, threshold_frequencies[i - 1])
                upper_limit = np.searchsorted(positive_freqs, f)
                fft_slice = positive_fft[lower_limit:upper_limit]
                power_spectrum.append([f, float(np.sum(fft_slice))])

        return power_spectrum
    except:
        return([[f, 0] for f in threshold_frequencies])