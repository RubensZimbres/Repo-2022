from flask import Flask, request, jsonify
import torch
import torchvision.transforms as transforms

app = Flask(__name__)

# Load your PyTorch model
model = YourModelClass()
model.load_state_dict(torch.load('model.pth'))
model.eval()

# Define the transformation to apply to the input image
transform = transforms.Compose([
    transforms.Resize(24),
    transforms.ToTensor(),
])

@app.route('/predict', methods=['POST'])
def predict():
    # Get the image from the request
    image = request.files['image']

    # Apply the transformation to the image
    image_tensor = transform(image).unsqueeze(0)

    # Pass the image through the model
    output = model(image_tensor)

    # Convert the output to an integer
    prediction = int(output.item())

    # Return the prediction as a JSON response
    return jsonify({'prediction': prediction})

if __name__ == '__main__':
    app.run()

##########################

(venv) $ FLASK_APP=app.py flask run


#(ChatGPT)
curl -X POST -F "image=@image.jpg" http://localhost:5000/predict
