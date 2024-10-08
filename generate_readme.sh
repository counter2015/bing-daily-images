#!/bin/bash

# download image
tail=`curl "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1" | grep -oP "th\?id=.*?jpg"`
image_name=`echo $tail | grep -oP 'OHR\.\K([a-zA-Z]+)'`
wget -O "images/${image_name}.jpg" https://bing.com/${tail}

image=`ls -t images/*.jpg | head -1`
echo latest image is $image

# API credentials
# OPENAI_API_KEY="read-your-key-here-or-set-it-as-an-environment-variable"

# Image path
IMAGE_PATH=$image

# Encode image to base64
BASE64_IMAGE=$(base64 -i "$IMAGE_PATH")

# Create a temporary file for the JSON payload
TEMP_JSON=$(mktemp)

# Construct the JSON payload and save it to the temporary file
cat << EOF > "$TEMP_JSON"
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Describe this image in one sentence."
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,$BASE64_IMAGE"
          }
        }
      ]
    }
  ],
  "max_tokens": 100
}
EOF

# Make the API request
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @"$TEMP_JSON" \
  https://api.openai.com/v1/chat/completions)

echo $RESPONSE

# Remove the temporary file
rm "$TEMP_JSON"

# Extract the content from the response
CONTENT=$(echo $RESPONSE | jq -r '.choices[0].message.content')

# Get current date and time in UTC
CURRENT_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Generate README.md
cat << EOF > README.md
![Collect Bing.com daily images](https://github.com/counter2015/bing-daily-images/workflows/Collect%20Bing.com%20daily%20images/badge.svg)
## Latest image:
![]($IMAGE_PATH)

EOF

# Add CONTENT to README.md only if it's not empty
if [ ! -z "$CONTENT" ]; then
    echo "$CONTENT" >> README.md
    echo "" >> README.md  # Add a newline after the content
fi

# Continue with the rest of the README
cat << EOF >> README.md
Use GitHub Actions to download www.bing.com images.

Last update: $CURRENT_DATE

All images since 2020-05-10 [here](https://github.com/counter2015/bing-daily-images/tree/master/images)
EOF

echo "README.md has been generated."
