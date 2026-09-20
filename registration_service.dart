import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DuplicateIdentityException implements Exception {
  @override
  String toString() =>
      'A student with this college, session, course, semester, section and '
      'roll number is already registered. Check your details or contact your teacher.';
}

class RegistrationService {
  static final _db = FirebaseFirestore.instance;

  static String identityKey({
    required String collegeId,
    required String session,
    required String courseId,
    required int semester,
    required String section,
    required String rollNo,
  }) =>
      [collegeId, session, courseId, 'sem$semester', section.toUpperCase(), rollNo.toUpperCase()]
          .join('_');

  /// Creates the user + student profile, and claims the academic identity
  /// atomically so two accounts can never share one identity.
  static Future<void> registerStudent({
    required User user,
    required String collegeId,
    required String courseId,
    required String session,
    required int semester,
    required String section,
    required String rollNo,
  }) async {
    final key = identityKey(
      collegeId: collegeId, session: session, courseId: courseId,
      semester: semester, section: section, rollNo: rollNo,
    );
    final identityRef = _db.collection('academicIdentities').doc(key);
    final userRef = _db.collection('users').doc(user.uid);
    final profileRef = _db.collection('studentProfiles').doc(user.uid);

    await _db.runTransaction((tx) async {
      if ((await tx.get(identityRef)).exists) throw DuplicateIdentityException();
      tx.set(identityRef, {'uid': user.uid, 'createdAt': FieldValue.serverTimestamp()});
      tx.set(userRef, _baseUser(user, 'student'));
      tx.set(profileRef, {
        'uid': user.uid,
        'collegeId': collegeId,
        'courseId': courseId,
        'session': session,
        'semester': semester,
        'section': section.toUpperCase(),
        'rollNo': rollNo.toUpperCase(),
        'identityKey': key,
      });
    });
  }

  static Future<void> registerTeacher({
    required User user,
    required String collegeId,
    required String department,
    required String designation,
    required String session,
  }) async {
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(user.uid), _baseUser(user, 'teacher'));
    batch.set(_db.collection('teacherProfiles').doc(user.uid), {
      'uid': user.uid,
      'collegeId': collegeId,
      'department': department,
      'designation': designation,
      'session': session,
    });
    await batch.commit();
  }

  static Map<String, dynamic> _baseUser(User user, String role) => {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'role': role,
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
      };
}
