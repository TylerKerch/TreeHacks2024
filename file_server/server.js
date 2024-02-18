const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;

// Middleware to parse JSON bodies
app.use(express.json({ limit: '50mb' })); // Adjust the limit as needed
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/images', express.static('images'));

// POST endpoint to upload a base64 encoded image
app.post('/upload', (req, res) => {
    const { imageBase64, filename } = req.body;

    // Check if the imageBase64 and filename are provided
    if (!imageBase64 || !filename) {
        return res.status(400).send('Missing imageBase64 or filename in the request body.');
    }

    // Decode the base64 image
    const imageBuffer = Buffer.from(imageBase64, 'base64');

    // Define the path for the saved image
    const imagePath = path.join(__dirname, 'images', filename);

    // Save the image to the disk
    fs.writeFile(imagePath, imageBuffer, (err) => {
        if (err) {
            console.error('Failed to save the image:', err);
            return res.status(500).send('Failed to save the image.');
        }

        res.send(`https://real-bug-pet.ngrok-free.app/images/${filename}`);
    });
});

// Start the server
app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
});
