# Authentication Testing Guide

## 📋 Overview
This guide walks you through testing the authentication fixes implemented to resolve signup and Google Sign-in issues.

---

## ✅ Authentication Fixes Applied

### 1. Email Domain Fix
- **Issue**: Domain mismatch between signup and auth service
- **Before**: `@vitapstudents.ac.in` (wrong)
- **After**: `@vitapstudent.ac.in` (correct)
- **File**: `lib/features/auth/screens/signup_screen.dart`

### 2. Google Sign-in Enhancement
- **Issue**: Incomplete scopes and missing error handling
- **Fixes**:
  - Added scopes: `['email', 'profile']`
  - Sign-out before sign-in (allows account selection)
  - Better error messages
  - Auto-creation of user profile on login
- **File**: `lib/features/auth/services/auth_service.dart`

### 3. User Profile Creation
- **Issue**: Profile not created on Google Sign-in
- **Fix**: Implemented auto-profile creation in `_handleGoogleSignIn()`
- **File**: `lib/features/auth/screens/login_screen.dart`

---

## 🧪 Testing Procedure

### Test 1: Email Signup with College Email

#### Steps:
1. Open the app (currently running on Chrome)
2. Navigate to **Sign Up** screen
3. Enter your full college email: `sritheshwar.22mis7075@vitapstudent.ac.in`
4. Enter a strong password (8+ characters, mixed case, numbers)
5. Confirm password
6. Click **Sign Up** button

#### Expected Results:
- ✅ Email validation passes (domain check works)
- ✅ Account created in Firebase Authentication
- ✅ User profile created in Firestore
- ✅ Redirects to Home screen
- ✅ User can see "Discover Skills" page
- ✅ Bottom navigation shows Discover, Add (+), Profile

#### Validation Points:
- Check Firebase Console → Authentication → Users (should see the new email)
- Check Firestore → `users` collection (should see user document with profile data)

---

### Test 2: Email Login

#### Steps:
1. From Home screen, logout (if logged in)
2. Navigate to **Login** screen
3. Enter your college email: `sritheshwar.22mis7075@vitapstudent.ac.in`
4. Enter password
5. Click **Sign In** button

#### Expected Results:
- ✅ Login succeeds with correct credentials
- ✅ Redirects to Home screen
- ✅ Discover page loads with skill posts
- ✅ User data persists

#### Validation Points:
- Check console for any authentication errors
- Verify profile data matches signup

---

### Test 3: Google Sign-in

#### Steps:
1. From **Login** screen, click **Google Sign-in** button
2. A Google OAuth dialog appears (or opens in popup)
3. Select your college Google account
4. Grant permissions when prompted
5. Allow email and profile access

#### Expected Results:
- ✅ Google OAuth dialog appears smoothly
- ✅ User account selection works
- ✅ Permissions dialog shows email + profile scopes
- ✅ Account connects successfully
- ✅ Redirects to Home screen
- ✅ User profile auto-created in Firestore
- ✅ User can see all features

#### Validation Points:
- Check browser console (F12) for any errors
- Verify Firestore has user document with Google profile data
- Check username, profile picture, and email in profile screen

---

### Test 4: Error Handling

#### Test 4a: Invalid Email Domain
1. On **Sign Up**, try email: `student@gmail.com`
2. Should show error message

#### Expected:
- ✅ Shows "Please use your college email"
- ✅ Prevents signup

#### Test 4b: Weak Password
1. On **Sign Up**, try password: `123`
2. Should show error message

#### Expected:
- ✅ Shows password requirement error
- ✅ Prevents signup

#### Test 4c: Account Already Exists
1. Try signing up with same email twice
2. Should show error message

#### Expected:
- ✅ Shows "Email already in use"
- ✅ Suggests login instead

#### Test 4d: Wrong Password on Login
1. Enter correct email but wrong password
2. Should show error

#### Expected:
- ✅ Shows "Invalid password"
- ✅ Doesn't crash app

---

## 🔍 Verification Points

### Firebase Authentication Console
Go to: https://console.firebase.google.com

