import cv2
import onnx
import onnxruntime as ort
import json
import numpy as np

#model = cv2.dnn.readNetFromONNX('yolov3u.onnx')
#width=640
#height=640
#
#img = cv2.imread('test/test.png')
#
#blob = cv2.dnn.blobFromImage(img, 1/255.0, (width, height), swapRB=True, crop=False)
#model.setInput(blob)
#
#output = model.forward()
#out = output[0]
#result = out.transpose()
#print(result[0][4:].max(), result[0][4:].argmax())
#print(sorted(result[0][4:]))
CLASS_FILE='classes.json'
IMAGE_WIDTH=640
IMAGE_HIGHT=640
THRESHOLD=0.5
ort_session = ort.InferenceSession('yolov3u.onnx')

with open(CLASS_FILE, 'r') as classfile:
    classes = json.load(classfile)

img = cv2.imread('test/test.png')
img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
img_resize = cv2.resize(img_rgb, (IMAGE_WIDTH, IMAGE_HIGHT))
img_norm = img_resize.astype(np.float32)/255.0
input_tensor = np.transpose(img_norm, (2, 0, 1))
input_tensor = np.expand_dims(input_tensor, axis=0)
input_tensor = input_tensor.astype(np.float32)
input_name = ort_session.get_inputs()[0].name


output = np.asarray(ort_session.run(None, {input_name: input_tensor}))
output = output[0][0]
output = output.transpose()

detections = np.empty((0,6))

for score in output:
    class_id = score[4:].argmax()
    class_score = score[4:].max()
    detection_score = np.concatenate((score[:4], np.array([class_id, class_score])))
    detections = np.vstack((detections, detection_score))


detections = [ x for x in detections if x[-1] > THRESHOLD ]
detections = [ [ float(y) if x != 4 else str(int(y)) for x, y in enumerate(i)] for i in detections]

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

print(json_output)