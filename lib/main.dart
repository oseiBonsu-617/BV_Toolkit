import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/patient_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';
import 'screens/tools/phoria_screen.dart';
import 'screens/tools/vergence_screen.dart';
import 'screens/tools/analysis_screen.dart';
import 'screens/tools/diagnosis_screen.dart';
import 'screens/tools/reference_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final auth = AuthService();
  await auth.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProxyProvider<AuthService, PatientService>(
          create: (_) => PatientService(),
          update: (_, authSvc, patients) {
            patients!.setUserId(authSvc.currentUser?.id);
            return patients;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, SessionService>(
          create: (_) => SessionService(),
          update: (_, authSvc, sessions) {
            sessions!.setUserId(authSvc.currentUser?.id);
            return sessions;
          },
        ),
      ],
      child: const BVToolkitApp(),
    ),
  );
}

class BVToolkitApp extends StatelessWidget {
  const BVToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BV Toolkit',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    return isLoggedIn ? const MainShell() : const LoginScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _titles = [
    ('BV Toolkit', 'Clinical suite'),
    ('Phoria & AC/A', 'Classification & ratio'),
    ('Vergence & NPC', 'Ranges vs. norms'),
    ('Analysis', "Sheard's & Percival's"),
    ('Diagnose', 'Ranked BV diagnosis'),
    ('Reference', 'Norms & conditions'),
  ];

  void _goTab(int tab) {
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
  }

  void _openProfile() {
    Navigator.push(context, appRoute(const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthService>().currentUser;
    final (title, subtitle) = _titles[_tab];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(subtitle, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => _goTab(5),
            tooltip: 'Reference',
          ),
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onNavigate: _goTab),
          const PhoriaScreen(),
          const VergenceScreen(),
          const AnalysisScreen(),
          const DiagnosisScreen(),
          const ReferenceScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab < 5 ? _tab : 0,
        onDestinationSelected: _goTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.remove_red_eye_outlined),
            selectedIcon: Icon(Icons.remove_red_eye),
            label: 'Phoria',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Vergence',
          ),
          NavigationDestination(
            icon: Icon(Icons.balance_outlined),
            selectedIcon: Icon(Icons.balance),
            label: 'Analysis',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Diagnose',
          ),
        ],
      ),
    );
  }
}
