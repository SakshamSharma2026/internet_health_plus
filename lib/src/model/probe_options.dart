/// Probe configuration and behavior tuning.
/// Use factory constructor to avoid const/const-evaluation issues.
class ProbeOptions {
  final String socketHost;
  final int socketPort;
  final Uri httpUrl;
  final Duration timeout;

  /// Use HEAD when probing HTTP (faster).
  final bool useHttpHeadWhenHttp;

  /// Debounce rapid connectivity events (e.g., 500ms) before probing.
  final Duration connectivityDebounce;

  /// Minimum interval between active probes (rate limit) to save battery.
  final Duration minProbeInterval;

  /// When connected, optionally perform a low-frequency periodic probe (e.g., every 5 minutes)
  /// to detect connection degradation even if connectivity doesn't change.
  final Duration? periodicProbeInterval;

  /// Retry settings for transient errors (exponential backoff).
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;

  /// Latency thresholds used to classify quality.
  final Map<String, int> latencyThresholds;

  /// Whether to prefer socket fallback when HTTP-probe fails.
  final bool useSocketFallback;

  const ProbeOptions._({
    required this.socketHost,
    required this.socketPort,
    required this.httpUrl,
    required this.timeout,
    required this.useHttpHeadWhenHttp,
    required this.connectivityDebounce,
    required this.minProbeInterval,
    required this.periodicProbeInterval,
    required this.maxRetries,
    required this.retryBaseDelay,
    required this.maxRetryDelay,
    required this.latencyThresholds,
    required this.useSocketFallback,
  });

  factory ProbeOptions({
    String socketHost = '8.8.8.8',
    int socketPort = 53,
    Uri? httpUrl,
    Duration timeout = const Duration(seconds: 4),
    bool useHttpHeadWhenHttp = true,
    Duration connectivityDebounce = const Duration(milliseconds: 500),
    Duration minProbeInterval = const Duration(seconds: 5),
    Duration? periodicProbeInterval = const Duration(minutes: 5),
    int maxRetries = 2,
    Duration retryBaseDelay = const Duration(milliseconds: 300),
    Duration maxRetryDelay = const Duration(seconds: 2),
    Map<String, int>? latencyThresholds,
    bool useSocketFallback = true,
  }) {
    return ProbeOptions._(
      socketHost: socketHost,
      socketPort: socketPort,
      httpUrl:
          httpUrl ??
          Uri(
            scheme: 'https',
            host: 'clients3.google.com',
            path: '/generate_204',
          ),
      timeout: timeout,
      useHttpHeadWhenHttp: useHttpHeadWhenHttp,
      connectivityDebounce: connectivityDebounce,
      minProbeInterval: minProbeInterval,
      periodicProbeInterval: periodicProbeInterval,
      maxRetries: maxRetries,
      retryBaseDelay: retryBaseDelay,
      maxRetryDelay: maxRetryDelay,
      latencyThresholds:
          latencyThresholds ?? const {'good': 150, 'moderate': 400},
      useSocketFallback: useSocketFallback,
    );
  }

  ProbeOptions copyWith({
    String? socketHost,
    int? socketPort,
    Uri? httpUrl,
    Duration? timeout,
    bool? useHttpHeadWhenHttp,
    Duration? connectivityDebounce,
    Duration? minProbeInterval,
    Duration? periodicProbeInterval,
    int? maxRetries,
    Duration? retryBaseDelay,
    Duration? maxRetryDelay,
    Map<String, int>? latencyThresholds,
    bool? useSocketFallback,
  }) {
    return ProbeOptions(
      socketHost: socketHost ?? this.socketHost,
      socketPort: socketPort ?? this.socketPort,
      httpUrl: httpUrl ?? this.httpUrl,
      timeout: timeout ?? this.timeout,
      useHttpHeadWhenHttp: useHttpHeadWhenHttp ?? this.useHttpHeadWhenHttp,
      connectivityDebounce: connectivityDebounce ?? this.connectivityDebounce,
      minProbeInterval: minProbeInterval ?? this.minProbeInterval,
      periodicProbeInterval:
          periodicProbeInterval ?? this.periodicProbeInterval,
      maxRetries: maxRetries ?? this.maxRetries,
      retryBaseDelay: retryBaseDelay ?? this.retryBaseDelay,
      maxRetryDelay: maxRetryDelay ?? this.maxRetryDelay,
      latencyThresholds: latencyThresholds ?? this.latencyThresholds,
      useSocketFallback: useSocketFallback ?? this.useSocketFallback,
    );
  }
}
