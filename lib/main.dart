import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/patient_service.dart';
import 'services/product_infra_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';
import 'screens/tools/phoria_screen.dart';
import 'screens/tools/vergence_screen.dart';
import 'screens/tools/accommodation_screen.dart';
import 'screens/tools/analysis_screen.dart';
import 'screens/tools/diagnosis_screen.dart';
import 'screens/tools/reference_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding_screen.dart';

bool _firebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final firebaseOptions = _loadFirebaseOptions();
  if (firebaseOptions == null) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  await Firebase.initializeApp(options: firebaseOptions);
  _firebaseReady = true;
  await ProductInfraService.init();

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

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 44, color: kBadText),
                  SizedBox(height: 16),
                  Text(
                    'Firebase is not configured',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Run FlutterFire setup or pass Firebase dart defines before launching.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6E6E73)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      navigatorObservers: _firebaseReady
          ? [
              FirebaseAnalyticsObserver(
                analytics: ProductInfraService.analytics,
              ),
            ]
          : const [],
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  static const _onboardingCompleteKey = 'onboarding_complete';
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    var complete = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      complete = prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (_) {
      complete = false;
    }
    if (mounted) setState(() => _showOnboarding = !complete);
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
    } catch (_) {
      // Onboarding is non-critical; continue to auth if local storage fails.
    }
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    if (isLoggedIn) return const MainShell();
    final showOnboarding = _showOnboarding;
    if (showOnboarding == null) return const _StartupSplash();
    return showOnboarding
        ? OnboardingScreen(
            onComplete: _finishOnboarding,
            onLogIn: _finishOnboarding,
          )
        : const LoginScreen();
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 42, color: kPrimary),
              SizedBox(height: 14),
              Text(
                'BV Toolkit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

FirebaseOptions? _loadFirebaseOptions() {
  try {
    return DefaultFirebaseOptions.currentPlatform;
  } catch (_) {
    return null;
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
    ('Phoria & ratios', 'AC/A and CA/C'),
    ('Vergence & NPC', 'Ranges vs. norms'),
    ('Accommodation', 'Norms & ranges'),
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
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => _goTab(6),
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
          const AccommodationScreen(),
          const AnalysisScreen(),
          const DiagnosisScreen(),
          const ReferenceScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab < 6 ? _tab : 0,
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
            icon: Icon(Icons.zoom_in_outlined),
            selectedIcon: Icon(Icons.zoom_in),
            label: 'Acc.',
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
