from fastapi import FastAPI, UploadFile
from fastapi.responses import JSONResponse
from ultralytics import YOLO
from contextlib import asynccontextmanager
from os import getenv
import logging
from io import BytesIO
from PIL import Image

YOLOVERSION=getenv("YOLOVERSION")
ALLOWED_EXTENSIONS=['bmp', 'dng', 'jpeg', 'jpg', 'mpo', 'png', 'tif', 'tiff'
                    'webp', 'pfm', 'HEIC']

def checkextenstion(filename):
    extension =  filename.split('.')[-1]
    if not any([extension==ext for ext in ALLOWED_EXTENSIONS]):
        raise ValueError("Extension not supported")

@asynccontextmanager
async def lifespan(app: FastAPI):
    global model
    model = YOLO(YOLOVERSION)
    yield

app = FastAPI(lifespan=lifespan)

@app.post("/predict")
async def predict(file: UploadFile) -> JSONResponse:
    try:
        checkextenstion(file.filename)
        image = Image.open(file.file)
        result = model(image)
    except ValueError:
        return {"Extanssion error": f"Unknown extension of file: {file.filename}"}
    except Exception as e:
        return {'Error': e.__context__}

    return result[0].to_json()
