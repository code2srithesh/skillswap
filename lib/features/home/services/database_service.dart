import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Save User Profile (Run this after Sign Up)
  Future<void> createUserProfile(
    String uid,
    String email,
    String name,
    String role, {
    String? username,
  }) async {
    // Generate username if not provided
    String finalUsername = username ?? _generateUsername(name);

    // Check if username is unique, if not, make it unique
    int counter = 1;
    String uniqueUsername = finalUsername;
    while (await _isUsernameTaken(uniqueUsername)) {
      uniqueUsername = '${finalUsername}$counter';
      counter++;
    }

    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'username': uniqueUsername,
      'role': role, // e.g. "3rd Year CSE"
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Generate a username from name
  String _generateUsername(String name) {
    return name.toLowerCase().replaceAll(' ', '');
  }

  // Check if username is already taken
  Future<bool> _isUsernameTaken(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Check username availability
  Future<bool> isUsernameAvailable(String username) async {
    return !(await _isUsernameTaken(username));
  }

  // Update username
  Future<void> updateUsername(String uid, String newUsername) async {
    // Check if username is unique
    if (!(await isUsernameAvailable(newUsername))) {
      throw 'Username already taken';
    }

    await _db.collection('users').doc(uid).update({'username': newUsername});
  }

  // 2. Create a New Skill Request (Post) with optional expiry (MAX 7 DAYS)
  Future<String> createPost(
    String uid,
    String userName,
    String role,
    String teach,
    String learn,
    String description, {
    int expiryDays = 0, // 0 = no expiry, max 7 days
  }) async {
    // Cap expiry to maximum 7 days
    int validExpiryDays = expiryDays;
    if (expiryDays > 7) {
      validExpiryDays = 7;
    }

    final docRef = await _db.collection('posts').add({
      'uid': uid,
      'userName': userName,
      'role': role,
      'teachSkill': teach,
      'learnSkill': learn,
      'description': description,
      'expiryDays': validExpiryDays,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDiscoverable': true, // Hide from Discover when swap chat starts
      'isSwapped': false, // Track if skills have been swapped
      'swappedWith': '', // UID of person swapped with
      'swappedAt': null, // When the swap happened
    });
    return docRef.id;
  }

  // Send a Swap Request
  Future<void> sendSwapRequest({
    required String receiverUid,
    required String senderName,
    required String message,
    required String skillOffered,
    required String postId,
    required String postOwnerName,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid;

    await _db.collection('requests').add({
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'senderName': senderName,
      'message': message,
      'skillOffered': skillOffered,

      // Helps querying active swaps without OR queries
      'participants': [senderUid, receiverUid],

      // New canonical fields (keep old ones above for compatibility)
      'requesterId': senderUid,
      'requesterName': senderName,
      'postOwnerId': receiverUid,
      'postOwnerName': postOwnerName,
      'postId': postId,

      'status': 'pending', // pending, accepted, rejected
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Get All Posts (Real-time Stream) - EXCLUDING USER'S OWN POSTS & SWAPPED POSTS & NON-VIT EMAILS
  Stream<List<PostModel>> getPosts() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db.collection('posts').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final postUid = data['uid'] ?? '';
            final isOwnPost = postUid == currentUid;

            // Get user email from the document or verify with auth
            final isSwapped = data['isSwapped'] ?? false;
            final isDiscoverable = data['isDiscoverable'] ?? true;

            // Exclude own posts, swapped posts
            return !isOwnPost && !isSwapped && isDiscoverable;
          })
          .map((doc) {
            final data = doc.data();
            return PostModel.fromJson({...data, 'id': doc.id});
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // 4. Get Current User's Posts
  Stream<List<PostModel>> getUserPosts(String uid) {
    return _db
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return PostModel.fromJson({...data, 'id': doc.id});
          }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // 5. Update a Post
  Future<void> updatePost(
    String postId,
    String teachSkill,
    String learnSkill,
    String description,
  ) async {
    await _db.collection('posts').doc(postId).update({
      'teachSkill': teachSkill,
      'learnSkill': learnSkill,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 6. Delete a Post
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // 7. Get a Single Post by ID
  Future<PostModel?> getPostById(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (doc.exists) {
      return PostModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    }
    return null;
  }

  // 8. Get All Pending Requests for a User
  Stream<List<Map<String, dynamic>>> getPendingRequests(String uid) {
    return _db
        .collection('requests')
        .where('receiverUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) => doc.data()).toList();
          requests.sort(
            (a, b) => (b['createdAt'] as Timestamp).compareTo(
              a['createdAt'] as Timestamp,
            ),
          );
          return requests;
        });
  }

  // 10. Get User Profile by UID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // 11. Get User's Posts count
  Future<int> getUserPostsCount(String uid) async {
    final snapshot = await _db
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // 9. Update Request Status (with swap tracking)
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? postId,
    String? counterPostId,
  }) async {
    final updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('requests').doc(requestId).update(updateData);

    // If accepted, mark both posts as swapped
    if (status == 'accepted' && postId != null && counterPostId != null) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final requestDoc = await _db.collection('requests').doc(requestId).get();
      final receiverUid = requestDoc['receiverUid'];

      await Future.wait([
        _db.collection('posts').doc(postId).update({
          'isSwapped': true,
          'swappedWith': receiverUid,
          'swappedAt': FieldValue.serverTimestamp(),
        }),
        _db.collection('posts').doc(counterPostId).update({
          'isSwapped': true,
          'swappedWith': currentUid,
          'swappedAt': FieldValue.serverTimestamp(),
        }),
      ]);
    }
  }
}
