# 🚀 SkillSwap: The Future of Peer-to-Peer Learning

Welcome to **SkillSwap** — a next-generation skill exchange platform designed exclusively for college students. Share your expertise, discover new skills to learn, and collaborate seamlessly through our hyper-focused, swap-based messaging ecosystem.

Built for the modern web and beyond. Powered by a robust **Flutter & Firebase** architecture, supporting *Web, Android, iOS, macOS, Windows, and Linux*.

---

## ✨ Futuristic Features

### 🔐 Secure Identity
- **Smart Authentication**: Restricted `@vitapstudent.ac.in` domain sign-ups to keep the community safe.
- **One-Tap OAuth**: Effortless Google Sign-In with strict domain validation.

### 🔍 Intelligent Discovery
- **Dynamic Browsing & Search**: Find the exact skills you're looking for.
- **Smart Visibility Control**: Accepted posts automatically vanish from the discovery feed to keep focus.

### 🤝 Seamless Swap Workflow
- **Real-Time Swap Tracking**: Monitor requests in `Pending`, `Accepted`, or `Rejected` states.
- **Centralized Command Center**: The "My Swaps" dashboard manages both incoming requests and active learning sessions.

### 💬 Contextual Messaging
- **Swap-Scoped Channels**: Every accepted swap generates a dedicated, isolated chat environment.
- **Precision Unread Tracking**: Per-user read states for ultimate communication clarity.

### 👤 Modern Profiles & UI
- **Fluid Bio & Identity**: Express yourself with personalized bios and circular avatar rendering.
- **Adaptive UI**: Stunning **Material 3 Design** fully equipped with fluid Light & Dark modes.

---

## 🛠️ Cutting-Edge Stack

- **Frontend**: Flutter (Dart) — Write once, deploy everywhere.
- **Backend & Auth**: Firebase Authentication & Cloud Firestore
- **Hosting**: Firebase Hosting (World-class CDN delivery)
- **State Management**: Provider (Reactive & Scalable)

---

## 🚀 Getting Started

### Prerequisites
- Latest [Flutter SDK](https://flutter.dev/docs/get-started/install) 
- [Firebase CLI](https://firebase.google.com/docs/cli) (`firebase --version`)

### Ignite Local Development
```bash
flutter pub get
flutter run -d chrome
```
*Targeting another platform? Easy:*
```bash
flutter run -d android  # Or ios, macos, windows, linux
```

### Deploy to the Cloud (Web)
```bash
flutter build web --release
firebase deploy --only hosting
```

---

## ⚙️ Configuration Matrix

Firebase settings are pre-integrated into our repo:
- **Global**: `lib/firebase_options.dart`
- **Web**: `firebase.json`
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`

---

## 📂 Architecture Mapping

```text
lib/
├── main.dart                 # Application entry point
├── firebase_options.dart     # Firebase generated configs
├── core/                     # Foundational systems (Theme, Animations, Formatter)
├── features/                 # Modular, feature-first architecture
│   ├── auth/                 # Secure identity & access
│   ├── home/                 # Main dashboards & dynamic feed
│   ├── messaging/            # Real-time chat & socket handling
│   ├── profile/              # User identity management
│   ├── skill_details/        # Deep-dives into individual skills
│   └── swaps/                # Stateful swap lifecycle management
└── utils/                    # Shared tools & helpers
```

---

## 🧠 Core System Flows

1. **Identity Phase**: User authenticates (Email/Google) → Firestore spins up a secure profile instance.
2. **Publishing**: User launches a skill post → System indexes it into the Discover/Search matrix.
3. **Connection**: Peer initiates a Swap Request → Bi-directional status monitors activate.
4. **Engagement**: Request Accepted → Dedicated, secure chat channel unlocks.
5. **Focus Mode**: First message transmitted → Original post enters stealth mode (removed from Discover).

---

<div align="center">
  <i>Conceptualized, Designed, and Engineered by <b>Srithesh</b></i> 🚀
</div>
