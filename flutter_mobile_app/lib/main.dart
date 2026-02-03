import 'package:flutter/material.dart';
import 'pages/live_stream_page.dart';
import 'config/app_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Stream',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuration is now managed in lib/config/app_config.dart
    // Update AppConfig.tunnelUrl and AppConfig.streamName there
    final tunnelUrl = AppConfig.tunnelUrl;
    final streamName = AppConfig.streamName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drone Stream'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LiveStreamPage(
                  tunnelUrl: tunnelUrl,
                  streamName: streamName,
                ),
              ),
            );
          },
          child: const Text('Open Live Stream'),
        ),
      ),
    );
  }
}
