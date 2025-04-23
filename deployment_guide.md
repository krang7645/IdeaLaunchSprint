# LaunchPad Notebook - Deployment Guide

This guide provides comprehensive instructions for deploying the LaunchPad Notebook application to production environments.

## Project Structure

The complete project structure is as follows:

```
launchpad_notebook/
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── lib/
│   ├── main.dart            # Application entry point
│   ├── models/              # Data models
│   │   ├── idea.dart
│   │   ├── todo.dart
│   │   └── subscription_plan.dart
│   ├── screens/             # UI screens
│   │   ├── home_screen.dart
│   │   ├── add_idea_screen.dart
│   │   ├── steps_screen.dart
│   │   ├── notification_screen.dart
│   │   ├── auth/            # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── reset_password_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── settings/        # Settings screens
│   │   │   ├── settings_screen.dart
│   │   │   └── api_key_screen.dart
│   │   ├── legal/           # Legal screens
│   │   │   ├── privacy_policy_screen.dart
│   │   │   └── terms_screen.dart
│   │   └── subscription_screen.dart
│   ├── services/            # Business logic and API integration
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── notification_service.dart
│   │   ├── secure_api_service.dart
│   │   ├── proxy_service.dart
│   │   └── subscription_service.dart
│   ├── utils/               # Utility classes and functions
│   │   └── constants.dart
│   └── widgets/             # Reusable UI components
│       ├── idea_card.dart
│       ├── capture_step.dart
│       ├── validate_step.dart
│       ├── build_step.dart
│       └── publish_step.dart
├── assets/
│   ├── fonts/               # Typography
│   │   ├── SF-Pro-Display-Regular.otf
│   │   ├── SF-Pro-Display-Bold.otf
│   │   ├── NotoSansJP-Regular.otf
│   │   └── NotoSansJP-Bold.otf
│   ├── images/              # Images and icons
│   │   ├── logo.png
│   │   ├── onboarding1.png
│   │   ├── onboarding2.png
│   │   ├── onboarding3.png
│   │   └── onboarding4.png
│   └── legal/               # Legal documents
│       ├── privacy_policy.md
│       └── terms_of_service.md
├── server/                  # Backend proxy server
│   ├── index.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env
├── supabase/                # Database schema and functions
│   └── schema.sql
├── .gitignore
├── pubspec.yaml             # Flutter dependencies
├── firebase_options.dart    # Firebase configuration
└── README.md
```

## Prerequisites

Before deploying, ensure you have the following:

1. **Flutter SDK** (3.0.0 or higher)
2. **Supabase Account**
3. **Firebase Account** (for push notifications)
4. **OpenAI API Key**
5. **RevenueCat Account** (for subscription management)
6. **Apple Developer Account** (for iOS deployment)
7. **Google Play Developer Account** (for Android deployment)
8. **Node.js** (for backend proxy server)
9. **Docker** (optional, for containerized deployment of the backend)

## Step 1: Environment Setup

### 1.1 Flutter Setup

Ensure Flutter is installed and updated to the latest stable version:

```bash
flutter upgrade
flutter doctor
```

### 1.2 Supabase Setup

