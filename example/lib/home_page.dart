import 'package:example/provider/riverpod_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_health_plus/internet_health_plus.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(internetStatusStreamProvider);

    return Scaffold(
      // extend body behind status bar for a modern look
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF0B3A5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: statusAsync.when(
            data: (status) => _StatusView(status: status),
            loading: () => const Center(child: _LoadingCard()),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small, modern loading card
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: SizedBox(
        width: 320,
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 12),
              Text(
                'Checking network...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusView extends ConsumerWidget {
  final InternetStatus status;

  const _StatusView({required this.status});

  Color _qualityColor(InternetQuality q) {
    switch (q) {
      case InternetQuality.good:
        return Colors.greenAccent.shade400;
      case InternetQuality.moderate:
        return Colors.amberAccent.shade700;
      case InternetQuality.slow:
        return Colors.redAccent.shade700;
      case InternetQuality.unknown:
        return Colors.blueGrey.shade200;
    }
  }

  IconData _qualityIcon(InternetQuality q) {
    switch (q) {
      case InternetQuality.good:
        return Icons.signal_wifi_4_bar;
      case InternetQuality.moderate:
        return Icons.network_wifi_2_bar;
      case InternetQuality.slow:
        return Icons.signal_cellular_connected_no_internet_4_bar;
      case InternetQuality.unknown:
        return Icons.device_unknown;
    }
  }

  String _networkLabel(NetworkType t) {
    switch (t) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checker = ref.read(internetCheckerProvider);
    final qualityColor = _qualityColor(status.quality);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 420 ? screenWidth - 32 : 420.0;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Card(
          key: ValueKey(
            '${status.networkType}_${status.internetAvailable}_${status.latencyMs}_${status.quality}',
          ),
          color: Colors.white.withValues(alpha: 0.06),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: cardWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // header row with icon + title
                  const Text(
                    'Internet Health Plus',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  Divider(color: Colors.white),
                  SizedBox(height: 40),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: qualityColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _qualityIcon(status.quality),
                          size: 28,
                          color: qualityColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _networkLabel(status.networkType),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Online chip
                      AnimatedOpacity(
                        opacity: status.internetAvailable ? 1 : 0.85,
                        duration: const Duration(milliseconds: 300),
                        child: _SmallChip(
                          label: status.internetAvailable
                              ? 'ONLINE'
                              : 'OFFLINE',
                          color: status.internetAvailable
                              ? Colors.greenAccent.shade400
                              : Colors.redAccent.shade400,
                          icon: status.internetAvailable
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // metrics row
                  Row(
                    children: [
                      // latency block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latency',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  status.latencyMs != null
                                      ? '${status.latencyMs} ms'
                                      : '-',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 8,
                                        value: (status.latencyMs != null)
                                            ? (_clampLatencyToProgress(
                                                status.latencyMs!,
                                              ))
                                            : 0.0,
                                        backgroundColor: Colors.white10,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              qualityColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // quality block
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Quality',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  _qualityIcon(status.quality),
                                  color: qualityColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _prettyQuality(status.quality),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // actions / contextual message
                  AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        if (status.isSlow) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Your connection speed is currently slow - consider switching to a better network.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  // optional manual refresh
                                  // final checker = context.read(internetCheckerProvider);
                                  // await checker.checkInternet();
                                  await checker.checkInternetDetailed();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      duration: Duration(seconds: 1),
                                      content: Text(
                                        'Refreshing connection status...',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Refresh',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _prettyQuality(InternetQuality q) {
    switch (q) {
      case InternetQuality.good:
        return 'Good';
      case InternetQuality.moderate:
        return 'Moderate';
      case InternetQuality.slow:
        return 'Slow';
      case InternetQuality.unknown:
        return 'Unknown';
    }
  }

  /// Maps latency (ms) to a 0..1 progress for the indicator (clamped for UX).
  double _clampLatencyToProgress(int latencyMs) {
    // lower latency => small value; higher => closer to 1
    final min = 0.0;
    final max = 800.0; // beyond 800ms treat as full
    final v = latencyMs.toDouble().clamp(min, max) / max;
    return v; // 0..1
  }
}

/// small pill/chip used in header
class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
