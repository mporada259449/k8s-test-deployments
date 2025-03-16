from ultralytics import YOLO
from os import getenv
import json
CLASS_FILE=getenv('CLASS_FILE')
model = YOLO('yolov3u.pt')

with open(CLASS_FILE, 'w') as classes:
    classdir = model.names
    json.dump(classdir, classes)