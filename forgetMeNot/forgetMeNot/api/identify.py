"""REST API for getting speakers."""
import flask
import os
from flask import request

import forgetMeNot
from forgetMeNot import model
from forgetMeNot.api.helpers import task_predict

import base64
import os

@forgetMeNot.app.route('/api/ios/identify/', methods=["POST"])
def identify_ios():
    audio_encode = request.get_json()['audio']
    
    path = forgetMeNot.app.config['MODEL_FILEPATH']
    if os.path.exists(str(path) + "/temp.wav"):
        os.remove(str(path) + "/temp.wav")
    
    wav_name = str(path) + "/temp.wav"
    aac_name = str(path) + "/temp.aac"
    aac_file = open(str(path) + "/temp.aac", "wb")
    decode_string = base64.b64decode(audio_encode)
    aac_file.write(decode_string)
    os.system('ffmpeg -i {} {}'.format(aac_name, wav_name))
    label = ""
    relationship = ""
    photo = ""
    if os.path.exists(str(path) + "/model.out"):
        label, score = task_predict(str(path) + "/temp.wav", str(path) + "/model.out")

    if label != "":
        arg = (label,)
        label = model.get_db().execute("SELECT fullname FROM speakers where speakerID=?", arg).fetchone()['fullname']
        relationship = model.get_db().execute("SELECT relationship FROM speakers where speakerID=?", arg).fetchone()['relationship']
        photo = model.get_db().execute("SELECT photo FROM speakers WHERE speakerID=?", arg).fetchone()['photo']



    context = {}
    context['name'] = label
    context['relationship'] = relationship
    context['photo'] = photo
    return flask.jsonify(**context)

@forgetMeNot.app.route('/api/identify/', methods=["POST"])
def identify():
    audio_encode = request.files.get('audio').read()
    
    path = forgetMeNot.app.config['MODEL_FILEPATH']
    if os.path.exists(str(path) + "/temp.wav"):
        os.remove(str(path) + "/temp.wav")
    
    wav_file = open(str(path) + "/temp.wav", "wb")
    wav_file.write(audio_encode)   
    label = ""
    score = 0
    if os.path.exists(str(path) + "/model.out"):
        label, score = task_predict(str(path) + "/temp.wav", str(path) + "/model.out")


    if label != "":
        arg = (label,)
        label = model.get_db().execute("SELECT fullname FROM speakers where speakerID=?", arg).fetchone()['fullname']

    context = {}
    context['label'] = label
    context['score'] = score
    return flask.jsonify(**context)
