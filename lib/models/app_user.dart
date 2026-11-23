class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'user' | 'admin'

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'user',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: (map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: (map['displayName'] ?? map['email'] ?? 'User').toString(),
      role: (map['role'] ?? 'user').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
      };

  bool get isAdmin => role == 'admin';
}
