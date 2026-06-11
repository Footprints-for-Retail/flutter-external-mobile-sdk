import 'package:flutter/material.dart';
import 'package:footprints_sdk/footprints_sdk.dart';

void main() {
  runApp(const FootprintsExampleApp());
}

class FootprintsExampleApp extends StatelessWidget {
  const FootprintsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Footprints SDK Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FootprintsSdk _sdk;
  String _status = 'Not initialized';
  ContentDeliveryResponse? _content;

  @override
  void initState() {
    super.initState();
    _sdk = FootprintsSdk(
      baseUrl: 'https://staging.footprints-ai.com',
      appKey: 'YOUR_APP_KEY_HERE',
      config: const FootprintsConfig(
        enableLocation: false,
        enableOfflineQueue: true,
        logLevel: LogLevel.debug,
      ),
    );
    _initSdk();
  }

  Future<void> _initSdk() async {
    setState(() => _status = 'Initializing...');

    final result = await _sdk.init();
    if (result.isSuccess) {
      setState(() => _status = 'Initialized (mobileId: ${result.data?.mobileId})');
      _fetchContent();
    } else {
      setState(() => _status = 'Init failed: ${result.error}');
    }
  }

  Future<void> _fetchContent() async {
    final result = await _sdk.getContentDelivery(
      screenIdentifier: 'home',
    );
    if (result.isSuccess) {
      setState(() => _content = result.data);
    }
  }

  @override
  void dispose() {
    _sdk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Footprints SDK Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 16),
            if (_content?.data != null) ...[
              Text(
                'Display ads: ${_content!.data!.displayAd.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final ad in _content!.data!.displayAd)
                FootprintsDisplayAd(
                  adContent: ad,
                  onAdClick: (ad) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Clicked: ${ad.title}')),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
