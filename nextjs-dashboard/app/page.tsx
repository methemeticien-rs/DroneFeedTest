'use client';

import DroneStreamPlayer from '@/components/DroneStreamPlayer';

export default function Home() {
  // Environment variables are loaded from .env.local
  // See .env.local.example for setup instructions
  const tunnelUrl = process.env.NEXT_PUBLIC_TUNNEL_URL || 'localhost:1984';
  const streamName = process.env.NEXT_PUBLIC_STREAM_NAME || 'demo';

  return (
    <div className="min-h-screen bg-gray-900 p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-white mb-6">Drone Stream Dashboard</h1>
        <div className="w-full" style={{ height: 'calc(100vh - 120px)' }}>
          <DroneStreamPlayer 
            tunnelUrl={tunnelUrl}
            streamName={streamName}
          />
        </div>
      </div>
    </div>
  );
}
