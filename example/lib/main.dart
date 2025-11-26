import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_health_plus/internet_health_plus.dart';

void main() {
  runApp(const MyApp());
}

// Root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internet Health Plus Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InternetHealthDemoPage(),
    );
  }
}

// Very simple page that shows current internet status
class InternetHealthDemoPage extends StatefulWidget {
  const InternetHealthDemoPage({super.key});

  @override
  State<InternetHealthDemoPage> createState() => _InternetHealthDemoPageState();
}

class _InternetHealthDemoPageState extends State<InternetHealthDemoPage> {
  // 1) Create the _internetHealthPlus
  final _internetHealthPlus = InternetHealthPlus();

  // 2) Hold the latest status in state
  InternetStatus _internetStatus = const InternetStatus(
    networkType: NetworkType.unknown,
    internetAvailable: false,
  );

  StreamSubscription<InternetStatus>? _internetStatusSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // 3) Listen to changes
    _internetStatusSubscription = _internetHealthPlus.onStatusChange.listen((
      status,
    ) {
      setState(() => _internetStatus = status);
    });

    // 4) Do an initial check
    _refreshNow();
  }

  @override
  void dispose() {
    _internetStatusSubscription?.cancel();
    _internetHealthPlus.dispose(); // important!
    super.dispose();
  }

  Future<void> _refreshNow() async {
    setState(() => _isRefreshing = true);
    try {
      await _internetHealthPlus
          .checkInternetDetailed(); // triggers a probe + stream update
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _networkLabel(NetworkType type) {
    switch (type) {
      case NetworkType.wifi:
        return 'Wi-Fi';
      case NetworkType.mobile:
        return 'Mobile';
      case NetworkType.ethernet:
        return 'Ethernet';
      case NetworkType.none:
        return 'Offline';
      case NetworkType.unknown:
        return 'Unknown';
    }
  }

  Color _qualityColor(InternetQuality q) {
    switch (q) {
      case InternetQuality.good:
        return Colors.green;
      case InternetQuality.moderate:
        return Colors.orange;
      case InternetQuality.slow:
        return Colors.red;
      case InternetQuality.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qualityColor = _qualityColor(_internetStatus.quality);
    return Scaffold(
      appBar: AppBar(title: const Text('Internet Health Plus')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connection Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Network type
                _InfoRow(
                  label: 'Network',
                  value: _networkLabel(_internetStatus.networkType),
                ),

                const SizedBox(height: 8),

                // Online / offline
                _InfoRow(
                  label: 'Online',
                  value: _internetStatus.internetAvailable ? 'Yes' : 'No',
                ),

                const SizedBox(height: 8),

                // Latency
                _InfoRow(
                  label: 'Latency',
                  value: _internetStatus.latencyMs != null
                      ? '${_internetStatus.latencyMs} ms'
                      : '-',
                ),

                const SizedBox(height: 8),

                // Quality
                _InfoRow(
                  label: 'Quality',
                  value: _internetStatus.quality.name,
                  valueColor: qualityColor,
                ),

                const SizedBox(height: 16),

                if (_internetStatus.isSlow)
                  const Text(
                    'Your connection is currently slow. '
                    'You may want to reduce data usage.',
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRefreshing ? null : _refreshNow,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isRefreshing ? 'Checking...' : 'Refresh now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small helper widget for label/value rows
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final styleLabel = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]);
    final styleValue = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: valueColor ?? Colors.black,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: styleLabel),
        Text(value, style: styleValue),
      ],
    );
  }
}
