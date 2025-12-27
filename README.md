# Unscroll

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

An intelligent short-form content blocker that helps you take control of your screen time. Block Instagram Reels, YouTube Shorts, and TikTok after reaching your daily limit.

## 🎯 Overview

Unscroll is a Flutter-based mobile application designed to combat doomscrolling and help users maintain a healthier relationship with social media. Set your daily limits for short-form content and let Unscroll automatically block access when you've reached your threshold.

## ✨ Features

- **Smart Content Blocking**: Automatically blocks Instagram Reels, YouTube Shorts, and TikTok
- **Daily Limit Setting**: Set personalized time limits for short-form content consumption
- **Usage Tracking**: Monitor your daily screen time and content consumption patterns
- **Automatic Reset**: Daily limits reset automatically at midnight
- **User-Friendly Interface**: Clean and intuitive design built with Flutter
- **Background Monitoring**: Continuous monitoring without draining battery

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- An Android device or emulator for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/onlyvaibhav/Unscroll.git
cd Unscroll
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🛠️ Building

### For Android

```bash
flutter build apk --release
```

For a smaller app bundle:
```bash
flutter build appbundle --release
```

## 📱 Permissions

Unscroll requires the following permissions to function properly:

- **Usage Stats Access**: To monitor app usage and track time spent on blocked apps
- **Overlay Permission**: To display blocking screens over targeted apps
- **Accessibility Service**: To detect when blocked apps are launched

## 🎨 Tech Stack

- **Framework**: Flutter
- **Language**: Dart (86.9%)
- **Platform**: Android (Kotlin 13.1%)
- **Architecture**: Clean architecture principles

## 📸 Screenshots

<!-- Add your app screenshots here -->
<p align="center">
  <img src="screenshots/home_screen.png" width="250" alt="Home Screen"/>
  <img src="screenshots/settings_screen.png" width="250" alt="Settings Screen"/>
  <img src="screenshots/blocking_screen.png" width="250" alt="Blocking Screen"/>
</p>

> **Note**: Add your screenshots to a `screenshots/` folder in the root directory and update the image paths above.

## 📂 Project Structure

```
Unscroll/
├── android/          # Android-specific code and configurations
├── assets/
│   └── icons/       # App icons and image assets
├── lib/             # Main Flutter application code
├── test/            # Unit and widget tests
├── pubspec.yaml     # Project dependencies and metadata
└── README.md        # Project documentation
```

## ⚙️ Requirements

### System Requirements
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 2.17.0 or higher
- **Android Studio**: Ladybug (2024.2.1) or higher
- **Android SDK**: API Level 23 (Android 6.0) or higher

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute to Unscroll:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Development Roadmap

- [ ] Custom blocking schedules
- [ ] Weekly/monthly usage reports
- [ ] Multiple profile support
- [ ] Whitelist/blacklist management
- [ ] Cloud sync for settings
- [ ] Widget support for quick stats
- [ ] Focus mode integration

## ⚠️ Disclaimer

Unscroll is designed to help users manage their screen time. However, tech-savvy users may find ways to bypass the blocking mechanisms. This app works best as a tool for self-discipline rather than a strict enforcement system.

## 📄 License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2025 Vaibhav

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 👨‍💻 Author

**Vaibhav**
- GitHub: [@onlyvaibhav](https://github.com/onlyvaibhav)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Open-source community for inspiration and resources

## 📞 Support

If you encounter any issues or have questions, please [open an issue](https://github.com/onlyvaibhav/Unscroll/issues) on GitHub.

---

**Take back control of your time. Unscroll today! 📱✨**