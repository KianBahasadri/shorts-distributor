#!/bin/bash
# Add captions to video using Submagic API

if [[ -z "$1" ]]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

if [[ -z "$SUBMAGIC_API_KEY" ]]; then
  echo "Error: SUBMAGIC_API_KEY not set" >&2
  exit 1
fi

input_file=$1
title=$(basename "${input_file%.*}")

# Upload to Submagic
response=$(curl -s -X POST "https://api.submagic.co/v1/projects/upload" \
  -H "x-api-key: $SUBMAGIC_API_KEY" \
  -F "title=$title" \
  -F "language=en" \
  -F "file=@$input_file" \
  -F "templateName=Devin" \
  -F "magicZooms=true" \
  -F "magicBrolls=true" \
  -F "magicBrollsPercentage=0" \
  -F "removeSilencePace=fast" \
  -F "removeBadTakes=true")

error=$(echo "$response" | jq -r '.error // .message // empty')
if [[ -n "$error" ]]; then
  echo "Upload failed: $error" >&2
  exit 1
fi

project_id=$(echo "$response" | jq -r '.id // .project.id // empty')
if [[ -z "$project_id" ]]; then
  echo "No project ID in response" >&2
  exit 1
fi

# Poll status until complete
echo "Processing project $project_id..."
for ((i=0; i<360; i++)); do
  sleep 10
  
  status_response=$(curl -s "https://api.submagic.co/v1/projects/$project_id" \
    -H "x-api-key: $SUBMAGIC_API_KEY")
  
  status=$(echo "$status_response" | jq -r '.status // .project.status // empty')
  if [[ -z "$status" ]]; then
    echo "Failed to parse status" >&2
    exit 1
  fi
  
  echo "Status: $status (${i}0s elapsed)"
  
  if [[ "$status" == "completed" ]]; then
    download_url=$(echo "$status_response" | jq -r '.downloadUrl // .project.downloadUrl // empty')
    if [[ -z "$download_url" ]]; then
      echo "No download URL" >&2
      exit 1
    fi
    
    output_file="${title}_captioned.mp4"
    if ! wget -q --show-progress -O "$output_file" "$download_url"; then
      echo "Download failed" >&2
      exit 1
    fi
    
    echo "$output_file"
    exit 0
    
  elif [[ "$status" == "failed" ]]; then
    reason=$(echo "$status_response" | jq -r '.failureReason // .project.failureReason // empty')
    echo "Processing failed: $reason" >&2
    exit 1
  fi
done

echo "Timeout after 1 hour" >&2
exit 1