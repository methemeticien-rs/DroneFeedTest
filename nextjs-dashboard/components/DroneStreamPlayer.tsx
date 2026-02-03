'use client';

import { useEffect, useRef, useState } from 'react';

interface DroneStreamPlayerProps {
  tunnelUrl: string;
  streamName: string;
}

export default function DroneStreamPlayer({ tunnelUrl, streamName }: DroneStreamPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const pcRef = useRef<RTCPeerConnection | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isLive, setIsLive] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [useHLS, setUseHLS] = useState(false);

  // Initialize WebRTC stream connection
  const initializeWebRTC = async () => {
    if (!videoRef.current || !tunnelUrl || !streamName) {
      setError('Tunnel URL or stream name is missing');
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setError(null);

      // Construct WebSocket URL for go2rtc
      const wsProtocol = tunnelUrl.startsWith('localhost') ? 'ws' : 'wss';
      const wsUrl = `${wsProtocol}://${tunnelUrl}/api/ws?src=${encodeURIComponent(streamName)}`;

      // Create WebSocket connection
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      // Create RTCPeerConnection
      const pc = new RTCPeerConnection({
        iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
      });
      pcRef.current = pc;

      // Handle incoming track
      pc.ontrack = (event) => {
        if (videoRef.current && event.track) {
          videoRef.current.srcObject = event.streams[0];
          setIsLive(true);
          setIsLoading(false);
        }
      };

      // Handle ICE candidates
      pc.onicecandidate = (event) => {
        if (event.candidate && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'ice', candidate: event.candidate }));
        }
      };

      // Handle connection state changes
      pc.onconnectionstatechange = () => {
        if (pc.connectionState === 'failed' || pc.connectionState === 'disconnected') {
          setError('WebRTC connection failed. Trying HLS fallback...');
          setUseHLS(true);
          cleanup();
        }
      };

      // Handle WebSocket messages
      ws.onopen = async () => {
        // Create offer
        const offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        ws.send(JSON.stringify({ type: 'webrtc', sdp: offer.sdp }));
      };

      ws.onmessage = async (event) => {
        try {
          const message = JSON.parse(event.data);
          
          if (message.type === 'webrtc' && message.sdp) {
            await pc.setRemoteDescription(new RTCSessionDescription({ type: 'answer', sdp: message.sdp }));
          } else if (message.type === 'ice' && message.candidate) {
            await pc.addIceCandidate(new RTCIceCandidate(message.candidate));
          }
        } catch (err) {
          console.error('Error handling WebSocket message:', err);
        }
      };

      ws.onerror = () => {
        setError('WebSocket connection failed. Trying HLS fallback...');
        setUseHLS(true);
        cleanup();
      };

      ws.onclose = () => {
        setIsLive(false);
        if (!useHLS) {
          setError('WebSocket connection closed');
        }
      };

    } catch (err) {
      console.error('WebRTC initialization error:', err);
      setError('WebRTC not supported. Using HLS fallback...');
      setUseHLS(true);
      cleanup();
    }
  };

  // Initialize HLS stream (fallback)
  const initializeHLS = () => {
    if (!videoRef.current || !tunnelUrl || !streamName) {
      setError('Tunnel URL or stream name is missing');
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setError(null);

      const protocol = tunnelUrl.startsWith('localhost') ? 'http' : 'https';
      const hlsUrl = `${protocol}://${tunnelUrl}/api/stream.m3u8?src=${encodeURIComponent(streamName)}`;

      if (videoRef.current) {
        // Use native HLS if supported (Safari, iOS)
        if (videoRef.current.canPlayType('application/vnd.apple.mpegurl')) {
          videoRef.current.src = hlsUrl;
          videoRef.current.addEventListener('loadedmetadata', () => {
            setIsLive(true);
            setIsLoading(false);
          });
          videoRef.current.addEventListener('error', () => {
            setError('Failed to load HLS stream');
            setIsLoading(false);
            setIsLive(false);
          });
        } else {
          // Use hls.js for browsers that don't support native HLS
          // Dynamic import to avoid SSR issues
          const loadHls = async () => {
            try {
              const HlsModule = await import('hls.js');
              const Hls = HlsModule.default || (HlsModule as any);
              if (Hls.isSupported()) {
                const hls = new Hls({
                  enableWorker: true,
                  lowLatencyMode: true,
                  backBufferLength: 90,
                });
                hls.loadSource(hlsUrl);
                hls.attachMedia(videoRef.current!);
                hls.on(Hls.Events.MANIFEST_PARSED, () => {
                  setIsLive(true);
                  setIsLoading(false);
                });
                hls.on(Hls.Events.ERROR, (_event: any, data: any) => {
                  if (data.fatal) {
                    setError('HLS playback error');
                    setIsLoading(false);
                    setIsLive(false);
                  }
                });
              } else {
                setError('HLS is not supported in this browser');
                setIsLoading(false);
              }
            } catch (err) {
              setError('Failed to load HLS.js library');
              setIsLoading(false);
            }
          };
          loadHls();
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to initialize HLS stream');
      setIsLoading(false);
    }
  };

  // Cleanup function
  const cleanup = () => {
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
    if (pcRef.current) {
      pcRef.current.close();
      pcRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
      videoRef.current.src = '';
    }
  };

  // Initialize stream
  useEffect(() => {
    if (useHLS) {
      initializeHLS();
    } else {
      initializeWebRTC();
    }

    return () => {
      cleanup();
    };
  }, [tunnelUrl, streamName, useHLS]);

  // Handle fullscreen toggle
  const toggleFullscreen = async () => {
    if (!videoRef.current) return;

    try {
      if (!isFullscreen) {
        if (videoRef.current.requestFullscreen) {
          await videoRef.current.requestFullscreen();
        } else if ((videoRef.current as any).webkitRequestFullscreen) {
          await (videoRef.current as any).webkitRequestFullscreen();
        } else if ((videoRef.current as any).msRequestFullscreen) {
          await (videoRef.current as any).msRequestFullscreen();
        }
      } else {
        if (document.exitFullscreen) {
          await document.exitFullscreen();
        } else if ((document as any).webkitExitFullscreen) {
          await (document as any).webkitExitFullscreen();
        } else if ((document as any).msExitFullscreen) {
          await (document as any).msExitFullscreen();
        }
      }
    } catch (err) {
      console.error('Fullscreen error:', err);
    }
  };

  // Listen for fullscreen changes
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };

    document.addEventListener('fullscreenchange', handleFullscreenChange);
    document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
    document.addEventListener('msfullscreenchange', handleFullscreenChange);

    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
      document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.removeEventListener('msfullscreenchange', handleFullscreenChange);
    };
  }, []);

  return (
    <div className="relative w-full h-full bg-black rounded-lg overflow-hidden shadow-2xl">
      {/* Live Status Indicator */}
      <div className="absolute top-4 left-4 z-10 flex items-center gap-2">
        <div
          className={`flex items-center gap-2 px-3 py-1.5 rounded-full backdrop-blur-md ${
            isLive
              ? 'bg-red-600/90 text-white'
              : 'bg-gray-600/90 text-gray-200'
          }`}
        >
          <div
            className={`w-2 h-2 rounded-full ${
              isLive ? 'bg-white animate-pulse' : 'bg-gray-300'
            }`}
          />
          <span className="text-xs font-semibold uppercase tracking-wide">
            {isLive ? 'Live' : 'Offline'}
          </span>
        </div>
        {useHLS && (
          <div className="px-2 py-1 bg-blue-600/90 text-white text-xs rounded">
            HLS
          </div>
        )}
      </div>

      {/* Loading Indicator */}
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/50 z-20">
          <div className="flex flex-col items-center gap-3">
            <div className="w-12 h-12 border-4 border-white/20 border-t-white rounded-full animate-spin" />
            <p className="text-white text-sm">
              {useHLS ? 'Loading HLS stream...' : 'Connecting to WebRTC stream...'}
            </p>
          </div>
        </div>
      )}

      {/* Error Message */}
      {error && !isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/80 z-20">
          <div className="text-center px-4">
            <p className="text-red-400 text-sm mb-2">{error}</p>
            <button
              onClick={() => {
                cleanup();
                setUseHLS(false);
                setTimeout(() => initializeWebRTC(), 100);
              }}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Retry Connection
            </button>
          </div>
        </div>
      )}

      {/* Video Element */}
      <video
        ref={videoRef}
        className="w-full h-full object-contain"
        autoPlay
        playsInline
        muted={false}
        controls={false}
      />

      {/* Controls Overlay */}
      <div className="absolute bottom-4 right-4 z-10">
        <button
          onClick={toggleFullscreen}
          className="p-2.5 bg-black/60 hover:bg-black/80 text-white rounded-lg backdrop-blur-sm transition-colors"
          aria-label="Toggle fullscreen"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            {isFullscreen ? (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            ) : (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
              />
            )}
          </svg>
        </button>
      </div>
    </div>
  );
}
