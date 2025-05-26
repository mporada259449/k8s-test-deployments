import os
import sys
import time
import csv
import requests
from datetime import datetime

if len(sys.argv) != 3:
    print("Usage: python send_requests.py <WORKSPACE_DIR> <ENDPOINT_URL>")
    sys.exit(1)

WORKSPACE_DIR = sys.argv[1]
ENDPOINT_URL = sys.argv[2]
IMAGES_DIR = os.path.join(WORKSPACE_DIR, "images")
LOG_FILE = os.path.join(WORKSPACE_DIR, "request_log.csv")

URL=f'http://{ENDPOINT_URL}:5000/predict'

if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, mode='w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["timestamp", "filename", "status", "status_code", "time_taken", "message"])

def log_request(timestamp, filename, status, status_code, time_taken):
    with open(LOG_FILE, mode='a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([timestamp, filename, status, status_code, f"{time_taken:.3f}"])

def send_file(file_path):
    filename = os.path.basename(file_path)
    timestamp = datetime.now().isoformat()
    start_time = time.time()

    try:
        with open(file_path, 'rb') as f:
            files = {'file': (filename, f)}
            response = requests.post(URL, files=files, timeout=3)
            elapsed = time.time() - start_time

            log_request(timestamp, filename, "SUCCESS", response.status_code, elapsed)

    except requests.RequestException as e:
        elapsed = time.time() - start_time
        log_request(timestamp, filename, "ERROR", str(e), elapsed)


while True:
    for filename in os.listdir(IMAGES_DIR):
        if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
            send_file(os.path.join(IMAGES_DIR, filename))
