# SkillSwap

SkillSwap is a peer-to-peer skill exchange platform for college students. Users post what they can teach and what they want to learn, send swap requests, and once a swap is accepted they can chat inside a swap-scoped conversation.

This repo contains a Flutter + Firebase app (Auth + Firestore + Hosting) and supports Web, Android, iOS, macOS, Windows, and Linux.

## Key features

- Authentication
	- Email sign-up/sign-in restricted to `@vitapstudent.ac.in`
	- Google Sign-In (OAuth) with domain validation
- Discover + Search
	- Browse and search skill posts
	- Posts can become hidden from discover after an accepted chat starts (business rule)
- Swap workflow
	- Swap requests show status: `pending` / `accepted` / `rejected`
	- “My Swaps” screen to manage incoming + active swaps
- Messaging
	- Chat is swap-scoped (conversation is tied to a specific request)
	- Chat becomes available after the swap is accepted
	- Per-user unread tracking on conversations
- Profiles
	- Bio + username display
	- Modern avatar picker (circular avatar rendering)
- UI
	- Material 3 design
	- Light/Dark mode

## Tech stack

- Flutter (Dart)
- Firebase Auth
- Cloud Firestore
- Firebase Hosting (web)
- Provider (state management)

## Requirements

- Flutter SDK installed
- For deployment: Firebase CLI (`firebase --version`)

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

To run on another platform:

```bash
flutter run -d android
# or: ios / macos / windows / linux
```

## Firebase configuration

Firebase options are checked into the repo in `lib/firebase_options.dart`.

Firebase project configuration files:
- Web hosting config: `firebase.json`
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Deploy (web)

```bash
flutter build web --release
firebase deploy --only hosting
```

## Folder structure (high level)

```
lib/
	main.dart
	firebase_options.dart
	core/
		theme.dart
		theme_provider.dart
		animations.dart
		time_formatter.dart
	features/
		auth/
			screens/
			services/
		home/
			models/
			screens/
			services/
			widgets/
		messaging/
			screens/
			services/
		profile/
			screens/
		skill_details/
			screens/
		swaps/
			screens/
test/
	widget_test.dart
```

## Core flows (how the app works)

1) User signs in (email or Google) → profile is available in Firestore.

2) User creates a post → it appears in Discover/Search (unless hidden by business rules).

3) Another user sends a swap request → requester/owner can see status updates.

4) When a request is accepted → chat becomes available for that swap.

5) First message in an accepted swap can mark the related post as not discoverable (so it disappears from Discover).

## Notes

- This repository intentionally keeps documentation in a single file (this `README.md`).

Status: production-ready
