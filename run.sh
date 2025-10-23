
#!/bin/bash

# Source the .env file for API keys
source .env

# Entry point for the shorts distribution pipeline
# This script orchestrates the process: test API keys, add captions, upload video, and archive files.

# First argument is the input file
input_file=$1

if [ -z "$input_file" ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

# Copy the input file to the local directory with _preprocessing suffix
base_filename="$(basename "$input_file")"
filename_no_ext="${base_filename%.*}"
extension="${base_filename##*.}"
local_input_file="${filename_no_ext}_preprocessing.${extension}"
cp "$input_file" "$local_input_file"
echo "Copied input file to local directory: $local_input_file"

# Test API keys
echo "Testing API keys..."
./test_api_keys.sh
if [ $? -ne 0 ]; then
  echo "API key test failed. Exiting."
  exit 1
fi

# Add captions using Submagic API
echo "Adding captions..."
captioned_file=$(./add_captions.sh "$local_input_file")
if [ $? -ne 0 ]; then
  echo "Adding captions failed. Exiting."
  exit 1
fi

# Rename the captioned file back to original filename
output_file="${base_filename}"
mv "$captioned_file" "$output_file"
echo "Renamed captioned file to: $output_file"

# Extract title from original filename (without extension)
video_title="${filename_no_ext}"

# Upload the video using Upload-Post API 
echo "Uploading video to Upload-Post..."
./upload_video.sh "$output_file" "$video_title"
if [ $? -ne 0 ]; then
  echo "Uploading failed. Exiting."
  exit 1
fi

# Move working files to last-generated-videos/<timestamp>
timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p "last-generated-videos/$timestamp"
mv "$local_input_file" "$output_file" "last-generated-videos/$timestamp/"

echo "Pipeline completed successfully. Files moved to last-generated-videos/$timestamp"

