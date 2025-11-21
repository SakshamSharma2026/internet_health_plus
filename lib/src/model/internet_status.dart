import 'package:flutter/foundation.dart';

/// Network type exposed to callers
enum NetworkType { wifi, mobile, ethernet, none, unknown }

/// Latency-based quality
enum InternetQuality { good, moderate, slow, unknown }

@immutable
class InternetStatus {
  final NetworkType networkType;
  final bool internetAvailable;
  final int? latencyMs;
  final InternetQuality quality;

  const InternetStatus({
    required this.networkType,
    required this.internetAvailable,
    this.latencyMs,
    this.quality = InternetQuality.unknown,
  });

  bool get isSlow => quality == InternetQuality.slow;

  InternetStatus copyWith({
    NetworkType? networkType,
    bool? internetAvailable,
    int? latencyMs,
    InternetQuality? quality,
  }) {
    return InternetStatus(
      networkType: networkType ?? this.networkType,
      internetAvailable: internetAvailable ?? this.internetAvailable,
      latencyMs: latencyMs ?? this.latencyMs,
      quality: quality ?? this.quality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InternetStatus &&
          runtimeType == other.runtimeType &&
          networkType == other.networkType &&
          internetAvailable == other.internetAvailable &&
          latencyMs == other.latencyMs &&
          quality == other.quality;

  @override
  int get hashCode =>
      networkType.hashCode ^
      internetAvailable.hashCode ^
      (latencyMs ?? 0) ^
      quality.hashCode;
}
