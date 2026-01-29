# SkillSwap 🎓

A peer-to-peer skill exchange platform built for college students to teach and learn from each other. Built with Flutter & Firebase.

## ✨ Features

### Core Features
- 🔐 **College Email Authentication** - Only VIT students (@vitapstudent.ac.in) can join
- 🌐 **Google Sign-in** - Secure OAuth2 authentication with college email validation
- 📱 **Real-time Feed** - Live skill exchange requests from other students
- 🎯 **Skill Matching** - Find people teaching what you want to learn
- 💬 **Swap Requests** - Connect with peers and negotiate skill exchanges
- 👥 **Profile Management** - Customize your profile with avatar, bio, and skills

### Advanced Features
- 🌙 **Dark Mode & Light Mode** - Switch between themes instantly
- ✨ **Smooth Animations** - Professional micro-interactions & transitions
- 🎨 **Material 3 Design** - Modern, responsive UI
- 💾 **Real-time Sync** - Firestore database for instant updates
- 🔔 **Pending Requests** - Track incoming swap requests

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase |
| **Database** | Firestore (Real-time) |
| **Authentication** | Firebase Auth + Google OAuth2 |
| **State Management** | Provider |
| **Hosting** | Firebase Hosting |
| **Design System** | Material 3 |

## 🚀 Getting Started

### Prerequisites
- Flutter 3.10+
- Dart 3.0+
- Firebase CLI (for deployment)

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd skillswap

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

### Configuration
- Firebase is pre-configured with project ID: `skillswap-26`
- No additional setup needed for local development
- Google Sign-in is configured for web

## 📋 Usage

### For Students
1. **Sign up** with your college email (e.g., name@vitapstudent.ac.in)
2. **Post a skill request** - Share what you can teach and want to learn
3. **Browse the feed** - Find students with matching skills
4. **Send a request** - Connect with someone for a skill swap
5. **Complete the swap** - Learn and teach asynchronously or synchronously

### For Developers
- See [FEATURES_AND_DEPLOYMENT.md](./FEATURES_AND_DEPLOYMENT.md) for detailed guide
- Deployment steps for Firebase Hosting
- Mobile app building instructions
- Architecture documentation

## 🌐 Deployment

### Web Deployment (Recommended - FREE)

```bash
# Build for production
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**Live URL**: `https://skillswap-26.web.app`

### Mobile Deployment (Optional)

**Android**:
```bash
flutter build apk --release
# Upload to Google Play Store ($25)
```

**iOS**:
```bash
flutter build ipa --release
# Upload to App Store ($99/year)
```

## 📱 Screenshots

### Authentication
- Email/Password login
- Google Sign-in with college email validation
- Automatic profile creation

### Home Feed
- Real-time skill requests
- Smooth animations & transitions
- Dark mode support

### Profile
- Profile customization
- Theme toggle
- Credit tracking
- Pending requests

## 🎯 Key Highlights for Resume

✅ **Full-stack Flutter application**  
✅ **Firebase + Firestore real-time backend**  
✅ **OAuth2 Google authentication implementation**  
✅ **Dark mode & theme customization**  
✅ **Production-ready architecture**  
✅ **Cloud deployment (Firebase Hosting)**  
✅ **Responsive Material 3 UI**  
✅ **Provider state management**  
✅ **Email domain validation**  
✅ **Real-world problem solving**  

## 📚 Architecture

```
lib/
├── main.dart              # App entry point
├── core/
│   ├── theme.dart         # Material 3 themes (light/dark)
│   ├── theme_provider.dart # Theme state management
│   └── animations.dart    # Custom animations
├── features/
│   ├── auth/              # Authentication
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   └── services/auth_service.dart
│   ├── home/              # Main feed
│   │   ├── screens/
│   │   ├── models/post_model.dart
│   │   ├── widgets/skill_card.dart
│   │   └── services/database_service.dart
│   ├── profile/           # User profile
│   │   └── screens/
│   └── skill_details/     # Skill detail view
│       └── screens/
└── firebase_options.dart  # Firebase config
```

## 🔐 Security

- Email domain validation (@vitapstudent.ac.in only)
- Firestore security rules for data protection
- No sensitive data in client code
- Firebase Auth handles password security

## 🚧 Future Enhancements

- [ ] In-app messaging/chat
- [ ] Rating & review system
- [ ] Video call integration
- [ ] Calendar scheduling
- [ ] Notification system
- [ ] User verification/badges
- [ ] Payment integration (if needed)

## 📝 License

This project is open source and available under the MIT License.

## 👨‍💻 Author

Built as a portfolio project for demonstrating full-stack development skills.

## 📞 Support

For detailed deployment and feature information, see [FEATURES_AND_DEPLOYMENT.md](./FEATURES_AND_DEPLOYMENT.md)

---

**Status**: ✅ Production Ready  
**Last Updated**: January 29, 2026
