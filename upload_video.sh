#!/bin/bash

# Upload the video using Upload-Post API
# Docs: https://docs.upload-post.com/api/upload-video

set -euo pipefail

# Load environment variables
if [ -f .env ]; then
  source .env
fi

api_url="https://api.upload-post.com/api/upload"
input_file=${1:-}
title=${2:-}

if [ -z "$input_file" ]; then
  echo "Usage: $0 <input_file> <title>"
  exit 1
fi

if [ -z "$title" ]; then
  echo "Usage: $0 <input_file> <title>"
  exit 1
fi

if [ ! -f "$input_file" ]; then
  echo "Error: input file '$input_file' not found."
  exit 1
fi

if [ -z "${UPLOAD_POST_API_KEY:-}" ]; then
  echo "Error: UPLOAD_POST_API_KEY environment variable is not set."
  exit 1
fi

# Show upload details and ask for confirmation
echo ""
echo "=========================================="
echo "Title: $title"
echo "Platform: YouTube, X (Twitter), Instagram, Facebook, TikTok"
echo "File: $input_file"
echo "=========================================="
echo ""
read -p "Proceed with upload? [y/Y to confirm, n/N to cancel]: " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Upload cancelled by user."
  exit 1
fi

curl_args=(
  -X POST "$api_url"
  -H "Authorization: Apikey $UPLOAD_POST_API_KEY"
  -F "user=mrcleverlive"
  -F "title=$title"
  -F "video=@$input_file"
  -F "platform[]=youtube"
  -F "platform[]=x"
  -F "platform[]=instagram"
  -F "platform[]=facebook"
  -F "platform[]=tiktok"
  --progress-bar
)
#  (e.g., "tiktok", "instagram", "linkedin", "youtube", "facebook", "twitter", "threads", "pinterest")

# Capture the response
response=$(mktemp)
http_code=$(curl -w "%{http_code}" -o "$response" --show-error "${curl_args[@]}")

if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
  echo ""
  echo "=========================================="
  echo "✅ VIDEO UPLOADED SUCCESSFULLY"
  echo "=========================================="
  echo ""
  
  # Extract YouTube URL
  youtube_url=$(jq -r '.results.youtube.url // "N/A"' "$response")
  echo "🔗 YouTube URL: $youtube_url"
  
  # Extract video ID
  post_id=$(jq -r '.results.youtube.post_id // "N/A"' "$response")
  echo "📹 Video ID: $post_id"
  
  # Check if video was transcoded
  was_transcoded=$(jq -r '.results.youtube.video_was_transcoded // false' "$response")
  if [ "$was_transcoded" = "true" ]; then
    echo "🔄 Transcoded: Yes"
  else
    echo "🔄 Transcoded: No"
  fi
  
  # Display usage information
  echo ""
  echo "📊 API Usage:"
  usage_count=$(jq -r '.usage.count // "N/A"' "$response")
  usage_limit=$(jq -r '.usage.limit // "N/A"' "$response")
  echo "   • Used: $usage_count / $usage_limit"
  
  echo ""
  echo "=========================================="
  
  rm -f "$response"
else
  echo ""
  echo "=========================================="
  echo "❌ Failed to upload video"
  echo "=========================================="
  echo "HTTP Status Code: $http_code"
  echo ""
  echo "API Response:"
  cat "$response"
  echo ""
  echo "=========================================="
  rm -f "$response"
  exit 1
fi