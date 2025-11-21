# 🌐 internet_health_plus

Advanced Internet Connectivity, Latency & Network Quality Detection for Flutter.

<p align="center">
  <img src="https://img.shields.io/pub/v/internet_health_plus?color=blue&label=pub.dev&style=for-the-badge" />
  <img src="https://img.shields.io/github/license/SakshamSharma2026/internet_health_plus?style=for-the-badge" />
  <img src="https://img.shields.io/badge/null_safety-enabled-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/platform-flutter-blue?style=for-the-badge" />
</p>

---

# 📸 Example App Preview

<p align="center">
  <img src="https://github.com/SakshamSharma2026/internet_health_plus/blob/main/assets/banner_image.png" width="420">
</p>

---

# 📝 Description

`internet_health_plus` is a production-ready Flutter plugin designed to provide **real internet reachability**, **latency measurement**, and **network quality detection** — far beyond what `connectivity_plus` offers.

It helps apps react to:

- Slow networks
- Sudden latency spikes
- Dropped internet
- Captive portals
- Poor connections disguised as Wi-Fi/Mobile

All with **battery-optimized active probing**.

---

# ❤️ Why Choose `internet_health_plus`?

### ⭐ Real Internet Health
It checks actual connectivity (HTTP + socket fallback), not just WiFi/mobile status.

### ⭐ Detect Slow/Moderate/Good Networks
Based on real latency measurements.

### ⭐ Real-Time Stream Updates
Receive events instantly via:
```dart
Stream<InternetStatus>
```

### ⭐ Battery Efficient
- Debouncing
- Rate limiting
- Shared Dio instance
- Retry with exponential backoff

### ⭐ Works Everywhere
- Android
- iOS
- Desktop
- Flutter Web (best effort)

### ⭐ Riverpod Ready
Built for reactive state management.

---

# ✨ Features

- ✔ Real-time internet reachability
- ✔ Latency measurement (ms)
- ✔ Network quality classification
- ✔ Connectivity Plus integration
- ✔ Socket fallback
- ✔ Retry logic with backoff
- ✔ Custom thresholds
- ✔ Highly configurable
- ✔ Production tested

---

# 🚀 Installation

```yaml
dependencies:
  internet_health_plus: ^1.0.0
```

---

# 📦 Import

```dart
import 'package:internet_health_plus/internet_health_plus.dart';
```

---

# 🎯 Quick Usage

```dart
final checker = InternetHealthPlus();

checker.onStatusChange.listen((status) {
  print('Network: ${status.networkType}');
  print('Reachable: ${status.internetAvailable}');
  print('Latency: ${status.latencyMs}');
  print('Quality: ${status.quality}');
});
```

---

# 🔥 Manual Refresh

```dart
final result = await checker.checkInternetDetailed();
print(result.quality);
```

---

# 🧩 Riverpod Integration

```dart
final internetCheckerProvider = Provider<InternetHealthPlus>((ref) {
  final checker = InternetHealthPlus();
  ref.onDispose(() => checker.dispose());
  return checker;
});

final internetStatusStreamProvider = StreamProvider<InternetStatus>((ref) {
  final checker = ref.watch(internetCheckerProvider);

  final controller = StreamController<InternetStatus>();
  controller.add(checker.lastStatus);

  final sub = checker.onStatusChange.listen(controller.add);

  checker.checkInternetDetailed(); // initial probe

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
```

---

# 🧪 Testing Slow Internet

### ✔ Android Emulator → Edge / GPRS
### ✔ iOS Simulator → Network Link Conditioner
### ✔ Router throttling
### ✔ Override thresholds:

```dart
ProbeOptions(latencyThresholds: {'good': 5, 'moderate': 10});
```

---

# 🧠 Architecture

```
 +-------------------------------+
 |      InternetHealthPlus       |
 |-------------------------------|
 | Connectivity listener         |
 | HTTP probe (Dio)              |
 | Socket fallback               |
 | Latency measurement           |
 | Debounce + rate-limit         |
 | Retry with backoff            |
 | Emits InternetStatus          |
 +-------------------------------+
                 |
                 v
      +-----------------------+
      |    InternetStatus     |
      +-----------------------+
      | networkType           |
      | internetAvailable     |
      | latencyMs             |
      | quality               |
      +-----------------------+
```

---

# 📄 CHANGELOG.md

```
## 1.0.0
- Initial release
- Internet reachability detection
- Latency measurement
- Network quality classification
- Real-time status stream
- Battery optimized probe scheduler
- Riverpod integration example
```

---

# 📦 Pub.dev Metadata

Add to `pubspec.yaml`:

```yaml
homepage: https://github.com/SakshamSharma2026/internet_health_plus
repository: https://github.com/SakshamSharma2026/internet_health_plus
issue_tracker: https://github.com/SakshamSharma2026/internet_health_plus/issues
documentation: https://github.com/SakshamSharma2026/internet_health_plus#readme
topics:
  - internet
  - connectivity
  - network
  - latency
  - performance
```

---

# 📄 License

MIT © SakshamSharma2026

---
