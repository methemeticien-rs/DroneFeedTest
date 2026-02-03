#!/bin/bash

# Test RTSP Stream Server using FFmpeg
# This script creates a test RTSP stream that simulates a drone feed

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: FFmpeg is not installed."
    echo "Install it with: brew install ffmpeg (on macOS)"
    exit 1
fi

# Configuration
RTSP_PORT=8554
STREAM_PATH="test"
RTSP_URL="rtsp://localhost:${RTSP_PORT}/${STREAM_PATH}"

echo "Starting test RTSP stream server..."
echo "Stream URL: ${RTSP_URL}"
echo ""
echo "Press Ctrl+C to stop the stream"
echo ""

# Create test pattern stream (color bars with timestamp)
# This creates a looping test pattern that looks like a camera feed
ffmpeg -re -f lavfi -i testsrc2=size=1280x720:rate=30 \
       -f lavfi -i sine=frequency=1000:duration=0 \
       -c:v libx264 -preset ultrafast -tune zerolatency \
       -b:v 2000k -maxrate 2000k -bufsize 4000k \
       -g 30 -keyint_min 30 -sc_threshold 0 \
       -c:a aac -b:a 128k \
       -f rtsp -rtsp_transport tcp \
       rtsp://localhost:${RTSP_PORT}/${STREAM_PATH}

