# 🌐 internet_health_plus

Advanced Internet Connectivity, Latency & Network Quality Detection for Flutter.

<p align="center">
  <img src="https://img.shields.io/pub/v/internet_health_plus?color=blue&label=pub.dev&style=for-the-badge" />
  <img src="https://img.shields.io/badge/null_safety-enabled-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/platform-flutter-blue?style=for-the-badge" />
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/SakshamSharma2026/internet_health_plus/main/assets/banner_image.png" width="480">
</p>

---

# 📸 Example App Preview

<p align="center">
  <img src="https://raw.githubusercontent.com/SakshamSharma2026/internet_health_plus/main/assets/example_app_ss.png" width="480">
</p>


# 📝 Description

`internet_health_plus` is a production-ready Flutter plugin designed to provide **real internet reachability**, **latency measurement**, and **network quality detection** — far beyond what `connectivity_plus` offers.

It helps apps react to:

- Slow networks
- Sudden latency spikes
- Dropped internet
- Captive portals
- Poor connections disguised as Wi-Fi/Mobile

### ✨ Features

- ✔ Real-time internet reachability
- ✔ Latency measurement (ms)
- ✔ Network quality classification
- ✔ Connectivity Plus integration
- ✔ Socket fallback
- ✔ Retry logic with backoff
- ✔ Custom thresholds
- ✔ Highly configurable
- ✔ Production tested

All with **battery-optimized active probing**.

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅ |
| iOS      | ✅ |
| macOS    | ✅ |
| Web      | ✅ |
| Linux    | ✅ |
| Windows  | ✅ |


# 🚀 Installation

```yaml
dependencies:
  internet_health_plus: ^1.0.4
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

&

checker.hasInternetAccess();
```

---

# 🔥 Manual Refresh

```dart
final result = await checker.checkInternetDetailed();
print(result.quality);
```

---


## 🛠 Customization (ProbeOptions)

```dart
final checker = InternetHealthPlus(
  options: ProbeOptions(
    timeout: Duration(seconds: 3),
    periodicProbeInterval: Duration(seconds: 5),
    latencyThresholds: {
      'good': 80,
      'moderate': 250,
    },
  ),
);
```

### Options include:

| Option | Description |
|--------|-------------|
| `httpUrl` | Ping this URL |
| `timeout` | Probe timeout |
| `periodicProbeInterval` | Auto-check interval |
| `latencyThresholds` | Define good/moderate/slow |
| `useHttpHeadWhenHttp` | Use `HEAD` for faster check |
| `socketHost/socketPort` | Fallback method |

---

## 🐢 Detect Slow Internet

```dart
checker.onStatusChange.listen((status) {
  if (status.isSlow) {
    print("Warning: Slow internet detected");
  }
});
```


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

# 📄 License

MIT © SakshamSharma2026

---
