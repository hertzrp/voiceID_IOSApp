"""REST API for getting speakers."""
import flask
from flask import request

import forgetMeNot
from forgetMeNot import model


@forgetMeNot.app.route('/getspeakers/')
def getspeakers():
    # Connect to database
    connection = forgetMeNot.model.get_db()

    # Query database
    cur = connection.execute("SELECT speakerID, fullname, relationship, photo FROM speakers").fetchall()
    speakers = []
    for speaker in cur:
        speakers.append(speaker)
    
    # Add database info to context
    context = {"speakers": speakers}
    return flask.jsonify(**context) 
