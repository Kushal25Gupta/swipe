# Swipe - Modern Dating App

![Swipe App](https://img.shields.io/badge/App-Swipe-ff3f6c) 
![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter&logoColor=white) 
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black) 
![License](https://img.shields.io/badge/License-MIT-blue)

## Overview

Swipe is a modern dating application built with Flutter that incorporates privacy features, user verification, and a smooth interface for a better dating experience. The app uses Firebase for backend services and implements modern UI/UX patterns with a focus on user privacy and meaningful connections.

## App Description

Swipe redefines the online dating experience by prioritizing authenticity, security, and meaningful connections. Built with Flutter and powered by Firebase, Swipe offers a seamless cross-platform experience for iOS and Android users looking for genuine relationships.

### Purpose and Vision
Swipe was created to address common issues in dating apps: fake profiles, privacy concerns, and superficial connections. Our vision is to create a safe space where users can be their authentic selves and find compatible matches based on shared interests and values, not just appearances.

### Target Audience
Swipe caters to singles aged 18-40 who are looking for meaningful relationships beyond casual encounters. The app appeals to privacy-conscious users who value verified profiles and authentic connections.

### Key Differentiators
- **Enhanced Privacy Controls**: Users have granular control over what information is shared and with whom
- **Verification System**: Multi-level verification process including email, phone, and optional ID verification to ensure authentic profiles
- **Smart Matching Algorithm**: Goes beyond simple proximity-based matching to consider compatibility factors
- **Interactive Features**: Beyond swiping, users can participate in icebreaker games and guided conversation starters
- **Safe Communication**: End-to-end encrypted chat with the ability to share disappearing media
- **Anti-Harassment Measures**: Advanced reporting system and AI-assisted message screening

### Technical Foundation
The app is built on a solid technical foundation with Flutter providing a beautiful, responsive UI and Firebase handling backend operations including authentication, real-time database, storage, and analytics. The app follows clean architecture principles for maintainability and scalability.

### User Experience
From the moment users open Swipe, they're guided through an intuitive onboarding process that helps them create compelling profiles. The interface is designed to be both visually appealing and functional, with smooth animations and thoughtful micro-interactions that enhance the dating experience.

## Features

- **Card-based Profile Swiping**: Intuitive card swiping interface for discovering potential matches
- **Real-time Chat**: Integrated messaging system for matched users with read receipts and media sharing
- **Profile Customization**: Detailed profile editing with multiple photos, interests, and preferences
- **User Verification**: Secure authentication and profile verification to ensure authentic users
- **Match Recommendations**: Smart matching algorithm based on preferences, gender, and location
- **Activity Tracking**: Notifications and activity feed for user interactions (likes, matches, messages)
- **Filters**: Customizable filters for finding ideal matches based on age, distance, interests, etc.
- **Location-based Matching**: Discover users within specified radius (default 50km)

## App Flow

1. **Authentication**: Login/Signup via email and password with secure verification
2. **Onboarding**: Profile setup with photos, bio, interests, and preferences
3. **Home Screen**: Main interface with Discover, Matches, Messages, and Profile tabs
4. **Discover**: Card swiping interface to like or pass on potential matches
5. **Matches**: View and interact with users you've matched with
6. **Messages**: Real-time chat with matched users including media sharing
7. **Profile**: View and edit your profile information and settings

## Technology Stack

### Frontend
- **Flutter SDK**: ^3.7.0
- **UI Components**: 
  - flutter_card_swiper: ^6.0.0 - For card swiping interface
  - flutter_chat_ui: ^1.6.12 - Chat interface components
  - cached_network_image: ^3.3.1 - Efficient image loading and caching
  - flutter_svg: ^2.0.9 - SVG support
  - shimmer: ^3.0.0 - Loading effects
  - lottie: ^3.0.2 - Animated illustrations
  - animate_do: ^3.3.1 - Animation library
  - flutter_staggered_grid_view: ^0.7.0 - Dynamic grid layouts
  - swipe_cards: ^2.0.0+1 - Alternative card swiping implementation
  - custom_sliding_segmented_control: ^1.8.5 - Custom UI controls

### State Management
- **Bloc Pattern**: flutter_bloc: ^8.1.4 - For reactive and predictable state management
- **Dependency Injection**: get_it: ^7.6.7 - Service locator for dependency injection
- **Provider**: provider: ^6.1.1 - Lighter state management solution
- **Equatable**: equatable: ^2.0.5 - Value equality for model classes

### Backend & Storage
- **Firebase Services**:
  - firebase_core: ^2.27.1 - Core Firebase functionality
  - firebase_auth: ^4.17.9 - Authentication services
  - cloud_firestore: ^4.15.9 - NoSQL database for profiles, matches, and chats
  - firebase_storage: ^11.6.10 - Media storage for user photos
  - firebase_messaging: ^14.7.20 - Push notifications
  - firebase_analytics: ^10.8.9 - Usage analytics
  - firebase_crashlytics: ^3.4.17 - Crash reporting
  - firebase_remote_config: ^4.3.10 - Remote configuration
  - firebase_dynamic_links: ^5.5.7 - Deep linking
  - firebase_database: ^10.4.0 - Realtime database for presence
- **Local Storage**:
  - shared_preferences: ^2.2.2 - Key-value storage
  - flutter_secure_storage: ^9.0.0 - Secure credential storage
  - path_provider: ^2.1.2 - File system access
  - path: ^1.8.3 - Path manipulation
  - file_selector: ^1.0.2 - File selection

### Communication & Location
- **Geolocation**:
  - geolocator: ^11.0.0 - Location services
  - geocoding: ^2.1.1 - Address geocoding
- **Media Handling**:
  - image_picker: ^1.0.7 - Image selection from gallery or camera
  - flutter_sound: ^9.2.13 - Audio recording/playback
  - flutter_contacts: ^1.1.7+1 - Contacts access
  - url_launcher: ^6.2.5 - Opening URLs
  - share_plus: ^7.2.1 - Content sharing
  - open_filex: ^4.3.4 - File opening

### Security & Analytics
- **Security**:
  - encrypt: ^5.0.3 - Encryption utilities
  - flutter_dotenv: ^5.1.0 - Environment variable management
  - uuid: ^4.3.3 - Unique ID generation
- **Analytics**:
  - mixpanel_flutter: ^2.3.0 - User behavior analytics
  - firebase_analytics: ^10.8.9 - Firebase analytics
  - logger: ^2.0.2+1 - Structured logging
  - permission_handler: ^11.3.0 - Permission management
  - connectivity_plus: ^5.0.2 - Network connectivity monitoring
  - device_info_plus: ^10.1.2 - Device information
  - timeago: ^3.7.0 - Relative time calculations

### Internationalization
- **intl**: ^0.19.0 - Internationalization and localization

### UI/UX Enhancements
- **flutter_native_splash**: ^2.3.9 - Customized splash screen
- **flutter_launcher_icons**: ^0.13.1 - App icon customization

### Development & Testing
- **flutter_lints**: ^5.0.0 - Linting rules
- **bloc_test**: ^9.1.6 - BLoC testing utilities
- **mockito**: ^5.4.4 - Mocking for tests
- **build_runner**: ^2.4.8 - Code generation

## Installation

### Prerequisites
- Flutter SDK (^3.7.0)
- Dart SDK (^3.7.0)
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
   - Create a `.env` file in the root directory with the following content:
     ```
     # Firebase Configuration
     FIREBASE_API_KEY=your_firebase_api_key
     FIREBASE_APP_ID=your_firebase_app_id
     FIREBASE_MESSAGING_SENDER_ID=your_firebase_sender_id
     FIREBASE_PROJECT_ID=your_firebase_project_id
     FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
     
     # Add other API keys here
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Environment Variables

This project uses environment variables to keep sensitive information secure. The variables are stored in a `.env` file which is not committed to the repository for security reasons.

### Setting Up Your .env File

Create a `.env` file in the root directory of the project with the following variables:

```
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_firebase_messaging_sender_id
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket

# Add other API keys and sensitive information here
# Examples:
# MAPS_API_KEY=your_google_maps_api_key
# MIXPANEL_TOKEN=your_mixpanel_token
```

### Security Note

- **NEVER commit the .env file to your repository**
- **DO NOT include API keys directly in the code**
- The .env file is included in .gitignore to prevent accidental commits

### For Collaborators

Contact the project maintainer to get the required API keys for development.

## Architecture

The app follows a clean architecture pattern with clearly separated layers:

### Presentation Layer
UI components and state management using the BLoC pattern for a reactive and testable interface.

### Domain Layer
Contains the business logic of the application, independent of any UI or external dependencies.

### Data Layer
Handles data retrieval and storage, interfacing with Firebase and local storage solutions.

### Core Layer
Provides utilities, constants, and shared functionality used across the application.

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
│   │   ├── models/           # Data models
│   │   ├── repositories/     # Repository implementations
│   │   └── services/         # External services (Firebase, etc.)
│   ├── domain/               # Business logic
│   │   ├── entities/         # Core domain models
│   │   ├── repositories/     # Repository interfaces
│   │   └── usecases/         # Application-specific business rules
│   └── presentation/         # UI components
│       ├── screens/          # App screens
│       │   ├── auth/         # Authentication screens
│       │   ├── chat/         # Chat functionality
│       │   ├── home/         # Main app screens
│       │   ├── onboarding/   # Onboarding flow
│       │   └── profile/      # Profile screens
│       └── widgets/          # Reusable UI components
├── test/                     # Test files
└── web/                      # Web specific files
```

## Key Features in Detail

### Matching Algorithm
- Filters users based on gender preferences
- Location proximity with configurable radius
- Exclusion of previously liked/passed profiles
- Interest compatibility

### Real-time Chat
- Implemented with Firestore for real-time updates
- Media sharing capabilities
- Read receipts
- Typing indicators

### User Verification
- Email verification
- Optional phone verification
- Profile verification badges

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
