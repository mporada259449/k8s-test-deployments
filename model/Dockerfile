FROM python:3.12-slim-bookworm AS export-model
ARG YOLO_FILE
ENV YOLOVERSION=${YOLO_FILE}
ENV CLASS_FILE='classes.json'

RUN mkdir /exportdir

WORKDIR /exportdir
COPY get-classes.py /exportdir/
RUN apt update && apt install ffmpeg libsm6 libxext6 curl -y
RUN pip3 install ultralytics onnx onnxruntime

RUN curl -L -O https://github.com/ultralytics/assets/releases/download/v8.3.0/${YOLOVERSION}.pt
RUN yolo export model=${YOLOVERSION}.pt format=onnx imgsz=640,640

RUN python3 get-classes.py

FROM python:3.12-slim-bookworm AS server-runner
ARG YOLO_FILE
ENV YOLOVERSION=${YOLO_FILE}
ENV CLASS_FILE='classes.json'

RUN mkdir /app
COPY --from=export-model /exportdir/${YOLO_FILE}.onnx /exportdir/${CLASS_FILE} /app/
COPY main.py requirements.txt /app/


WORKDIR /app
RUN pip3 install --no-cache-dir -r requirements.txt

CMD [ "fastapi", "run", "main.py", "--host", "0.0.0.0", "--port", "5000" ]