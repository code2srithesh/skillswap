// Firebase Firestore Batch Reset Script - Run ONCE in Firestore Console
// This script resets all existing user records that don't have postsCount/swapsCount fields
// Usage: Copy this code into a function in your Firebase Function OR run in Cloud Shell

// Firestore console script (run manually once):
/*
db.collection('users').get().then(snapshot => {
  let batch = db.batch();
  let count = 0;
  
  snapshot.forEach(doc => {
    // Only update documents that are missing the new fields
    if (doc.data().postsCount === undefined || doc.data().swapsCount === undefined) {
      batch.update(doc.ref, {
        'postsCount': 0,
        'swapsCount': 0,
      });
      count++;
    }
  });
  
  return batch.commit().then(() => {
    console.log(`Updated ${count} user documents`);
  });
}).catch(error => console.error('Error:', error));
*/

// Alternative: Add this as a Cloud Function triggered on demand or schedule
// (TypeScript example – kept here for reference only, not compiled as Dart)
/*
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const resetUserStats = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    // Check authentication (optional security)
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    // Only allow admin users (optional)
    // Get admin status from user doc if you have such a field
    // const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    // if (!userDoc.data()?.isAdmin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Only admins can run this');
    // }

    const batch = admin.firestore().batch();
    let updateCount = 0;

    try {
      const usersSnapshot = await admin
        .firestore()
        .collection('users')
        .get();

      usersSnapshot.forEach((doc) => {
        // Only update documents missing the new fields
        if (
          doc.data().postsCount === undefined ||
          doc.data().swapsCount === undefined
        ) {
          batch.update(doc.ref, {
            postsCount: 0,
            swapsCount: 0,
          });
          updateCount++;
        }
      });

      await batch.commit();

      return {
        success: true,
        message: `Reset ${updateCount} user documents`,
      };
    } catch (error) {
      console.error('Reset error:', error);
      throw new functions.https.HttpsError('internal', 'Reset failed');
    }
  });
*/

// To deploy: firebase deploy --only functions:resetUserStats
// To call from Flutter:
/*
final HttpsCallable resetFunction = FirebaseFunctions.instance.httpsCallable('resetUserStats');
try {
  final result = await resetFunction.call();
  print('Reset complete: ${result.data['message']}');
} catch (e) {
  print('Error: $e');
}
*/
