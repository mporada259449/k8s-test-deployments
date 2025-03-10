FROM python:3.12
ARG YOLO_FILE
ENV YOLOVERSION=${YOLO_FILE}
#dummy comment
RUN mkdir /app
COPY main.py requirements.txt /app/

WORKDIR /app
RUN apt update && apt install ffmpeg libsm6 libxext6 -y
RUN pip3 install -r requirements.txt
RUN curl -L -O https://github.com/ultralytics/assets/releases/download/v8.3.0/${YOLOVERSION}

CMD [ "fastapi", "run", "main.py", "--host", "0.0.0.0", "--port", "5000" ]