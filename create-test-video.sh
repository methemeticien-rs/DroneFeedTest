#!/bin/bash

# Create a test video file for go2rtc streaming
# This generates a test pattern video that can be used as a demo feed

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: FFmpeg is not installed."
    echo "Install it with: brew install ffmpeg (on macOS)"
    exit 1
fi

OUTPUT_DIR="test-videos"
OUTPUT_FILE="${OUTPUT_DIR}/test-pattern.mp4"
DURATION=3600  # 1 hour of video (can loop)

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Creating test video file..."
echo "Output: $OUTPUT_FILE"
echo "This may take a few minutes..."
echo ""

# Generate test pattern video with timestamp
ffmpeg -f lavfi -i testsrc2=size=1280x720:rate=30 \
       -f lavfi -i sine=frequency=1000:duration=${DURATION} \
       -vf "drawtext=text='%{localtime}':fontsize=24:fontcolor=white:x=10:y=10" \
       -c:v libx264 -preset medium -crf 23 \
       -c:a aac -b:a 128k \
       -t ${DURATION} \
       -y "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Test video created successfully!"
    echo "File: $OUTPUT_FILE"
    echo ""
    echo "You can now use this in go2rtc.yaml:"
    echo "  demo: file://$(pwd)/$OUTPUT_FILE"
    echo ""
    echo "Or use the absolute path:"
    echo "  demo: file://$(realpath $OUTPUT_FILE)"
else
    echo ""
    echo "✗ Failed to create test video"
    exit 1
fi



