class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final bool emailVerified;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.createdAt,
    required this.emailVerified,
  });

  factory AppUser.fromFirebaseUser(dynamic user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      createdAt: user.metadata.creationTime,
      emailVerified: user.emailVerified,
    );
  }
}