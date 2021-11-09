import pyaudio

def hello(message):
    return "Hello from " + message.decode("utf-8")

def dict():
    return ({
        'key1': 'value1',
        'key2': 'value2'
    })