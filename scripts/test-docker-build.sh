#!/bin/bash
set -eux
container_name=yolo
docker build -t $container_name --build-arg YOLO_FILE=${YOLO_FILE} model/
docker run --rm -p 5000:5000 -d $container_name
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "Container run successfully"
    curl -L -O https://ultralytics.com/images/bus.jpg
    inference_code=$(curl -X POST -F "file=@bus.jpg" -o /dev/null -s -w "%{http_code}\n" 127.0.0.1:5000/predict)
    if [ $inference_code=='200' ]; then
        echo "Inference of image passed"
    else
        echo "Inference failed with status code ${inference_code}"
        curl -X POST -F "file=@bus.jpg" -o /dev/null -s -w "%{http_code}\n" 127.0.0.1:5000/predict
        exit 1
    fi

else
    echo "Container startup failed with code $exit_code"
    exit 1
fi