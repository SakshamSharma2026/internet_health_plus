import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'model/internet_status.dart';
import 'model/probe_options.dart';

class InternetHealthPlus {
  // Singleton
  static final InternetHealthPlus _instance = InternetHealthPlus._internal();

  factory InternetHealthPlus({Dio? dio, ProbeOptions? options}) {
    if (dio != null || options != null) {
      // if caller explicitly provided dependencies, create a new instance (not singleton)
      return InternetHealthPlus._withDio(dio: dio, options: options);
    }
    return _instance;
  }

  // Default singleton internal constructor
  InternetHealthPlus._internal()
    : _dio = Dio(
        BaseOptions(responseType: ResponseType.plain, followRedirects: false),
      ),
      _defaultOptions = ProbeOptions() {
    _init();
  }

  // Non-singleton constructor used when injecting Dio/options
  InternetHealthPlus._withDio({Dio? dio, ProbeOptions? options})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              responseType: ResponseType.plain,
              followRedirects: false,
            ),
          ),
      _defaultOptions = options ?? ProbeOptions() {
    _init();
  }

  final Dio _dio;
  final ProbeOptions _defaultOptions;

  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounceTimer;
  Timer? _periodicProbeTimer;

  InternetStatus _lastStatus = InternetStatus(
    networkType: NetworkType.unknown,
    internetAvailable: false,
    latencyMs: null,
    quality: InternetQuality.unknown,
  );

  // rate-limiting trackers
  DateTime? _lastProbeAt;
  bool _probeInProgress = false;

  // expose stream
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  InternetStatus get lastStatus => _lastStatus;

  void _init() {
    // subscribe to connectivity updates and debounce them to avoid repeated probes
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivityEvent,
      onError: (e) {
        // ignore connectivity subscription errors silently
      },
    );

    // initial check (non-blocking)
    _scheduleProbeIfAllowed(reason: 'initial-check');

    // setup periodic probes if configured
    if (_defaultOptions.periodicProbeInterval != null) {
      _periodicProbeTimer = Timer.periodic(
        _defaultOptions.periodicProbeInterval!,
        (_) {
          _scheduleProbeIfAllowed(reason: 'periodic-probe');
        },
      );
    }
  }

  /// Clean up resources
  void dispose() {
    _connectivitySub?.cancel();
    _debounceTimer?.cancel();
    _periodicProbeTimer?.cancel();
    if (!_controller.isClosed) _controller.close();
    // do not close injected Dio (caller owns it). For default singleton Dio, close it.
    try {
      _dio.close(force: true);
    } catch (_) {}
  }

  /// Handle connectivity events (listened from connectivity_plus 6.x which yields List<ConnectivityResult)
  void _onConnectivityEvent(List<ConnectivityResult> results) {
    // Convert list -> single representative result (first if exists)
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    // Debounce: wait for small window before probing (some platforms emit multiple events)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_defaultOptions.connectivityDebounce, () {
      final networkType = _mapConnectivityResult(result);
      if (networkType == NetworkType.none) {
        // immediately update to offline without probing
        _updateStatus(
          InternetStatus(
            networkType: NetworkType.none,
            internetAvailable: false,
            latencyMs: null,
            quality: InternetQuality.unknown,
          ),
        );
        return;
      }
      // For other network types, schedule a probe (subject to rate-limiting)
      _scheduleProbeIfAllowed(reason: 'connectivity-change');
    });
  }

  /// Schedule a probe but respect minProbeInterval and concurrency
  void _scheduleProbeIfAllowed({required String reason}) {
    final now = DateTime.now();
    if (_probeInProgress) {
      return; // don't start another probe while one is in progress
    }
    if (_lastProbeAt != null) {
      final elapsed = now.difference(_lastProbeAt!);
      if (elapsed < _defaultOptions.minProbeInterval) {
        return; // rate-limited
      }
    }
    // start probe (do not block caller)
    _performProbe(reason: reason);
  }

  /// Performs the active probe with retries/backoff, updates state if changed.
  Future<void> _performProbe({required String reason}) async {
    _probeInProgress = true;
    _lastProbeAt = DateTime.now();

    try {
      final probe = await _probeWithRetries(_defaultOptions);
      // read connectivity current state (connectivity_plus 6.x returns List)
      NetworkType netType = NetworkType.unknown;
      try {
        final connectivityList = await Connectivity().checkConnectivity();
        final connectivityResult = connectivityList.isNotEmpty
            ? connectivityList.first
            : ConnectivityResult.none;
        netType = _mapConnectivityResult(connectivityResult);
      } catch (_) {
        netType = NetworkType.unknown;
      }

      final newStatus = InternetStatus(
        networkType: netType,
        internetAvailable: probe.reachable,
        latencyMs: probe.latencyMs,
        quality: _classifyQuality(
          probe.latencyMs,
          _defaultOptions.latencyThresholds,
          probe.reachable,
        ),
      );

      _updateStatus(newStatus);
    } finally {
      _probeInProgress = false;
    }
  }

  /// Retries the probe with exponential backoff (bounded)
  Future<_ProbeResult> _probeWithRetries(ProbeOptions options) async {
    int attempt = 0;
    Duration delay = options.retryBaseDelay;
    while (true) {
      final result = await _probeInternetWithLatency(options);
      if (result.reachable) return result;
      if (attempt >= options.maxRetries) return result;
      // Exponential backoff with jitter
      final jitter = Random().nextInt(100);
      await Future.delayed(
        _minDelay(delay + Duration(milliseconds: jitter), options.maxRetryDelay),
      );
      attempt++;
      delay *= 2;
    }
  }

  Duration _minDelay(Duration d1, Duration max) => d1 <= max ? d1 : max;

  /// Single probe attempt (HTTP via Dio preferred; socket fallback optional)
  Future<_ProbeResult> _probeInternetWithLatency(ProbeOptions options) async {
    // Guard: ensure valid httpUrl
    try {
      final uri = options.httpUrl;
      try {
        final sw = Stopwatch()..start();
        // reuse same Dio instance, but copy timeouts to options for this call
        final r = await _dio.fetch(
          RequestOptions(
            path: uri.toString(),
            method: options.useHttpHeadWhenHttp ? 'HEAD' : 'GET',
            connectTimeout: Duration(
              milliseconds: options.timeout.inMilliseconds,
            ),
            receiveTimeout: Duration(
              milliseconds: options.timeout.inMilliseconds,
            ),
            sendTimeout: Duration(milliseconds: options.timeout.inMilliseconds),
            responseType: ResponseType.plain,
            followRedirects: false,
          ),
        );
        sw.stop();
        final statusCode = r.statusCode ?? 0;
        final reachable = statusCode >= 200 && statusCode < 300;
        final latency = sw.elapsedMilliseconds;
        if (reachable) {
          return _ProbeResult(reachable: true, latencyMs: latency);
        }
        // else fallthrough to socket fallback below if allowed
      } catch (_) {
        // HTTP probe failed — will try socket fallback if configured
      }

      if (options.useSocketFallback) {
        try {
          final sw = Stopwatch()..start();
          final socket = await Socket.connect(
            options.socketHost,
            options.socketPort,
            timeout: options.timeout,
          );
          sw.stop();
          final latency = sw.elapsedMilliseconds;
          socket.destroy();
          return _ProbeResult(reachable: true, latencyMs: latency);
        } catch (_) {
          // socket failed
        }
      }
    } catch (_) {
      // unexpected internal error — treat as unreachable
    }

    return const _ProbeResult(reachable: false, latencyMs: null);
  }

  void _updateStatus(InternetStatus s) {
    if (s != _lastStatus) {
      _lastStatus = s;
      if (!_controller.isClosed) _controller.add(s);
    }
  }

  NetworkType _mapConnectivityResult(ConnectivityResult r) {
    switch (r) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.none:
        return NetworkType.none;
      default:
        return NetworkType.unknown;
    }
  }

  /// Public: one-off check returning a detailed status (might be rate-limited)
  Future<InternetStatus> checkInternetDetailed({ProbeOptions? options}) async {
    final o = options ?? _defaultOptions;
    final probe = await _probeWithRetries(o);

    NetworkType nt = NetworkType.unknown;
    try {
      final connectivityList = await Connectivity().checkConnectivity();
      final connectivityResult = connectivityList.isNotEmpty
          ? connectivityList.first
          : ConnectivityResult.none;
      nt = _mapConnectivityResult(connectivityResult);
    } catch (_) {
      nt = NetworkType.unknown;
    }

    final status = InternetStatus(
      networkType: nt,
      internetAvailable: probe.reachable,
      latencyMs: probe.latencyMs,
      quality: _classifyQuality(
        probe.latencyMs,
        o.latencyThresholds,
        probe.reachable,
      ),
    );

    _updateStatus(status);
    return status;
  }

  /// Public: simple boolean check
  Future<bool> hasInternetAccess({ProbeOptions? options}) async {
    final s = await checkInternetDetailed(options: options);
    return s.internetAvailable;
  }

  InternetQuality _classifyQuality(
    int? latencyMs,
    Map<String, int> thresholds,
    bool reachable,
  ) {
    if (!reachable) return InternetQuality.unknown;
    if (latencyMs == null) return InternetQuality.unknown;
    final good = thresholds['good'] ?? 150;
    final moderate = thresholds['moderate'] ?? 400;
    if (latencyMs <= good) return InternetQuality.good;
    if (latencyMs <= moderate) return InternetQuality.moderate;
    return InternetQuality.slow;
  }
}

/// Simple probe result holder
class _ProbeResult {
  final bool reachable;
  final int? latencyMs;

  const _ProbeResult({required this.reachable, required this.latencyMs});
}
