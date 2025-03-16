#!/bin/bash
set -eux
container_name=yolo
docker build -t $container_name --build-arg YOLO_FILE=${YOLO_FILE} model/
docker run --rm -p 5000:5000 -d $container_name
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "Container run successfully"
    curl -L -O https://ultralytics.com/images/bus.jpg
    inference_result=$(curl -X POST -F "file=@bus.jpg" 127.0.0.1:5000/predict)
    if grep -q 'Error' <<< "${inference_result}"; then
        echo "Inference failed with result: ${inference_result}"
        exit 1
    else
        echo "Inference of image passed"
    fi
else
    echo "Container startup failed with code $exit_code"
    exit 1
fi