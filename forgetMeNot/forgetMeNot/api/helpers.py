import pickle
from collections import defaultdict
import time
from python_speech_features import mfcc
import numpy as np
from sklearn.mixture import GaussianMixture
import operator
import math
import os
import sys
import itertools
import glob
import argparse
from scipy.io import wavfile
import forgetMeNot

class ModelInterface:
    
    def __init__(self):
        self.features = defaultdict(list)
        self.gmmset = GMMSet()

    def enroll(self, name, fs, signal):
        feat = get_feature(fs, signal)
        self.features[name].extend(feat)

    def train(self):
        self.gmmset = GMMSet()
        start_time = time.time()
        for name, feats in self.features.items():
            try:
                self.gmmset.fit_new(feats, name)
            except Exception as e :
                print ("%s failed"%(name))
        print (time.time() - start_time, " seconds")

    def dump(self, fname):
        """ dump all models to file"""
        self.gmmset.before_pickle()
        with open(fname, 'wb') as f:
            pickle.dump(self, f, -1)
        self.gmmset.after_pickle()

    def predict(self, fs, signal):
        """
        return a label (name)
        """
        try:
            feat = get_feature(fs, signal)
        except Exception as e:
            print (e)
        return self.gmmset.predict_one(feat)

    @staticmethod
    def load(fname):
        """ load from a dumped model file"""
        #with open(fname, 'rb') as f:
        path = forgetMeNot.app.config['MODEL_FILEPATH']
        R = pickle.load(open( str(path) + "/model.out", "rb" ))
        R.gmmset.after_pickle()
        return R


def get_feature(fs, signal):
    mfcc_feature = mfcc(signal, fs, nfft = 1200)
    if len(mfcc_feature) == 0:
        print >> sys.stderr, "ERROR.. failed to extract mfcc feature:", len(signal)
    return mfcc_feature

class GMMSet:
    
    def __init__(self, gmm_order = 32):
        self.gmms = []
        self.gmm_order = gmm_order
        self.y = []

    def fit_new(self, x, label):
        self.y.append(label)
        gmm = GaussianMixture(self.gmm_order)
        gmm.fit(x)
        self.gmms.append(gmm)

    def gmm_score(self, gmm, x):
        return np.sum(gmm.score(x))

    @staticmethod
    def softmax(scores):
        scores_sum = sum([math.exp(i) for i in scores])
        score_max  = math.exp(max(scores))
        if scores_sum == 0:
            return 0
        return round(score_max / scores_sum, 3)

    def predict_one(self, x):
        scores = [self.gmm_score(gmm, x) / len(x) for gmm in self.gmms]
        p = sorted(enumerate(scores), key=operator.itemgetter(1), reverse=True)
        p = [(str(self.y[i]), y, p[0][1] - y) for i, y in p]
        result = [(self.y[index], value) for (index, value) in enumerate(scores)]
        p = max(result, key=operator.itemgetter(1))
        softmax_score = self.softmax(scores)
        return p[0], softmax_score

    def before_pickle(self):
        pass

    def after_pickle(self):
        pass

def read_wav(fname):
    fs, signal = wavfile.read(fname)
    if len(signal.shape) != 1:
        print("convert stereo to mono")
        signal = signal[:,0]
    return fs, signal


def task_enroll(input_dirs, output_model):
    m = ModelInterface()
    input_dirs = [os.path.expanduser(k) for k in input_dirs.strip().split()]
    dirs = itertools.chain(*(glob.glob(d) for d in input_dirs))
    dirs = [d for d in dirs if os.path.isdir(d)]

    files = []
    if len(dirs) == 0:
        print ("No valid directory found!")
        sys.exit(1)

    for d in dirs:
        label = os.path.basename(d.rstrip('/'))
        wavs = glob.glob(d + '/*.wav')

        if len(wavs) == 0:
            print ("No wav file found in %s"%(d))
            continue
        for wav in wavs:
            try:
                fs, signal = read_wav(wav)
                m.enroll(label, fs, signal)
                print("wav %s has been enrolled"%(wav))
            except Exception as e:
                print(wav + " error %s"%(e))
                return False


    m.train()
    m.dump(output_model)
    return True

def task_predict(input_files, input_model):
    m = ModelInterface.load(input_model)
    for f in glob.glob(os.path.expanduser(input_files)):
        fs, signal = read_wav(f)
        label, score = m.predict(fs, signal)
        print (f, '->', label, ", score->", score)
        return (label, score)
