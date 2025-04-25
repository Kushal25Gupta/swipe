# Swipe - Modern Dating App

![Swipe App](https://img.shields.io/badge/App-Swipe-ff3f6c) 
![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter&logoColor=white) 
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black) 
![License](https://img.shields.io/badge/License-MIT-blue)

## Overview

Swipe is a modern dating application built with Flutter that incorporates privacy features, user verification, and a smooth interface for a better dating experience. The app uses Firebase for backend services and implements modern UI/UX patterns.

## Features

- **Card-based Profile Swiping**: Intuitive card swiping interface for discovering potential matches
- **Real-time Chat**: Integrated messaging system for matched users
- **Profile Customization**: Detailed profile editing with multiple photos, interests, and preferences
- **User Verification**: Secure authentication and profile verification
- **Match Recommendations**: Smart matching algorithm based on preferences and location
- **Activity Tracking**: Notifications and activity feed for user interactions
- **Filters**: Customizable filters for finding ideal matches
- **Location-based Matching**: Discover users within specified radius

## Technology Stack

### Frontend
- **Flutter SDK**: ^3.7.0
- **UI Components**: 
  - flutter_card_swiper: ^6.0.0
  - flutter_chat_ui: ^1.6.12
  - cached_network_image: ^3.3.1
  - flutter_svg: ^2.0.9
  - shimmer: ^3.0.0
  - lottie: ^3.0.2
  - animate_do: ^3.3.1
  - flutter_staggered_grid_view: ^0.7.0

### State Management
- **Bloc Pattern**: flutter_bloc: ^8.1.4
- **Dependency Injection**: get_it: ^7.6.7
- **Provider**: provider: ^6.1.1
- **Equatable**: equatable: ^2.0.5

### Backend & Storage
- **Firebase Services**:
  - firebase_core: ^2.27.1
  - firebase_auth: ^4.17.9
  - cloud_firestore: ^4.15.9
  - firebase_storage: ^11.6.10
  - firebase_messaging: ^14.7.20
  - firebase_analytics: ^10.8.9
  - firebase_dynamic_links: ^5.5.7
- **Local Storage**:
  - shared_preferences: ^2.2.2
  - flutter_secure_storage: ^9.0.0

### Communication & Location
- **Geolocation**:
  - geolocator: ^11.0.0
  - geocoding: ^2.1.1
- **Media Handling**:
  - image_picker: ^1.0.7
  - flutter_sound: ^9.2.13
  - path_provider: ^2.1.2

### Security & Analytics
- **Security**:
  - encrypt: ^5.0.3
  - flutter_dotenv: ^5.1.0
- **Analytics**:
  - mixpanel_flutter: ^2.3.0
  - firebase_analytics: ^10.8.9

## Installation

### Prerequisites
- Flutter SDK (^3.7.0)
- Dart SDK (^3.0.0)
- Android Studio / XCode
- Firebase account

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/swipe.git
   cd swipe
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and place the configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS

4. **Set up environment variables**
   - Create a `.env` file in the root directory
   - Add necessary environment variables (API keys, etc.)

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
swipe/
├── android/                  # Android specific configurations
├── ios/                      # iOS specific configurations
├── assets/                   # Static assets (images, fonts, animations)
├── lib/
│   ├── app/                  # App level classes (router, app config)
│   ├── config/               # Configuration files
│   ├── core/                 # Core utilities, constants, themes
│   ├── data/                 # Data handling (repositories, models, services)
│   ├── domain/               # Business logic
│   └── presentation/         # UI components
│       ├── screens/          # App screens
│       └── widgets/          # Reusable UI components
├── test/                     # Test files
└── web/                      # Web specific files
```

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Flutter Team for the amazing framework
- Firebase for backend services
- All open-source package contributors
