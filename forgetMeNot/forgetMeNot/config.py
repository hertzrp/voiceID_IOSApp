"""
forgetMeNot development configuration.
"""

import pathlib

# Root of this application, useful if it doesn't occupy an entire domain
APPLICATION_ROOT = '/'

# File Upload to var/uploads/ !!ADD LATER!!
FORGETMENOT_ROOT = pathlib.Path(__file__).resolve().parent.parent
#UPLOAD_FOLDER = FORGETMENOT_ROOT/'var'/'uploads'
#ALLOWED_EXTENSIONS = set(['png', 'jpg', 'jpeg', 'gif'])
#MAX_CONTENT_LENGTH = 16 * 1024 * 1024

# Database file is var/insta485.sqlite3
DATABASE_FILENAME = FORGETMENOT_ROOT/'var'/'forgetMeNot.sqlite3'
# Model filepath
MODEL_FILEPATH = FORGETMENOT_ROOT/'forgetMeNot'/'api'/'audio'
# MODEL_FILEPATH = FORGETMENOT_ROOT/'speaker-recognition-py3'
