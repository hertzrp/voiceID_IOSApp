"""
forgetMeNot index (main) view.

URLs include:
/
"""
import flask
import forgetMeNot

from flask import session
from flask import render_template
from flask import request
from flask import redirect
from flask import url_for

@forgetMeNot.app.route('/')
def show_index():
    """Display / route."""

    # Connect to database
    connection = forgetMeNot.model.get_db()

    # Query database
    cur = connection.execute(
        "SELECT speakerID, fullname "
        "FROM speakers"
    )
    speakers = cur.fetchall()

    # Add database info to context
    context = {"speakers": speakers}
    return flask.render_template("index.html", **context)
   

@forgetMeNot.app.route('/identify/')
def show_identify():
    return flask.render_template("identify.html")