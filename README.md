# Catalyst

Catalyst is a cross-platform Flutter application designed to help users build and track habits, set goals, and monitor progress. The app leverages Firebase for authentication and data storage, and supports notifications to keep users engaged.

## Features

- User authentication (Firebase Auth)
- Habit and goal tracking
- Progress dashboard and analytics
- Friends and social features
- Local notifications for reminders
- Cross-platform support: Android, iOS, macOS, Windows, Linux, Web

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart (comes with Flutter)
- Xcode (for iOS/macOS)
- Android Studio (for Android)
- A Firebase project (for authentication and backend)

### Installation

1. Clone the repository:

   ```
   git clone <your-repo-url>
   cd catalyst
   ```

2. Install dependencies:

   ```
   flutter pub get
   ```

3. Set up Firebase:

   - Add your `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) to the respective platform folders.

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

- `lib/` - Main Dart source code
- `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` - Platform-specific code
- `test/` - Unit and widget tests

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements and bug fixes.

## License

This project is licensed under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0).
