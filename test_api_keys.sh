#!/bin/bash

# Test API keys for Submagic and Upload APIs
# This script checks if the required API keys are set in the environment variables.

# Submagic API Docs: https://docs.submagic.co/api-reference/languages
# Upload API Docs: https://docs.upload-post.com/quickstart

# Check for Submagic API key
if [ -z "$SUBMAGIC_API_KEY" ]; then
  echo "Error: SUBMAGIC_API_KEY environment variable is not set."
  exit 1
fi

# Test Submagic API key
echo "Testing Submagic API key..."
response=$(curl -s -X GET "https://api.submagic.co/v1/languages" \
  -H "x-api-key: $SUBMAGIC_API_KEY")

if echo "$response" | grep -q "error\|401\|403"; then
  echo "Error: Submagic API key test failed."
  echo "Response: $response"
  exit 1
fi

echo "Submagic API key test passed."

# Check for Upload API key
if [ -z "$UPLOAD_POST_API_KEY" ]; then
  echo "Error: UPLOAD_POST_API_KEY environment variable is not set."
  exit 1
fi

# Test Upload Post API key by calling the Analytics endpoint
echo "Testing Upload Post API key..."
response=$(curl -s -X GET "https://api.upload-post.com/api/analytics/mrcleverlive?platforms=youtube" \
  -H "Authorization: Apikey $UPLOAD_POST_API_KEY")

if echo "$response" | grep -q "error\|401\|403\|404|success\":false"; then
  echo "Error: Upload Post API key test failed."
  echo "Response: $response"
  exit 1
fi

echo "Upload Post API key test passed."

echo "All API keys are set."