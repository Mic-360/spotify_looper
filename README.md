# 🎵 Spotify Looper

<p align="center">
  <img src="assets/logo.png" width="150" alt="Spotify Looper Logo">
</p>

Spotify Looper is an open-source Flutter app for creating precise loop points in Spotify tracks. It is built for musicians, learners, and anyone who wants repeatable control over song sections on **Web** and **Android**.

## ✨ Features

- Spotify account connection and playback control
- Millisecond-level loop start/end points
- Responsive UI for phone, tablet, and desktop
- Material 3 styling with dynamic theming support
- Web + Android support from one codebase

## 🖼️ Showcase Gallery

<p align="center">
  <img src="assets/images/looper-image%20(1).jpeg" width="220" alt="Pulse Loop screenshot 1" />
  <img src="assets/images/looper-image%20(2).jpeg" width="220" alt="Pulse Loop screenshot 2" />
  <img src="assets/images/looper-image%20(3).jpeg" width="220" alt="Pulse Loop screenshot 3" />
</p>

<p align="center">
    <img src="assets/images/looper-image%20(10).jpeg" width="220" alt="Pulse Loop screenshot 10" />
  <img src="assets/images/looper-image%20(5).jpeg" width="220" alt="Pulse Loop screenshot 5" />
  <img src="assets/images/looper-image%20(6).jpeg" width="220" alt="Pulse Loop screenshot 6" />
</p>

<p align="center">
  <img src="assets/images/looper-image%20(7).jpeg" width="220" alt="Pulse Loop screenshot 7" />
  <img src="assets/images/looper-image%20(8).jpeg" width="220" alt="Pulse Loop screenshot 8" />
  <img src="assets/images/looper-image%20(9).jpeg" width="220" alt="Pulse Loop screenshot 9" />
</p>

## 🧰 Tech Stack

- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev) + code generation
- [`spotify_sdk`](https://pub.dev/packages/spotify_sdk)
- [`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2)
- [`just_audio`](https://pub.dev/packages/just_audio)
- `http`, `shared_preferences`, `flutter_secure_storage`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Dart SDK included) — project uses Dart `^3.10.8`
- A Spotify Developer app (Client ID + Client Secret)
- Chrome (for web) or an Android device/emulator

### 1) Clone

```bash
git clone https://github.com/Mic-360/spotify_looper.git
cd spotify_looper
```

### 2) Configure Spotify credentials

Create `.env.json` in the project root:

```json
{
  "SPOTIFY_CLIENT_ID": "YOUR_CLIENT_ID",
  "SPOTIFY_CLIENT_SECRET": "YOUR_CLIENT_SECRET"
}
```

### 3) Install dependencies

```bash
flutter pub get
```

### 4) Run

```bash
# Web
flutter run -d chrome

# Android
flutter run -d <device_id>
```

## 🛠 Development

### Generate code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Regenerate app/web icons

```bash
dart run icons_launcher:create
```

## 🤝 Contributing

Contributions are welcome!

1. Fork the repo
2. Create a feature branch
3. Make your changes with clear commits
4. Open a Pull Request

Please keep changes focused, tested, and well-described.

## 📄 License

This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

Built with ❤️ by bhaumic.
