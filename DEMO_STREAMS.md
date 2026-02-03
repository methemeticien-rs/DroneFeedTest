# Demo WebRTC Streams Setup

Since RTSP streams aren't working, here are several demo WebRTC feed options that work directly with go2rtc:

## Quick Start - Use Built-in Test Pattern (Recommended)

The easiest option is to use go2rtc's built-in FFmpeg test pattern. It's already configured in `go2rtc.yaml`:

**Stream name: `demo`**

This generates a test pattern on-the-fly with no files needed. Just:
1. Make sure go2rtc is running
2. Use `streamName="demo"` in your Next.js/Flutter apps

## Available Demo Streams

Based on your `go2rtc.yaml` configuration:

### 1. `demo` - FFmpeg Test Pattern (No file needed)
- **Type**: Generated test pattern
- **Resolution**: 1280x720
- **Frame Rate**: 30fps
- **Codec**: H.264
- **Status**: ✅ Ready to use immediately

### 2. `demo2` - Test Pattern with Audio
- **Type**: Generated test pattern with sine wave audio
- **Resolution**: 1280x720
- **Frame Rate**: 30fps
- **Status**: ✅ Ready to use immediately

### 3. `demo3` - Test Video File (Requires file generation)
- **Type**: Pre-recorded test video file
- **Setup**: Run `./create-test-video.sh` first
- **Status**: ⚠️ Requires file generation

### 4. `demo4` - Public HTTP Test Stream
- **Type**: Public test video (Big Buck Bunny)
- **Source**: Google Cloud Storage
- **Status**: ✅ Ready to use (requires internet)

## Setup Instructions

### Option A: Use Built-in Test Pattern (Easiest)

1. **Update your Next.js app** (`nextjs-dashboard/app/page.tsx` or `.env.local`):
   ```typescript
   const streamName = 'demo'; // or 'demo2'
   ```

2. **Update your Flutter app** (`flutter_mobile_app/lib/config/app_config.dart`):
   ```dart
   static const String streamName = 'demo'; // or 'demo2'
   ```

3. **Restart go2rtc** to load the new configuration:
   ```bash
   # Stop go2rtc (Ctrl+C) and restart it
   ./go2rtc
   ```

4. **Test the stream**:
   - Next.js: `cd nextjs-dashboard && npm run dev`
   - Flutter: `cd flutter_mobile_app && flutter run`

### Option B: Generate Test Video File

1. **Generate test video**:
   ```bash
   ./create-test-video.sh
   ```
   This creates a 1-hour test pattern video file.

2. **Uncomment demo3 in go2rtc.yaml**:
   ```yaml
   demo3: file://test-videos/test-pattern.mp4
   ```

3. **Use `demo3` as your stream name** in your apps.

### Option C: Use Public HTTP Stream

1. **Use `demo4` as your stream name** in your apps.
2. **Requires internet connection** to fetch the video.

## Testing

### Verify Stream is Available

Check if go2rtc can see your stream:
```bash
curl http://localhost:1984/api/streams.json
```

You should see your `demo` stream listed.

### Test WebRTC Connection

1. Open your Next.js app
2. Check browser console for WebSocket connection
3. Stream should start automatically

### Test HLS Fallback

If WebRTC fails, HLS should automatically kick in. Check:
```bash
curl http://localhost:1984/api/stream.m3u8?src=demo
```

## Troubleshooting

### Stream not showing up?
- Make sure go2rtc is running: `curl http://localhost:1984/api/streams.json`
- Check go2rtc logs for errors
- Verify the stream name matches exactly (case-sensitive)

### WebRTC not connecting?
- Check browser console for WebSocket errors
- Verify CORS is enabled in go2rtc.yaml (`origin: "*"`)
- The component will automatically fall back to HLS

### HLS not working?
- Make sure HLS is enabled in go2rtc.yaml
- Check that the stream is actually playing in go2rtc
- Try accessing the HLS URL directly in VLC or browser

## Next Steps

Once you have a working demo stream:
1. Test both WebRTC (low latency) and HLS (fallback)
2. Verify it works in both Next.js and Flutter apps
3. When ready, replace with your actual HM30 RTSP stream



