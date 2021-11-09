import pyaudio
import wave

def devices():
    p = pyaudio.PyAudio()

    devices = []

    for i in range(p.get_device_count()):
        devices.append(p.get_device_info_by_index(i))

    return devices

def record(device_index, record_time):
    default_frames = 512
    p = pyaudio.PyAudio()
    
    devices = []

    for i in range(p.get_device_count()):
        devices.append(p.get_device_info_by_index(i))
    
    device_info = devices[device_index]
    channelcount = device_info["maxInputChannels"] if (device_info["maxOutputChannels"] < device_info["maxInputChannels"]) else device_info["maxOutputChannels"]
    
    
    stream = p.open(format = pyaudio.paInt16,
                    channels = channelcount,
                    rate = int(device_info["defaultSampleRate"]),
                    input = True,
                    frames_per_buffer = default_frames,
                    input_device_index = device_info["index"],
                    as_loopback = True)
    
    recorded_frames = []
    for i in range(0, int(int(device_info["defaultSampleRate"]) / default_frames * record_time)):
        recorded_frames.append(stream.read(default_frames))

    stream.stop_stream()
    stream.close()

    waveFile = wave.open('out.wav', 'wb')
    waveFile.setnchannels(channelcount)
    waveFile.setsampwidth(p.get_sample_size(pyaudio.paInt16))
    waveFile.setframerate(int(device_info["defaultSampleRate"]))
    waveFile.writeframes(b''.join(recorded_frames))
    waveFile.close()

    return len(recorded_frames)