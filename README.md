# AI Todo App - iOS Development Setup

## Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 17.0+ target device or simulator

## Quick Start

### 1. Open in Xcode
```bash
cd /path/to/ios
open AITodoApp.xcodeproj
```

### 2. Install Dependencies
The app uses Swift Package Manager. Dependencies will auto-resolve when you build:
- GoogleSignIn-iOS
- Firebase SDK
- SocketIO
- Alamofire
- Kingfisher

### 3. Configure API Keys

Create a `Config.xcconfig` file in the project root:
```
// Config.xcconfig
GOOGLE_CLIENT_ID = your_google_client_id_here
OPENAI_API_KEY = your_openai_api_key_here
FIREBASE_CONFIG = your_firebase_config_here
```

### 4. Run the App
1. Select a simulator or connected device
2. Press Cmd+R or click the Play button
3. The app will build and launch

## Project Structure
```
AITodoApp/
├── Sources/
│   ├── App/              # Main app entry point
│   ├── Models/           # Core Data models
│   ├── Views/            # SwiftUI views
│   ├── Services/         # Business logic
│   └── Utils/            # Utilities and extensions
├── Resources/            # Assets and data models
└── Supporting Files/     # Info.plist, etc.
```

## Features Implemented
✅ Complete tab bar navigation
✅ Task management with CRUD operations
✅ Real-time messaging system
✅ AI-powered assistant
✅ Gmail integration
✅ Push notifications
✅ User authentication (Apple/Google)
✅ Onboarding flow
✅ Settings and preferences

## Development Notes

### Core Data
The app uses Core Data for local persistence. The data model includes:
- User, Task, Project, Conversation, Message entities
- Proper relationships and constraints
- Migration support

### Real-time Features
- WebSocket connection for messaging
- Live updates across all views
- Optimistic UI updates

### AI Integration
- OpenAI GPT integration for assistance
- Email summarization
- Task extraction from conversations
- Daily brief generation

## Testing
Run tests in Xcode:
```bash
Cmd+U
```

## Troubleshooting

### Build Issues
1. Clean build folder: Product → Clean Build Folder
2. Reset package caches: File → Packages → Reset Package Caches
3. Check signing certificates in project settings

### Simulator Issues
1. Reset simulator: Device → Erase All Content and Settings
2. Restart Xcode
3. Check iOS version compatibility

## Next Steps
1. Add your API keys
2. Test on device/simulator
3. Customize branding and colors
4. Deploy to TestFlight for beta testing