1. Select your project
2. Go to **Authentication** → **Users**
3. You should see:
   - Email-based users (from signup/login)
   - Google OAuth users (from Google Sign-in)
   - Each with provider info and signup date

### Firestore Database Console
1. Go to **Firestore Database**
2. Check `users` collection
3. Each user document should have:
   ```json
   {
     "email": "user@vitapstudent.ac.in",
     "username": "user",
     "role": "Student",
     "createdAt": timestamp,
     "provider": "email" or "google"
   }
   ```

### Browser Console (F12)
1. Open **Chrome DevTools** (F12)
2. Go to **Console** tab
3. Check for authentication-related logs
4. Should see:
   - No authentication errors
   - Successful user creation messages
   - Profile load confirmations

---

## 🎯 Testing Scenarios

### Scenario 1: New User Flow
1. Sign up with email
2. Verify user created
3. Login again with same email
4. Verify profile loads

### Scenario 2: Google User Flow
1. Google Sign-in
2. Accept permissions
3. Verify profile auto-created
4. Logout and login again with Google

### Scenario 3: Cross-Provider Testing
1. Sign up with email
2. Try Google Sign-in with same email
3. Should link accounts or handle gracefully

### Scenario 4: Network Testing
1. Test signup with slow network
2. Test Google Sign-in with slow network
3. Verify error messages appear
4. Verify no crashes occur

---

## 📊 Test Results Template

```
Test Date: _______________
Tester: ___________________

Email Signup:        [ ] Pass  [ ] Fail
Email Login:         [ ] Pass  [ ] Fail
Google Sign-in:      [ ] Pass  [ ] Fail
Email Validation:    [ ] Pass  [ ] Fail
Error Handling:      [ ] Pass  [ ] Fail
Profile Creation:    [ ] Pass  [ ] Fail
Database Sync:       [ ] Pass  [ ] Fail

Issues Found:
_________________________________
_________________________________

Notes:
_________________________________
_________________________________
```

---

## 🚨 Troubleshooting

### Issue: Email signup not working
**Possible Causes:**
- Email domain incorrect
- Firebase Auth not properly initialized
- Email already registered

**Solution:**
1. Check email is exactly: `xxx@vitapstudent.ac.in`
2. Verify Firebase credentials in `firebase_options.dart`
3. Check Firebase Console for email registration errors

### Issue: Google Sign-in button does nothing
**Possible Causes:**
- Google OAuth not configured
- Scopes missing
- Browser blocking popups

**Solution:**
1. Check Firebase Console → Google Sign-in enabled
2. Verify `google_sign_in` package installed
3. Allow popups in Chrome (click allow on popup)

### Issue: Profile not showing after login
**Possible Causes:**
- Firestore rules blocking access
- Profile document not created
- User document structure different

**Solution:**
1. Check Firestore Security Rules
2. Verify user collection exists
3. Check profile data in Firestore console

### Issue: Error messages not showing
**Possible Causes:**
- Error handling not triggering
- UI not updating with error state

**Solution:**
1. Check browser console for actual errors (F12)
2. Look for Firebase error codes
3. Verify error state UI is implemented

---

## ✨ Success Criteria

After testing, the app should meet these criteria:

- ✅ Users can sign up with college email
- ✅ Users can login with email/password
- ✅ Users can login with Google account
- ✅ Profiles auto-create in Firestore
- ✅ No crashes on authentication actions
- ✅ Clear error messages on failures
- ✅ Smooth transitions between screens
- ✅ Data persists after logout/login
- ✅ All UI renders with new fonts and animations
- ✅ App ready for production deployment

---

## 📞 Support

If you encounter any issues:

1. **Check Console Logs**: F12 → Console for detailed errors
2. **Review Firebase Console**: Check Authentication and Firestore
3. **Verify Credentials**: Ensure `firebase_options.dart` is correct
4. **Check Network**: Ensure internet connection is stable
5. **Clear Cache**: Try `flutter clean && flutter pub get`

---

## ✅ Sign-off

Once all tests pass and the app meets success criteria, authentication is ready for production deployment! 🚀
