# Study Network (Phase 1: Foundation)

Flutter + Firebase. Includes Google sign-in, student/teacher onboarding, role-based shells
(bottom navigation per the spec), and Firestore security rules.

## Setup
1. `flutter create .` (generates android/ios folders; keeps lib/ and pubspec.yaml)
2. Create a Firebase project; enable **Authentication > Google** and **Firestore**.
3. `dart pub global activate flutterfire_cli && flutterfire configure`
   (Android: add your SHA-1/SHA-256 fingerprints in Firebase for Google Sign-In.)
4. `flutter pub get && flutter run`
5. Deploy rules: `firebase deploy --only firestore:rules`

## Seed data (Firestore console)
- `universities/pu` : { name: "Panjab University, Chandigarh" }
- `colleges/<id>`   : { name: "Your College", universityId: "pu" }
- `courses/<id>`    : { name: "BA", collegeId: "<college id>" }

## Make the first admin
Sign in once, then in the Firestore console set `users/<your uid>.role` to `admin`
and `status` to `verified`. (Rules stop anyone else from doing this.)

## Design notes
- Student identity = College + Session + Course + Semester + Section + Roll No.,
  claimed atomically in `academicIdentities/{key}` (transaction), so it can't be duplicated.
- New accounts start as `pending_verification`; only admins can change role/status.
- Firestore offline persistence is on; the admin verification UI is the next step.
