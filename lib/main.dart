import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'l10n/strings.dart';
import 'screens/admin_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_state.dart';
import 'services/firebase_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.init();
  final storage = await StorageService.init();
  final app = AppState(storage);
  runApp(ZahidAcademyApp(app: app));
}

class ZahidAcademyApp extends StatelessWidget {
  final AppState app;

  const ZahidAcademyApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      app: app,
      child: MaterialApp(
        title: 'Zahid Architecture Academy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A2540),
          ),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: app.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          );
        },
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    final pages = <Widget>[
      const HomeScreen(),
      LibraryScreen(),
      const CoursesScreen(),
      const ProfileScreen(),
      if (app.user?.isAdmin == true) const AdminScreen(),
    ];
    final safeIndex = _index < pages.length ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('app_title')),
        actions: [
          IconButton(
            tooltip: s.t('notifications'),
            onPressed: () => _showNotifications(app, s),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (app.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${app.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.t('language'),
            onPressed: () => app.toggleLang(),
            icon: const Icon(Icons.translate),
          ),
          const SizedBox(width: 2),
        ],
      ),
      drawer: _buildDrawer(app, s),
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        selectedItemColor: const Color(0xFF0A2540),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _index = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: s.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_library_outlined),
            activeIcon: const Icon(Icons.local_library),
            label: s.t('library'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school),
            label: s.t('courses'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: s.t('profile'),
          ),
          if (app.user?.isAdmin == true)
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              activeIcon: const Icon(Icons.admin_panel_settings),
              label: s.t('admin'),
            ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(AppState app, S s) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF0A2540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(
                      app.user == null ? Icons.person : Icons.account_circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    app.user?.displayName ?? s.t('guest'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    app.user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.home_outlined, s.t('home'), 0),
            _drawerItem(Icons.local_library_outlined, s.t('library'), 1),
            _drawerItem(Icons.school_outlined, s.t('courses'), 2),
            _drawerItem(Icons.person_outline, s.t('profile'), 3),
            if (app.user?.isAdmin == true)
              _drawerItem(Icons.admin_panel_settings_outlined, s.t('admin'), 4),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(s.t('settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: Text(s.t('whatsapp_contact')),
              onTap: () {
                Navigator.pop(context);
                app.openWhatsApp(
                  'Assalam-o-Alaikum, Mujhe Zahid Architecture Academy ki madad chahiye',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _index == index,
      onTap: () {
        setState(() => _index = index);
        Navigator.pop(context);
      },
    );
  }

  void _showNotifications(AppState app, S s) {
    final items = app.notifications;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('notifications')),
        content: items.isEmpty
            ? Text(s.t('all'))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.orange),
                      title: Text(s.t(item.titleKey)),
                      subtitle: Text(s.t(item.bodyKey)),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.t('close')),
          ),
        ],
      ),
    );
  }
}
