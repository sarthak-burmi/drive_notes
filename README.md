# DriveNotes - A Google Drive Connected Notes App

DriveNotes is a Flutter application that allows users to create, view, and update text notes that are seamlessly synced with Google Drive.

## Features

- 🔐 Google OAuth 2.0 authentication with secure token storage
- 📁 Automatic Google Drive folder creation and management
- 📝 Create, view, edit, and delete text notes
- 🔄 Offline support with automatic sync when back online
- 🌓 Dark/light theme switching
- 📱 Responsive Material 3 design

## Architecture

This project follows a modular, feature-based architecture with:

- **Core Layer**: App-wide utilities, constants, and themes
- **Features Layer**: Feature-specific code organized by domain
  - Auth Feature
  - Notes Feature
- **State Management**: Riverpod for dependency injection and state management
- **Navigation**: GoRouter for declarative routing
- **Error Handling**: Centralized error handling with custom exceptions

## Project Setup

### Prerequisites

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Google Cloud Platform account for OAuth credentials

### Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/drive_notes.git
   cd drive_notes
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Generate the required files:

   ```bash
   # Run build_runner to generate code
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Configure Google OAuth:

   - Create a project in the [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Google Drive API
   - Create OAuth 2.0 credentials (Web application type)
   - Add redirect URIs:
     - `http://localhost:8080`
     - `com.drivenotes.drivenotes:/oauth2redirect`
   - Update the `app_constants.dart` file with your client ID and secret

5. Run the application:
   ```bash
   flutter run
   ```

## Authentication Setup

The app uses Google OAuth 2.0 for authentication. To set up your own credentials:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Credentials"
4. Create OAuth 2.0 client ID credentials (Web application type)
5. Add redirect URIs:
   - `http://localhost:8080`
   - `com.drivenotes.drivenotes:/oauth2redirect`
6. Copy the Client ID and Client Secret
7. Update `lib/core/constants/app_config.dart` with your credentials:
8. DO REMEMBER NOT TO UPLOAD THE APP_CONFIG IN GIT HUB DONT EXPOSE YOUR CREDENTIALS
   ```dart
   static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
   static const String googleClientSecret = 'YOUR_GOOGLE_CLIENT_SECRET';
   ```

## Dependencies

Key libraries used in this project:

- **State Management**: `flutter_riverpod` and `riverpod_annotation`
- **Networking**: `dio` for HTTP requests
- **Google API**: `googleapis` and `googleapis_auth`
- **Secure Storage**: `flutter_secure_storage`
- **Routing**: `go_router`
- **UI**: `flutter_markdown` and `google_fonts`
- **Serialization**: `json_annotation` and `json_serializable`
- **Connectivity**: `connectivity_plus`

## Testing

Run the unit tests with:

```bash
flutter test
```

## Project Structure

```
lib/
├── core/                  # Core functionality
│   ├── constants/         # App-wide constants
│   ├── error/             # Error handling
│   ├── theme/             # App themes
│   └── utils/             # Utilities
├── features/              # Feature modules
│   ├── auth/              # Authentication feature
│   │   ├── data/          # Data layer
│   │   ├── presentation/  # UI layer
│   │   └── providers/     # State providers
│   └── notes/             # Notes feature
│       ├── data/          # Data layer
│       ├── presentation/  # UI layer
│       └── providers/     # State providers
├── router/                # App routing
├── app.dart               # App widget
└── main.dart              # Entry point
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
