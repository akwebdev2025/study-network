import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/registration_service.dart';

const kSessions = ['2026-27', '2027-28'];

class OnboardingScreen extends StatefulWidget {
  final User user;
  const OnboardingScreen({super.key, required this.user});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  String _role = 'student';
  String? _collegeId, _courseId, _session = kSessions.first;
  int _semester = 1;
  final _section = TextEditingController();
  final _roll = TextEditingController();
  final _dept = TextEditingController();
  final _designation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_section, _roll, _dept, _designation]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_role == 'student') {
        await RegistrationService.registerStudent(
          user: widget.user, collegeId: _collegeId!, courseId: _courseId!,
          session: _session!, semester: _semester,
          section: _section.text.trim(), rollNo: _roll.text.trim(),
        );
      } else {
        await RegistrationService.registerTeacher(
          user: widget.user, collegeId: _collegeId!,
          department: _dept.text.trim(), designation: _designation.text.trim(),
          session: _session!,
        );
      }
    } catch (e) {
      _error = e is DuplicateIdentityException
          ? e.toString()
          : 'Could not save your details. Check your connection and try again.';
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your account'),
        actions: [TextButton(onPressed: AuthService.signOut, child: const Text('Sign out'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Signed in as ${widget.user.email}'),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'teacher', label: Text('Teacher'), icon: Icon(Icons.cast_for_education)),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 20),
            _collegeDropdown(),
            const SizedBox(height: 16),
            if (_role == 'student') ..._studentFields() else ..._teacherFields(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _session,
              decoration: const InputDecoration(labelText: 'Academic session', border: OutlineInputBorder()),
              items: kSessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _session = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit for verification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collegeDropdown() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('colleges').orderBy('name').snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            value: _collegeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'College', border: OutlineInputBorder()),
            items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
            validator: (v) => v == null ? 'Select your college' : null,
            onChanged: (v) => setState(() { _collegeId = v; _courseId = null; }),
          );
        },
      );

  List<Widget> _studentFields() => [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _collegeId == null
              ? const Stream.empty()
              : FirebaseFirestore.instance
                  .collection('courses')
                  .where('collegeId', isEqualTo: _collegeId)
                  .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            return DropdownButtonFormField<String>(
              value: _courseId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Course',
                helperText: _collegeId == null ? 'Select a college first' : null,
                border: const OutlineInputBorder(),
              ),
              items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
              validator: (v) => v == null ? 'Select your course' : null,
              onChanged: (v) => setState(() => _courseId = v),
            );
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _semester,
          decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
          items: [for (var i = 1; i <= 8; i++) DropdownMenuItem(value: i, child: Text('Semester $i'))],
          onChanged: (v) => setState(() => _semester = v ?? 1),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _section,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Section (e.g. D)', border: OutlineInputBorder()),
          validator: _required,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _roll,
          decoration: const InputDecoration(labelText: 'Roll number', border: OutlineInputBorder()),
          validator: _required,
        ),
      ];

  List<Widget> _teacherFields() => [
        TextFormField(
          controller: _dept,
          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
          validator: _required,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _designation,
          decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()),
          validator: _required,
        ),
      ];
}
