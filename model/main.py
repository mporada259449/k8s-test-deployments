from fastapi import FastAPI, UploadFile
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from os import getenv
import onnxruntime as ort
import numpy as np
import json
import cv2
import json


YOLOVERSION = getenv("YOLOVERSION")
CLASS_FILE = 'classes.json'
IMAGE_WIDTH = 640
IMAGE_HIGHT = 640
THRESHOLD = 0.5
ALLOWED_EXTENSIONS = ['bmp', 'dng', 'jpeg', 'jpg', 'mpo', 'png', 'tif', 'tiff'
                    'webp', 'pfm', 'HEIC']

def checkextenstion(filename):
    extension =  filename.split('.')[-1]
    if not any([extension==ext for ext in ALLOWED_EXTENSIONS]):
        raise ValueError("Extension not supported")

@asynccontextmanager
async def lifespan(app: FastAPI):
    global ort_session
    global classes
    yolo_onnx_file= YOLOVERSION + '.onnx'
    ort_session = ort.InferenceSession(yolo_onnx_file)
    with open(CLASS_FILE, 'r') as classfile:
        classes = json.load(classfile)
    yield

app = FastAPI(lifespan=lifespan)

@app.post("/predict")
async def predict(file: UploadFile) -> JSONResponse:
    try:
        checkextenstion(file.filename)
        content = await file.read()
        nparr = np.frombuffer(content, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        result = forward(image)
    except ValueError:
        return {"Extanssion error": f"Unknown extension of file: {file.filename}"}
    except Exception as e:
        return {'Error': e.__context__}

    return result

def forward(image):
    #image preprocession
    input_tensor = prepocessing_image(image)
    input_name = ort_session.get_inputs()[0].name

    #inference
    input_name = ort_session.get_inputs()[0].name
    output = np.asarray(ort_session.run(None, {input_name: input_tensor}))
    
    #filtering detections with score lower the THRESHOLD
    detections = filter_detections(output)

    #preparing JSONResponse
    json_response = prepare_json(detections)

    return JSONResponse(content=json_response)


def prepocessing_image(img):
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resize = cv2.resize(img_rgb, (IMAGE_WIDTH, IMAGE_HIGHT))
    img_norm = img_resize.astype(np.float32)/255.0
    input_tensor = np.transpose(img_norm, (2, 0, 1))
    input_tensor = np.expand_dims(input_tensor, axis=0)
    input_tensor = input_tensor.astype(np.float32)

    return input_tensor

def filter_detections(output):
    output = output[0][0]
    output = output.transpose()

    detections = []

    for score in output:
        class_id = score[4:].argmax()
        class_score = score[4:].max()
        detection_score = np.concatenate((score[:4], np.array([class_id, class_score])))
        detections.append(detection_score)

    detections = np.vstack(detections)

    detections = [ x for x in detections if x[-1] > THRESHOLD ]
    detections = [ [ float(y) if x != 4 else str(int(y)) for x, y in enumerate(i)] for i in detections]

    return detections 

def prepare_json(detections):
    json_output = []

    for detection in detections:
        detection_dir = {
            'x1': detection[0],
            'y1:': detection[1],
            'x2': detection[2],
            'y2': detection[3],
            'class': classes[detection[4]],
            'class_score': detection[5]
        }
        json_output.append(detection_dir)
        
    return json_output

