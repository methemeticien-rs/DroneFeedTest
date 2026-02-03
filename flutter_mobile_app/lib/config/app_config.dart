/// App Configuration
///
/// This file manages environment variables and configuration for the Flutter app.
///
/// For development, update the values below directly.
/// For production, consider using flutter_dotenv package or build-time configuration.
class AppConfig {
  // Your Cloudflare Tunnel URL (without https:// prefix)
  // Examples:
  //   - For local testing: 'localhost:1984'
  //   - For Cloudflare Tunnel: 'my-tunnel-abc123.trycloudflare.com'
  //   - For custom domain: 'drone-stream.example.com'
  static const String tunnelUrl = 'localhost:1984';

  // The stream name from go2rtc.yaml
  // Available demo options (no RTSP required):
  //   - 'demo' (FFmpeg test pattern - recommended, works immediately)
  //   - 'demo2' (Test pattern with audio)
  //   - 'demo3' (Test video file - requires create-test-video.sh)
  //   - 'demo4' (Public HTTP test stream - Big Buck Bunny)
  //   - 'hm30' (Your actual drone stream when available)
  static const String streamName = 'demo';

  // Helper method to get the full stream URL
  static String getStreamUrl() {
    return 'https://$tunnelUrl/api/stream.m3u8?src=${Uri.encodeComponent(streamName)}';
  }

  // Helper method to get the WebSocket URL (for reference)
  static String getWebSocketUrl() {
    return 'wss://$tunnelUrl/api/ws?src=${Uri.encodeComponent(streamName)}';
  }
}
