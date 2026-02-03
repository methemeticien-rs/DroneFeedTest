import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LiveStreamPage extends StatefulWidget {
  final String tunnelUrl;
  final String streamName;

  const LiveStreamPage({
    Key? key,
    required this.tunnelUrl,
    required this.streamName,
  }) : super(key: key);

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.tunnelUrl.isEmpty || widget.streamName.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Tunnel URL or stream name is missing';
      });
      return;
    }

    // Construct HLS stream URL from go2rtc
    final streamUrl =
        'https://${widget.tunnelUrl}/api/stream.m3u8?src=${Uri.encodeComponent(widget.streamName)}';

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isBuffering = true;
      _isInitialized = false;
    });

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      _controller!.addListener(_videoListener);
      _controller!
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _isBuffering = false;
              });
              _controller!.play();
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage =
                    'Failed to initialize video player: ${error.toString()}';
                _isBuffering = false;
                _isInitialized = false;
              });
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error creating video player: ${e.toString()}';
          _isBuffering = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    if (_controller!.value.isBuffering && !_isBuffering) {
      setState(() {
        _isBuffering = true;
      });
    } else if (!_controller!.value.isBuffering && _isBuffering) {
      setState(() {
        _isBuffering = false;
      });
    }

    if (_controller!.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage =
            _controller!.value.errorDescription ?? 'Unknown video player error';
      });
    }
  }

  void _reconnect() {
    _disposeController();
    _initializePlayer();
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
    }
    setState(() {
      _isInitialized = false;
      _isBuffering = false;
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Drone Stream',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isInitialized && !_hasError ? Colors.red : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Video Player
          if (_isInitialized && _controller != null && !_hasError)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(child: SizedBox()),
            ),

          // Buffering Indicator
          if (_isBuffering)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Buffering stream...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Error Display with Reconnect Button
          if (_hasError)
            Container(
              color: Colors.black87,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Stream Error',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Unknown error occurred',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _reconnect,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


