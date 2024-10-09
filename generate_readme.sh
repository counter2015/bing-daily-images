#!/bin/bash

# Bing Daily Image Downloader and README Generator
#
# This script automates the process of downloading the daily image from Bing,
# generating a description using OpenAI's GPT-4 model, and updating a README file.
#
# Usage:
#   1. Ensure you have the necessary dependencies installed: curl, wget, jq, base64
#   2. Set the OPENAI_API_KEY environment variable with your OpenAI API key
#   3. Run the script: ./generate_readme.sh
#
# The script will:
#   - Check if today's Bing image has already been downloaded
#   - If not, download the image and request a description from OpenAI
#   - Generate or update the README.md file with the new image and description
#
# Note: This script is designed to be run daily, ideally through a scheduled task or CI/CD pipeline.

# Function to check if image exists
# Usage: if image_exists "ImageName"; then ...
image_exists() {
    local image_name=$1
    if [ -f "images/${image_name}.jpg" ]; then
        return 0  # Image exists
    else
        return 1  # Image does not exist
    fi
}

# Function to get image name without downloading
# Usage: image_name=$(get_image_name)
get_image_name() {
    local tail=$(curl -s "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1" | grep -oP "th\?id=.*?jpg")
    echo $(echo $tail | grep -oP 'OHR\.\K([a-zA-Z]+)')
}

# Function to download the image
# Usage: image_path=$(download_image "ImageName")
download_image() {
    local image_name=$1
    local tail=$(curl -s "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1" | grep -oP "th\?id=.*?jpg")
    wget -O "images/${image_name}.jpg" https://bing.com/${tail}
    echo "images/${image_name}.jpg"
}

# Function to encode image to base64
# Usage: base64_image=$(encode_image "path/to/image.jpg")
encode_image() {
    local image_path=$1
    base64 -i "$image_path"
}

# Function to create JSON payload for OpenAI API
# Usage: temp_json=$(create_json_payload "$base64_image")
create_json_payload() {
    local base64_image=$1
    local temp_json=$(mktemp)
    cat << EOF > "$temp_json"
{
  "model": "gpt-4o1",
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
            "url": "data:image/jpeg;base64,$base64_image"
          }
        }
      ]
    }
  ],
  "max_tokens": 100
}
EOF
    echo "$temp_json"
}

# Function to make API request to OpenAI
# Usage: response=$(make_api_request "$temp_json")
make_api_request() {
    local temp_json=$1
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d @"$temp_json" \
      https://api.openai.com/v1/chat/completions
}

# Function to extract content from OpenAI response
# Usage: content=$(extract_content "$response")
extract_content() {
    local response=$1
    echo $response | jq -r '.choices[0].message.content'
}

# Function to generate README.md
# Usage: generate_readme "$image_path" "$content"
generate_readme() {
    local image_path=$1
    local content=$2
    local current_date=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    cat << EOF > README.md
![Collect Bing.com daily images](https://github.com/counter2015/bing-daily-images/workflows/Collect%20Bing.com%20daily%20images/badge.svg)
## Latest image:
![]($image_path)

EOF

    if [ -z "$content" ]; then
        echo "$content" >> README.md
    else
        echo "" >> README.md
    fi

    cat << EOF >> README.md
Use GitHub Actions to download www.bing.com images.

Last update: $current_date

All images since 2020-05-10 [here](https://github.com/counter2015/bing-daily-images/tree/master/images)
EOF

    echo "README.md has been generated."
}

# Main execution
image_name=$(get_image_name)
if image_exists "$image_name"; then
    echo "Image already exists. Skipping download and API request."
else
    image_path=$(download_image "$image_name")
    base64_image=$(encode_image "$image_path")
    temp_json=$(create_json_payload "$base64_image")
    response=$(make_api_request "$temp_json")
    echo "response: $response"
    rm "$temp_json"
    content=$(extract_content "$response")
    echo "content: $content"
    generate_readme "$image_path" "$content"
fi
