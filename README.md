# 🎵 Spotify Looper

<p align="center">
  <img src="logo.png" width="150" alt="Spotify Looper Logo">
</p>

Spotify Looper is a modern, high-performance Flutter application designed to give you precise control over your music playback. Whether you're practicing a specific segment of a song, transcribing music, or just want to loop your favorite bridge, Spotify Looper makes it seamless on both Web and Android.

## 🚀 Key Features

- **Spotify Integration**: Seamlessly connect your Spotify account to access your entire library.
- **Precision Looping**: Set custom start and end points for any track with millisecond accuracy.
- **Cross-Platform**: Beautifully optimized for both Android (native experience) and Web (PWA ready).
- **Material 3 Design**: A premium, expressive UI with support for dynamic color theming.
- **Responsive Layouts**: Designed to look great on phones, tablets, and desktop browsers.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev) with Code Generation
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio)
- **Authentication**: Spotify OAuth 2.0 via `flutter_web_auth_2`
- **Networking**: `http` for REST API interactions
- **Theming**: Google Fonts & Material 3 Expressive Design

## 🏁 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.8 or higher)
- [Dart SDK](https://dart.dev/get-started)
- A [Spotify Developer](https://developer.spotify.com/) account for API credentials

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Mic-360/spotify_looper.git
   cd spotify_looper
   ```

2. **Setup environment variables**:
   Create a `.env.json` file in the root directory (this file is gitignored):
   ```json
   {
     "SPOTIFY_CLIENT_ID": "YOUR_CLIENT_ID",
     "SPOTIFY_CLIENT_SECRET": "YOUR_CLIENT_SECRET"
   }
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

### Running the App

- **Web**:
  ```bash
  flutter run -d chrome
  ```

- **Android**:
  ```bash
  flutter run -d <device_id>
  ```

## 🏗 Development Commands

### Code Generation
This project uses `build_runner` for Riverpod and JSON serialization:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Icon Generation
To regenerate app icons and favicons from `logo.png`:
```bash
dart run icons_launcher:create
```

---
*Built with ❤️ by the Spotify Looper Team*

