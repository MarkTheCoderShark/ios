# 🍎 AI Todo App - MacBook Setup Guide

## Quick Start (5 minutes to running app!)

### 1. Prerequisites
```bash
# Check macOS version (need 13.0+)
sw_vers

# Install Xcode from App Store (or use Xcode Command Line Tools)
xcode-select --install
```

### 2. Transfer Project to MacBook
```bash
# Copy the entire /ios folder to your MacBook
# You can use AirDrop, USB, or GitHub

# On MacBook, navigate to the project
cd ~/Downloads/ios  # or wherever you put it
```

### 3. Open in Xcode
```bash
# Open the project
open AITodoApp.xcodeproj

# Or from Xcode: File → Open → Select AITodoApp.xcodeproj
```

### 4. Configure Dependencies
The project uses Swift Package Manager - dependencies auto-resolve:
- In Xcode: File → Packages → Resolve Package Versions
- Wait for packages to download (2-3 minutes)

### 5. Set Up API Keys (Optional for initial testing)
Create `Config.xcconfig` in project root:
```
GOOGLE_CLIENT_ID = your_google_client_id_here
OPENAI_API_KEY = your_openai_api_key_here
```

### 6. Run the App
1. Select **iPhone 15 Pro Simulator** from device dropdown
2. Press **⌘+R** or click ▶️ Play button
3. App will build and launch in simulator!

## 📱 Testing Options

### Option A: iOS Simulator (Immediate)
- ✅ No setup required
- ✅ Test all features except notifications
- ✅ Perfect for development

### Option B: Physical iPhone/iPad
1. Connect device via USB
2. In Xcode: Window → Devices and Simulators
3. Trust device and enable Developer Mode
4. Select your device and run

### Option C: Create .ipa for BrowserStack
```bash
# In Xcode:
# 1. Product → Archive
# 2. Distribute App → Development
# 3. Export as .ipa file
# 4. Upload to BrowserStack App Live
```

## 🔧 Troubleshooting

### "No Team Selected" Error
1. Xcode → Preferences → Accounts
2. Add your Apple ID
3. Project Settings → Signing & Capabilities
4. Select your team

### Dependencies Not Loading
```bash
# Reset package caches
# In Xcode: File → Packages → Reset Package Caches
```

### Simulator Issues
```bash
# Reset simulator
# Device → Erase All Content and Settings
```

## 🚀 Next Steps

### For App Store Release
1. **Apple Developer Account** ($99/year)
2. **App Store Connect** setup
3. **TestFlight** for beta testing
4. **App Store Review** submission

### For Immediate Testing
1. Run in simulator ✅
2. Test core features ✅
3. Build .ipa for BrowserStack ✅
4. Share with team/stakeholders ✅

## 📋 Features You Can Test Immediately

✅ **Home Dashboard** - AI brief, top tasks, inbox
✅ **Task Management** - Create, edit, complete tasks
✅ **Communications** - Notes, messaging interface
✅ **AI Assistant** - Chat interface (needs API key)
✅ **Settings** - All preference screens
✅ **Onboarding** - Full sign-up flow

*Note: Real-time messaging and Gmail integration need backend services*

## 🎯 Ready to Run!

The app is fully functional for local testing. All UI components work, and you can see the complete user experience. Just open in Xcode and hit run!