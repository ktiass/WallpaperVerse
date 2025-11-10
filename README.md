# WallpaperVerse

A cross-platform Flutter app for purchasing and generating AI-powered wallpapers with Firebase backend.

## Features

- 🎨 **Browse & Purchase** - Discover premium wallpapers across various categories
- 🤖 **AI Generation** - Create custom wallpapers using AI (Stability AI / OpenAI DALL-E)
- 💳 **In-App Purchases** - Credit packs and subscriptions via App Store / Google Play
- 🔐 **Secure Payments** - Server-side receipt validation and credit management
- 🖼️ **Watermarked Previews** - Full previews with watermarks until purchase
- 📱 **Cross-Platform** - iOS and Android support
- 🎯 **Modern UI** - AMOLED-friendly dark theme with smooth animations

## Tech Stack

### Frontend
- **Flutter** (Dart)
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Freezed** - Immutable data models
- **Cached Network Image** - Image caching

### Backend
- **Firebase Authentication** - Sign in with Apple, Google, Email
- **Cloud Firestore** - Database
- **Cloud Storage** - Image storage
- **Cloud Functions** - Serverless backend (Node 20 / TypeScript)
- **Firebase Analytics** - Usage tracking
- **Firebase Crashlytics** - Error reporting
- **Firebase App Check** - Security

### Payments
- **in_app_purchase** - Flutter IAP package
- Server-side receipt validation (App Store & Google Play)

### AI Providers
- Stability AI (Stable Diffusion XL)
- OpenAI (DALL-E 3)
- Switchable via environment config

## Project Structure

```
lib/
├── config/              # App configuration
│   ├── constants.dart
│   └── firebase_options.dart
├── features/            # Feature modules
│   ├── auth/           # Authentication
│   ├── home/           # Home/Browse
│   ├── detail/         # Wallpaper details
│   ├── generator/      # AI generation
│   ├── library/        # User library
│   └── profile/        # User profile & purchases
├── models/             # Data models
│   ├── user_model.dart
│   ├── wallpaper_model.dart
│   ├── generation_model.dart
│   ├── ownership_model.dart
│   └── receipt_model.dart
├── services/           # Business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   ├── functions_service.dart
│   ├── iap_service.dart
│   └── ai_provider.dart
├── widgets/            # Reusable widgets
├── router/             # Navigation
├── theme/              # App theming
└── utils/              # Utilities

functions/
├── src/
│   ├── index.ts
│   ├── validateReceipt.ts
│   ├── spendCredits.ts
│   ├── requestGeneration.ts
│   ├── unlockGenerated.ts
│   ├── purchaseWallpaper.ts
│   └── generationWorker.ts
└── package.json

scripts/
└── seed_data.js        # Sample data seeding
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.0+)
- Firebase CLI
- Node.js (20+)
- Firebase project
- Stability AI or OpenAI API key

### 1. Firebase Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Select:
# - Firestore
# - Functions
# - Storage
# - Emulators (optional)
```

### 2. Configure Firebase for Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This generates `lib/config/firebase_options.dart` with your project credentials.

### 3. Install Dependencies

```bash
# Flutter dependencies
flutter pub get

# Functions dependencies
cd functions
npm install
cd ..

# Scripts dependencies (optional)
cd scripts
npm install
cd ..
```

### 4. Configure Environment

#### Cloud Functions Configuration

```bash
# Set AI provider (stability or openai)
firebase functions:config:set ai.provider="stability"
firebase functions:config:set ai.api_key="YOUR_API_KEY"

# Set Apple shared secret for IAP (iOS)
firebase functions:config:set apple.shared_secret="YOUR_SHARED_SECRET"
```

### 5. Deploy Security Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

### 6. Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### 7. Seed Sample Data (Optional)

```bash
cd scripts

# Add your service account key as serviceAccountKey.json
# Download from Firebase Console > Project Settings > Service Accounts

npm run seed
```

### 8. Configure In-App Purchases

#### iOS (App Store Connect)

1. Create app in App Store Connect
2. Configure products:
   - `credits_5` - 5 Credits (Consumable)
   - `credits_20` - 20 Credits (Consumable)
   - `credits_100` - 100 Credits (Consumable)
   - `sub_monthly_plus` - Monthly Plus (Auto-Renewable Subscription)

3. Set up shared secret for receipt validation

#### Android (Google Play Console)

1. Create app in Google Play Console
2. Configure products with same IDs
3. Set up Google Play Developer API
4. Configure service account for receipt validation

