class PostModel {
  final String id; // Post ID from Firestore
  final String uid; // User ID who posted
  final String userName;
  final String role;
  final String teachSkill;
  final String learnSkill;
  final String description; // Additional post details
  final String timePosted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int expiryDays; // How many days post is valid (0 = no expiry)
  final bool isExpired; // If post has expired

  PostModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.role,
    required this.teachSkill,
    required this.learnSkill,
    required this.description,
    required this.timePosted,
    required this.createdAt,
    this.updatedAt,
    this.expiryDays = 0, // 0 means no expiry by default
    this.isExpired = false,
  });

  // Check if post has expired
  bool checkIfExpired() {
    if (expiryDays == 0) return false; // No expiry
    final now = DateTime.now();
    final expiryDate = createdAt.add(Duration(days: expiryDays));
    return now.isAfter(expiryDate);
  }

  // Convert PostModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'userName': userName,
      'role': role,
      'teachSkill': teachSkill,
      'learnSkill': learnSkill,
      'description': description,
      'timePosted': timePosted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'expiryDays': expiryDays,
    };
  }

  // Create PostModel from Firestore JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now();
    final expiryDays = json['expiryDays'] ?? 0;
    final isExpiredNow =
        expiryDays > 0 &&
        DateTime.now().isAfter(createdAt.add(Duration(days: expiryDays)));

    return PostModel(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      userName: json['userName'] ?? '',
      role: json['role'] ?? '',
      teachSkill: json['teachSkill'] ?? '',
      learnSkill: json['learnSkill'] ?? '',
      description: json['description'] ?? '',
      timePosted: json['timePosted'] ?? '',
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as dynamic).toDate()
          : null,
      expiryDays: expiryDays,
      isExpired: isExpiredNow,
    );
  }

  // Create a copy with updated fields
  PostModel copyWith({
    String? id,
    String? uid,
    String? userName,
    String? role,
    String? teachSkill,
    String? learnSkill,
    String? description,
    String? timePosted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expiryDays,
    bool? isExpired,
  }) {
    return PostModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      teachSkill: teachSkill ?? this.teachSkill,
      learnSkill: learnSkill ?? this.learnSkill,
      description: description ?? this.description,
      timePosted: timePosted ?? this.timePosted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDays: expiryDays ?? this.expiryDays,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}