1. Create a new Supabase project from the [Supabase Dashboard](https://supabase.com/dashboard)
2. Execute the SQL schema in `supabase/schema.sql` in the SQL Editor
3. Configure Row Level Security (RLS) policies as defined in the schema

### 1.3 Firebase Setup

1. Create a new Firebase project from the [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to the project
3. Download `google-services.json` and place it in the `android/app` directory
4. Download `GoogleService-Info.plist` and place it in the `ios/Runner` directory
5. Enable Firebase Cloud Messaging (FCM) for push notifications

### 1.4 RevenueCat Setup

1. Create a new project in [RevenueCat](https://www.revenuecat.com/)
2. Configure your app's subscription plans (Monthly and Yearly)
3. Link your Apple App Store Connect and Google Play Developer accounts
4. Get your API keys for iOS and Android

## Step 2: Configuration

### 2.1 Update Constants

Edit `lib/utils/constants.dart` to include your configuration values:

```dart
class AppConstants {
  // Supabase configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Backend proxy server
  static const String backendUrl = 'YOUR_BACKEND_URL';
  
  // Colors
  static final Color primaryColor = Color(0xFFFF9800);
  static final Color progressColor = Color(0xFF4CAF50);
  static final Color dangerColor = Color(0xFFF44336);
  
  // Timer extensions
  static const Duration captureSaveExtension = Duration(days: 7);
  static const Duration validateAnswerExtension = Duration(hours: 48);
  static const Duration buildTodoExtension = Duration(hours: 24);
}
```

### 2.2 Update Firebase Configuration

Generate Firebase configuration files using the Firebase CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 2.3 Add Subscription Keys

Update your RevenueCat API keys in `lib/services/subscription_service.dart`:

```dart
// RevenueCat API keys
static const String _revenueCatApiKeyIOS = 'YOUR_REVENUECAT_IOS_API_KEY';
static const String _revenueCatApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_API_KEY';
```

### 2.4 Backend Server Configuration

Update the `.env` file in the `server` directory with your configuration:

```
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_supabase_service_key
OPENAI_API_KEY=your_openai_api_key
PORT=3000
```

## Step 3: Deploy Backend Proxy Server

### 3.1 Deploying to Heroku

```bash
cd server
heroku create launchpad-backend
git init
heroku git:remote -a launchpad-backend
git add .
git commit -m "Initial backend commit"
git push heroku master
```

### 3.2 Deploying with Docker

```bash
cd server
docker build -t launchpad-backend .
docker run -p 3000:3000 --env-file .env launchpad-backend
```

### 3.3 Other Cloud Options

You can also deploy to services like:
- Google Cloud Run
- AWS Elastic Beanstalk
- Digital Ocean App Platform

## Step 4: Prepare Assets

### 4.1 Add Font Files

Download the required font files and place them in the `assets/fonts` directory:
- SF Pro Display: [Apple Fonts](https://developer.apple.com/fonts/)
- Noto Sans JP: [Google Fonts](https://fonts.google.com/specimen/Noto+Sans+JP)

### 4.2 Add Legal Documents

Copy the privacy policy and terms of service to the appropriate asset directories:
- `assets/legal/privacy_policy.md`
- `assets/legal/terms_of_service.md`

## Step 5: Build and Deploy Mobile App

### 5.1 Pre-build Checklist

- Verify app version in `pubspec.yaml`
- Ensure all dependencies are up to date
- Run tests to ensure everything works correctly

### 5.2 iOS Deployment

1. Configure signing in Xcode:
   ```bash
   cd ios
   pod install
   open Runner.xcworkspace
   ```
   Configure signing in Xcode using your Apple Developer account

2. Build the iOS release:
   ```bash
   flutter build ipa
   ```

3. Upload to App Store Connect:
   ```bash
   xcrun altool --upload-app --file build/ios/ipa/LaunchPad\ Notebook.ipa --type ios --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
   ```

4. Complete the App Store Connect setup:
   - Add screenshots
   - Fill in app information
   - Configure in-app purchases
   - Submit for review

### 5.3 Android Deployment

1. Prepare signing configuration:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Configure signing in `android/app/build.gradle`

3. Build the Android release:
   ```bash
   flutter build appbundle
   ```

4. Upload to Google Play Console:
   - Access the Google Play Console
   - Create a new application
   - Upload the AAB file from `build/app/outputs/bundle/release/app-release.aab`
   - Add store listing details (screenshots, descriptions)
   - Configure in-app purchases
   - Submit for review

## Step 6: Post-Deployment Tasks

### 6.1 Monitor Analytics

Set up analytics to monitor app usage:
- Firebase Analytics for user behavior
- Sentry for error tracking
- RevenueCat dashboard for subscription metrics

### 6.2 Implement CI/CD

Set up continuous integration and deployment:

```yaml
# .github/workflows/ci.yml
name: CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

### 6.3 Regular Maintenance

Establish a maintenance schedule:
- Weekly code updates
- Monthly dependency updates
- Quarterly security reviews

## Step 7: Custom Domain Setup (Optional)

### 7.1 Backend Custom Domain

1. Register a domain (e.g., `api.launchpad-notebook.com`)
2. Configure DNS for your hosting provider
3. Set up SSL certificates

### 7.2 Update App Configuration

Update the backend URL in the app to use your custom domain:

```dart
// lib/utils/constants.dart
static const String backendUrl = 'https://api.launchpad-notebook.com';
```

## Step 8: Scaling Considerations

### 8.1 Database Scaling

As your user base grows:
- Enable Supabase database read replicas
- Implement database caching
- Set up periodic database maintenance

### 8.2 Backend Scaling

Options for scaling the backend proxy server:
- Implement load balancing
- Set up auto-scaling
- Use a CDN for static content

### 8.3 API Usage Limits

Monitor and manage API usage:
- Implement stricter rate limiting
- Add usage quotas by subscription tier
- Consider implementing a token bucket algorithm

## Troubleshooting

### Common Issues and Solutions

1. **Authentication Issues**
   - Verify Supabase URL and anon key
   - Check RLS policies
   - Ensure user session is properly managed

2. **Push Notification Problems**
   - Verify FCM configuration
   - Check device token registration
   - Test with Firebase console

3. **In-App Purchase Issues**
   - Verify RevenueCat API keys
   - Test with sandbox accounts
   - Check product IDs match across platforms

4. **Backend Connection Errors**
   - Verify backend URL
   - Check network permissions in app
   - Ensure CORS is properly configured on backend

## Security Best Practices

1. **API Key Protection**
   - Never commit API keys to version control
   - Use environment variables
   - Implement key rotation policies

2. **Data Security**
   - Encrypt sensitive data at rest
   - Use HTTPS for all API calls
   - Implement proper authentication and authorization

3. **Compliance**
   - Maintain GDPR compliance
   - Update privacy policy when needed
   - Conduct regular security audits

## Conclusion

This deployment guide covers the essential steps to launch the LaunchPad Notebook application. The process requires careful configuration of multiple services, but once properly set up, provides a robust and scalable solution for users.

Remember to monitor the application after deployment and address any issues promptly. Regular updates and maintenance will ensure the app continues to function smoothly and securely.

For any questions or issues, please contact the development team at support@launchpad-notebook.com.

Happy launching! 🚀