#!/bin/bash

# Alternative: Simple test RTSP stream using MediaMTX (rtsp-simple-server)
# This is easier to set up and more reliable for testing

# Check if MediaMTX is installed
if ! command -v mediamtx &> /dev/null; then
    echo "MediaMTX not found. Installing..."
    echo ""
    echo "On macOS, install with:"
    echo "  brew install mediamtx"
    echo ""
    echo "Or download from: https://github.com/bluenviron/mediamtx/releases"
    exit 1
fi

echo "Starting MediaMTX RTSP server..."
echo "Stream will be available at: rtsp://localhost:8554/test"
echo ""
echo "To push a test stream, run in another terminal:"
echo "  ffmpeg -re -f lavfi -i testsrc2=size=1280x720:rate=30 -c:v libx264 -f rtsp rtsp://localhost:8554/test"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start MediaMTX with default config
mediamtx



