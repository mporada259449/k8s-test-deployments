FROM python:3.12
ARG YOLOFILE=yolov3u.pt
ENV YOLOVERSION=${YOLOFILE}

RUN mkdir /app
COPY main.py requirements.txt /app/

WORKDIR /app
RUN apt update
RUN pip3 install -r requirements.txt
RUN curl -O https://github.com/ultralytics/assets/releases/download/v8.3.0/${YOLOVERSION}

CMD [ "fastapi", "run", "main.py", "--host", "0.0.0.0", "--port", "5000" ]