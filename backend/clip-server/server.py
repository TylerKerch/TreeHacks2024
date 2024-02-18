from flask import Flask, request, jsonify
import torch
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import base64
import io
import json

# Initialize Flask app
app = Flask(__name__)

# Initialize CLIP
model_name = "openai/clip-vit-base-patch32"
model = CLIPModel.from_pretrained(model_name)
processor = CLIPProcessor.from_pretrained(model_name)


@app.route('/tag-image', methods=['POST'])
def tag_image():
    data = request.json

    if 'image_base64' not in data:
        return "No image provided", 400

    image_base64 = data['image_base64']

    try:
        # Decode the Base64 encoded image
        image_data = base64.b64decode(image_base64)
        image = Image.open(io.BytesIO(image_data))

        # Process the image for CLIP
        inputs = processor(images=image, return_tensors="pt")

        # Generate the embedding
        with torch.no_grad():
            embeddings = model.get_image_features(**inputs)

        # Convert embedding tensor to list for JSON serialization
        embeddings_list = embeddings.tolist()

        # Return the embeddings as JSON
        print(embeddings_list)
        return jsonify({"embedding": embeddings_list})

    except Exception as e:
        return str(e), 500


@app.route('/process-image', methods=['POST'])
def process_image():
    data = request.json
    print('here')

    if 'image_base64' not in data:
        return "No image provided", 400

    if 'text_query' not in data:
        return "No text query provided", 400

    if 'predictions' not in data:
        return "No predictions provided", 400

    image_base64 = data['image_base64']
    text_query = data['text_query']
    predictions = data['predictions']
    print(text_query)
    print(predictions)
    try:
        print('reached')
        # Decode the Base64 encoded image
        image_data = base64.b64decode(image_base64)
        print('reached')
        image = Image.open(io.BytesIO(image_data))
        print('reached')
        # Process the text query
        text_input = processor(text=text_query, return_tensors="pt", padding=True)
        print('reached')
        text_features = model.get_text_features(**text_input)
        print('reached')
        batch_size = 32
        sub_image_batches = []
        batch_predictions = []
        for detection_id, prediction in enumerate(predictions):
            x, y, width, height = prediction['x'], prediction['y'], prediction['width'], prediction['height']
            print(x,y,width,height)
            sub_image = image.crop((max(0,x-width/2), max(0,y-height/2), min(image.width, x + width/2), min(image.height, y + height/2)))
            sub_image_batches.append(sub_image)
            prediction['detection_id'] = detection_id
            batch_predictions.append(prediction)

            if len(sub_image_batches) == batch_size or detection_id == len(predictions) - 1:
                sub_image_inputs = processor(images=sub_image_batches, return_tensors="pt", padding=True)

                with torch.no_grad():
                    image_features = model.get_image_features(**sub_image_inputs)

                similarities = torch.nn.functional.cosine_similarity(image_features, text_features)

                for prediction, similarity in zip(batch_predictions, similarities):
                    print(similarity)
                    prediction['similarity'] = similarity.item()

                sub_image_batches = []
                batch_predictions = []

        sorted_predictions = sorted(predictions, key=lambda x: x['similarity'], reverse=True)
        print(sorted_predictions)

        return jsonify({'predictions': sorted_predictions})

    except Exception as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(port=8081, debug=True)
