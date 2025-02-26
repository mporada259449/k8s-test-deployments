#!/bin/bash

container_name=yolo
docker build -t $container_name model/
docker run --rm -d $container_name
exit_code=$?
if [ $exit_code ]; then
    echo "Container run with successfully"
else
    echo "Container startup faild with code $exit_code"
    exit 1
fi