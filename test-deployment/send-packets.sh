#!/bin/bash
set -xe
ENDPOINT=$1
echo "Downloading test images"
export WORKSPACE="test-dir"
if [ -d "$WORKSPACE" ]; then
    rm -rf "$WORKSPACE"
fi
    
mkdir -p $WORKSPACE
pushd $WORKSPACE 

curl -L -O  https://github.com/ultralytics/assets/releases/download/v0.0.0/coco8.zip

echo "Unzip and gether images"
unzip  "coco8.zip"
mkdir images results
find ./coco8 -type f -name "*.jpg" -exec cp {} images \;

popd

python3 -m venv venv
. venv/bin/activate
pip3 install requests

python3 send-packets.py  $WORKSPACE $ENDPOINT

