import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import '../home_screen.dart';
import '../patients/patient_detail_screen.dart';
import '../patients/patient_list_screen.dart';
import '../tools/reference_screen.dart';
import '../tools/tool_workspace_screen.dart';
import '../tools/tools_hub_screen.dart';
import 'shell_scope.dart';

/// The signed-in app: four tabs, each with its own navigator so switching
/// tabs keeps every tab's place. The navigator keys live in [State], so a
/// fresh [MainShell] (e.g. after sign-out and sign-in) starts every tab anew.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _roots = <Widget>[
    HomeScreen(),
    PatientListScreen(),
    ToolsHubScreen(),
    ReferenceScreen(),
  ];

  final _navigatorKeys = List.generate(
    _roots.length,
    (_) => GlobalKey<NavigatorState>(),
  );
  int _tab = ShellTab.home;

  NavigatorState? _navigator(int tab) => _navigatorKeys[tab].currentState;

  void _popToRoot(int tab) => _navigator(tab)?.popUntil((r) => r.isFirst);

  void _openTab(int tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  void _onDestinationSelected(int tab) {
    HapticFeedback.selectionClick();
    if (tab == _tab) {
      _popToRoot(tab);
    } else {
      _openTab(tab);
    }
  }

  void _openIn(int tab, Widget page) {
    _openTab(tab);
    _popToRoot(tab);
    _navigator(tab)?.push(appRoute(page));
  }

  void _openTool(String toolId) =>
      _openIn(ShellTab.tools, ToolWorkspaceScreen(initialToolId: toolId));

  void _openPatient(String patientId) =>
      _openIn(ShellTab.patients, PatientDetailScreen(patientId: patientId));

  void _handleBack() {
    final navigator = _navigator(_tab);
    if (navigator != null && navigator.canPop()) {
      navigator.maybePop();
    } else if (_tab != ShellTab.home) {
      setState(() => _tab = ShellTab.home);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      openTab: _openTab,
      openTool: _openTool,
      openPatient: _openPatient,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          body: IndexedStack(
            index: _tab,
            children: [
              for (var i = 0; i < _roots.length; i++)
                Navigator(
                  key: _navigatorKeys[i],
                  onGenerateRoute: (_) =>
                      MaterialPageRoute(builder: (_) => _roots[i]),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Patients',
              ),
              NavigationDestination(
                icon: Icon(Icons.handyman_outlined),
                selectedIcon: Icon(Icons.handyman),
                label: 'Tools',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Reference',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
