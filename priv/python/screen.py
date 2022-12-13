#!/usr/bin/env python
import binascii
import numpy as np
import scipy.cluster

from vidgear.gears import ScreenGear
from PIL import Image

def get_most_frequent_color():
    width = 2560
    height = 1440

    options = {'top': 0, 'left': 0, 'width': width, 'height': height}
    stream = ScreenGear(**options).start()

    frame = stream.read()
    frame = Image.fromarray(frame, 'RGB')
    width, height = frame.size

    NUM_CLUSTERS = 5

    im = frame.resize((round(frame.width / 20), round(frame.height / 20)))
    ar = np.asarray(im)
    shape = ar.shape
    ar = ar.reshape(np.product(shape[:2]), shape[2]).astype(float)

    codes, dist = scipy.cluster.vq.kmeans(ar, NUM_CLUSTERS)

    vecs, dist = scipy.cluster.vq.vq(ar, codes)         # assign codes
    counts, bins = np.histogram(vecs, len(codes))    # count occurrences

    index_max = np.argmax(counts)                    # find most frequent
    peak = codes[index_max]
    colour = binascii.hexlify(bytearray(int(c) for c in peak)).decode('ascii')
    stream.stop()
    return '#{}'.format(colour)
