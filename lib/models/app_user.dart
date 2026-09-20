import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher, admin }

enum AccountStatus { pendingVerification, verified, suspended }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final AccountStatus status;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.status,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      photoUrl: d['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => UserRole.student,
      ),
      status: switch (d['status']) {
        'verified' => AccountStatus.verified,
        'suspended' => AccountStatus.suspended,
        _ => AccountStatus.pendingVerification,
      },
    );
  }
}
