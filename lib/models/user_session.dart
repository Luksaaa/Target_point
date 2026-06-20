class UserSession {
  const UserSession({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarColorValue,
    required this.isGuest,
    this.photoUrl,
  });

  final String id;
  final String displayName;
  final String? email;
  final int avatarColorValue;
  final bool isGuest;
  final String? photoUrl;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return isGuest ? 'G' : 'U';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  UserSession copyWith({
    String? id,
    String? displayName,
    String? email,
    int? avatarColorValue,
    bool? isGuest,
    String? photoUrl,
  }) {
    return UserSession(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      isGuest: isGuest ?? this.isGuest,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class FollowedUser {
  const FollowedUser({
    required this.id,
    required this.displayName,
    required this.handle,
    this.email,
  });

  final String id;
  final String displayName;
  final String handle;
  final String? email;
}
