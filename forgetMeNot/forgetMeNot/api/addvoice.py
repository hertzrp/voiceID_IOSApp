"""REST API for getting speakers."""
import flask
from flask import request

import forgetMeNot
from forgetMeNot import model
from forgetMeNot.api.helpers import task_enroll

import base64
import os

@forgetMeNot.app.route('/api/ios/addvoice/', methods=["POST"])
def addvoice_ios():
    name = request.get_json()['name']
    relationship = request.get_json()['relationship']
    audio_encode = request.get_json()['audio']
    photo = request.get_json()['photo']
    speakerID = int(request.get_json()['id'])

    if speakerID == -1:
        speakerID = model.get_db().execute("SELECT MAX(speakerID) FROM speakers").fetchone()['MAX(speakerID)']
        if speakerID is None:
            speakerID = 0
        else:
            speakerID += 1
        
    
    path = forgetMeNot.app.config['MODEL_FILEPATH']

    if not os.path.exists(str(path) + "/" + str(speakerID)):
        os.mkdir(str(path) + "/" + str(speakerID)) 
    aac_name = str(path) + "/" + str(speakerID) + "/temp.aac"
    aac_file = open(str(path) + "/" + str(speakerID) + "/temp.aac", "wb")
    wav_name = str(path) + "/" + str(speakerID) + "/temp.wav"
    
    audio_decode = base64.b64decode(audio_encode)
    aac_file.write(audio_decode)   
    os.system('ffmpeg -i {} {}'.format(aac_name, wav_name))
    enrolled = task_enroll(str(path) + "/" + str(speakerID) + "/", str(path) + "/model.out")
    status = ""
    if(enrolled):
        status = "Success"
        args = (speakerID, name, relationship, photo,)
        model.get_db().execute("INSERT INTO speakers(speakerID, fullname, relationship, photo) VALUES (?,?,?,?)", args)
    if(not enrolled):
        status = "Failure"

    print(status)
    context = {}
    context['success'] = status


    return flask.jsonify(**context)

@forgetMeNot.app.route('/api/addvoice/', methods=["POST"])
def addvoice():
    method = int(request.form.get('method'))
    name = request.form.get('name')
    relationship = request.form.get('relationship')
    if method == 1:
        photo = request.form.get('photo')
        audio_encode = request.form.get('audio')
    else:
        photo = request.files.get('photo').read()
        audio_encode = request.files.get('audio').read()
    speakerID = int(request.form.get('id'))

    if speakerID == -1:
        speakerID = model.get_db().execute("SELECT MAX(speakerID) FROM speakers").fetchone()['MAX(speakerID)']
        if speakerID is None:
            speakerID = 0
        else:
            speakerID += 1
        if method == 1:
            photo = base64.b64decode(photo)
        args = (speakerID, name, relationship, photo,)
        model.get_db().execute("INSERT INTO speakers(speakerID, fullname, relationship, photo) VALUES (?,?,?,?)", args)
    
    path = forgetMeNot.app.config['MODEL_FILEPATH']

    if not os.path.exists(str(path) + "/" + str(speakerID)):
        os.mkdir(str(path) + "/" + str(speakerID)) 
    
    wav_file = open(str(path) + "/" + str(speakerID) + "/temp.wav", "wb")
    if method == 1:
        audio_encode = base64.b64decode(audio_encode + "========")
    wav_file.write(audio_encode)   
    
    #directories = ""
    #for i in range(0, speakerID + 1):
    #    directories += str(path) + "/" + str(i) + "/  "

    #enrolled = task_enroll(directories , str(path) + "/model.out")
    enrolled = task_enroll(str(path) + "/*", str(path) + "/model.out")
    status = ""
    if(enrolled):
        status = "Success"
    if(not enrolled):
        status = "Failure"

    print(status)
    context = {}
    context['success'] = status
    #context['directories'] = directories

    return flask.jsonify(**context)