### 9. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# With Firebase Emulators (for development)
firebase emulators:start
flutter run
```

## Product IDs

Configure these products in App Store Connect and Google Play Console:

| Product ID | Type | Credits | Price |
|------------|------|---------|-------|
| `credits_5` | Consumable | 5 | $0.99 |
| `credits_20` | Consumable | 20 | $2.99 |
| `credits_100` | Consumable | 100 | $9.99 |
| `sub_monthly_plus` | Subscription | 50/month | $4.99 |

## Credit Costs

| Action | Credits |
|--------|---------|
| Unlock Wallpaper | 1 |
| Generate 1:1 (1024x1024) | 1 |
| Generate 9:16 (1080x1920) | 1 |
| Generate 2:3 (1024x1536) | 2 |

## Data Model

### Firestore Collections

**users/{uid}**
```json
{
  "email": "user@example.com",
  "displayName": "User Name",
  "photoURL": "https://...",
  "credits": 100,
  "createdAt": "2024-01-01T00:00:00Z",
  "lastActiveAt": "2024-01-01T00:00:00Z",
  "plan": {
    "type": "monthly_plus",
    "renewalDate": "2024-02-01T00:00:00Z",
    "isActive": true
  }
}
```

**wallpapers/{wallpaperId}**
```json
{
  "title": "Mountain Sunset",
  "tags": ["mountain", "sunset", "nature"],
  "colors": ["orange", "purple"],
  "category": "Nature",
  "style": "realistic",
  "resolution": { "width": 1080, "height": 1920 },
  "storagePath": "public/wallpapers/.../full.jpg",
  "thumbnailPath": "public/wallpapers/.../thumb.jpg",
  "price": 1,
  "featured": true,
  "sales": 150,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**generations/{genId}**
```json
{
  "uid": "user123",
  "prompt": "A beautiful sunset...",
  "style": {
    "aspect": "9:16",
    "stylePreset": "realistic",
    "chromatic": 1.0
  },
  "status": "succeeded",
  "storagePath": "protected/users/.../full.jpg",
  "thumbnailPath": "protected/users/.../thumb.jpg",
  "creditCost": 2,
  "createdAt": "2024-01-01T00:00:00Z",
  "completedAt": "2024-01-01T00:01:00Z"
}
```

## Cloud Functions API

### Callable Functions

**validateReceipt**
```typescript
{
  raw: string,           // Receipt data
  platform: "ios" | "android"
}
→ { validated: boolean, creditsGranted: number }
```

**spendCredits**
```typescript
{
  amount: number,
  reason: "generation" | "unlock" | "download",
  refId?: string
}
→ { ok: boolean, authToken: string }
```

**requestGeneration**
```typescript
{
  prompt: string,
  aspect: "9:16" | "1:1" | "2:3",
  stylePreset?: string,
  chromatic?: number
}
→ { genId: string }
```

**unlockGenerated**
```typescript
{
  genId: string
}
→ { owned: boolean }
```

**purchaseWallpaper**
```typescript
{
  wallpaperId: string
}
→ { owned: boolean }
```

## Security

- ✅ Firebase App Check enforced for all client requests
- ✅ Firestore Security Rules prevent direct writes to sensitive data
- ✅ Credits managed server-side only
- ✅ Receipt validation server-side
- ✅ Watermarked previews until purchase
- ✅ User data isolated per UID
- ✅ HTTPS-only Cloud Functions

## Testing

```bash
# Run unit tests
flutter test

# Run with Firebase Emulators
firebase emulators:start
flutter run

# Test IAP with sandbox accounts
# iOS: TestFlight or Xcode simulator with sandbox account
# Android: Internal testing track with test accounts
```

## Deployment

### Flutter App

```bash
# iOS
flutter build ios --release
# Upload to App Store Connect via Xcode

# Android
flutter build appbundle --release
# Upload to Google Play Console
```

### Backend

```bash
# Deploy all
firebase deploy

# Deploy specific components
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## Environment Variables

Required Cloud Functions config:

```bash
ai.provider=stability              # or "openai"
ai.api_key=YOUR_API_KEY
apple.shared_secret=YOUR_SECRET    # For iOS IAP validation
```

## Troubleshooting

### IAP not working
- Verify products are configured in both stores
- Check bundle ID / package name matches
- Ensure app is signed with correct certificates
- Test with sandbox/test accounts

### AI generation failing
- Verify API key is set: `firebase functions:config:get`
- Check API provider quotas/limits
- Review Cloud Functions logs: `firebase functions:log`

### Images not loading
- Check Storage security rules
- Verify storage paths are correct
- Ensure App Check is configured

## License

This is a sample project for demonstration purposes.

## Support

For issues and questions:
- File issues on GitHub
- Check Firebase Console for errors
- Review Cloud Functions logs
