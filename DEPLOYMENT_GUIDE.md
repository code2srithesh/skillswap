# Deployment Guide - Security Rules

## Quick Deploy (Security Rules Only)

```bash
cd /Users/srithesh/skillswap
firebase deploy --only firestore:rules
```

## Verify Deployment

1. **Check Firebase Console**:
   - Go to: https://console.firebase.google.com
   - Select project: "skillswap-26"
   - Navigate to: Firestore → Rules tab
   - Verify timestamp shows recent deployment

2. **Test Privacy**:
   - User A logs in and sends message to User B
   - Try to access that message from User B's account
   - Should work ✓
   - Try to access User B's message as User C (not participant)
   - Should fail ✗ with "Permission denied"

## Full Deployment (If updating app code)

```bash
# 1. Update rules
firebase deploy --only firestore:rules

# 2. Build and deploy web
flutter build web --release
firebase deploy --only hosting

# 3. Rebuild Android
flutter build apk --release

# 4. Rebuild iOS
flutter build ios --release
```

## Rollback (If needed)

```bash
# The previous rules are stored in Firebase
# You can manually revert via Firebase Console:
# - Firestore → Rules → Revisions
# - Select previous version → Publish
```
