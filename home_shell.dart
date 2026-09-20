import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class _Tab {
  final String label;
  final IconData icon;
  const _Tab(this.label, this.icon);
}

const _studentTabs = [
  _Tab('Home', Icons.home_outlined),
  _Tab('Subjects', Icons.menu_book_outlined),
  _Tab('Updates', Icons.campaign_outlined),
  _Tab('Timetable', Icons.calendar_month_outlined),
  _Tab('Profile', Icons.person_outline),
];
const _teacherTabs = [
  _Tab('Dashboard', Icons.dashboard_outlined),
  _Tab('Classes', Icons.groups_outlined),
  _Tab('Tasks', Icons.checklist_outlined),
  _Tab('Updates', Icons.campaign_outlined),
  _Tab('Profile', Icons.person_outline),
];
const _adminTabs = [
  _Tab('Dashboard', Icons.dashboard_outlined),
  _Tab('Users', Icons.people_outline),
  _Tab('Structure', Icons.account_tree_outlined),
  _Tab('Content', Icons.article_outlined),
  _Tab('Settings', Icons.settings_outlined),
];

class HomeShell extends StatefulWidget {
  final AppUser appUser;
  const HomeShell({super.key, required this.appUser});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  List<_Tab> get _tabs => switch (widget.appUser.role) {
        UserRole.student => _studentTabs,
        UserRole.teacher => _teacherTabs,
        UserRole.admin => _adminTabs,
      };

  @override
  Widget build(BuildContext context) {
    final u = widget.appUser;
    final tab = _tabs[_index];
    final isProfile = tab.label == 'Profile' || tab.label == 'Settings';

    return Scaffold(
      appBar: AppBar(title: Text(tab.label)),
      body: Column(
        children: [
          if (u.status == AccountStatus.pendingVerification)
            MaterialBanner(
              leading: const Icon(Icons.hourglass_top),
              content: Text(u.role == UserRole.teacher
                  ? 'Pending verification: an administrator must verify your teacher account.'
                  : 'Pending verification: your class teacher or admin will confirm your enrollment.'),
              actions: const [SizedBox.shrink()],
            ),
          if (u.status == AccountStatus.suspended)
            const MaterialBanner(
              leading: Icon(Icons.block),
              content: Text('Your account is suspended. Contact your college administrator.'),
              actions: [SizedBox.shrink()],
            ),
          Expanded(
            child: isProfile
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                          child: u.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u.name),
                        subtitle: Text('${u.email}\nRole: ${u.role.name}'),
                        isThreeLine: true,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: AuthService.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                    ],
                  )
                : Center(child: Text('${tab.label}: coming in a later phase')),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
