from flask import Flask
from flask_cors import CORS

# import logging
# import sys

# logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

app = Flask(__name__)
CORS(app)


@app.route('/')
def hello():
    return 'My First API !!'