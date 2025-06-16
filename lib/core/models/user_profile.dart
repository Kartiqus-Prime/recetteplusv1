class UserProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final bool phoneVerified;
  final bool? isAdmin;
  final List<String> favorites;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.phoneVerified = false,
    this.isAdmin,
    this.favorites = const [],
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      displayName: json['display_name'],
      phone: json['phone'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      phoneVerified: json['phone_verified'] ?? false,
      isAdmin: json['is_admin'],
      favorites: List<String>.from(json['favorites'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'phone': phone,
      'bio': bio,
      'avatar_url': avatarUrl,
      'phone_verified': phoneVerified,
      'is_admin': isAdmin,
      'favorites': favorites,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? bio,
    String? avatarUrl,
    bool? phoneVerified,
    bool? isAdmin,
    List<String>? favorites,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      favorites: favorites ?? this.favorites,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
