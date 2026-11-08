import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _stacks = List.generate(_roots.length, (_) => _RouteStack());
  late final _observers = [
    for (final stack in _stacks) <NavigatorObserver>[stack],
  ];
  int _tab = ShellTab.home;

  NavigatorState? _navigator(int tab) => _navigatorKeys[tab].currentState;

  /// Pops [tab]'s stack until [stop] holds for the top route. Each pop goes
  /// through `maybePop`, so a route's PopScope (e.g. an unsaved session) can
  /// refuse; then this stops, leaves the rest of the stack alone and returns
  /// false, and the caller must not go on to push or switch.
  Future<bool> _popUntil(int tab, bool Function(Route<dynamic>) stop) async {
    final navigator = _navigator(tab);
    if (navigator == null) return false;
    final routes = _stacks[tab].routes;
    while (routes.isNotEmpty && !stop(routes.last) && navigator.canPop()) {
      final depth = routes.length;
      await navigator.maybePop();
      // A vetoed pop leaves the route in place: the stack did not shrink.
      if (!mounted || routes.length >= depth) return false;
    }
    return true;
  }

  Future<bool> _popToRoot(int tab) => _popUntil(tab, (r) => r.isFirst);

  void _openTab(int tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  /// Pops [tab] to its root while it is still hidden, then shows it. If a
  /// route refuses to pop (an unsaved session), it stays and the tab is shown
  /// with it, so the user sees what the discard prompt is about.
  Future<void> _openTabAtRoot(int tab) async {
    await _popToRoot(tab);
    if (mounted) _openTab(tab);
  }

  void _onDestinationSelected(int tab) {
    HapticFeedback.selectionClick();
    if (tab == _tab) {
      _popToRoot(tab);
    } else {
      _openTab(tab);
    }
  }

  /// Shows [tab], pops it to its root and pushes [route] — unless a route
  /// on the way refuses to pop.
  Future<void> _openIn(int tab, Route<void> route) async {
    _openTab(tab);
    if (await _popToRoot(tab)) _navigator(tab)?.push(route);
  }

  /// Shows [toolId] in the Tools tab. An open workspace is switched in place
  /// (after popping anything above it), so values typed into its tools stay
  /// until the user goes back to the Tools list; otherwise one is pushed.
  Future<void> _openTool(String toolId) async {
    final workspace = _stacks[ShellTab.tools].routes.reversed
        .where((r) => r.settings.name == ToolWorkspaceScreen.routeName)
        .firstOrNull;
    if (workspace == null) {
      await _openIn(ShellTab.tools, ToolWorkspaceScreen.route(toolId));
      return;
    }
    _openTab(ShellTab.tools);
    if (await _popUntil(ShellTab.tools, (r) => identical(r, workspace))) {
      ToolWorkspaceScreen.stateOf(workspace)?.switchTo(toolId);
    }
  }

  /// Shows the patient's detail in the Patients tab. If that patient is
  /// already open there (the detail or a screen of their flow above it), the
  /// tab is shown as it is.
  Future<void> _openPatient(String patientId) async {
    final alreadyOpen = _stacks[ShellTab.patients].routes.any(
      (r) =>
          r.settings.name == PatientDetailScreen.routeName &&
          r.settings.arguments == patientId,
    );
    if (alreadyOpen) {
      _openTab(ShellTab.patients);
    } else {
      await _openIn(ShellTab.patients, PatientDetailScreen.route(patientId));
    }
  }

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
      openTabAtRoot: _openTabAtRoot,
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
                  observers: _observers[i],
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

/// Mirrors a tab navigator's route stack, so the shell can see what is open
/// in a tab and tell whether a pop actually removed a route.
class _RouteStack extends NavigatorObserver {
  final routes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : routes.indexOf(oldRoute);
    if (newRoute == null) {
      if (i >= 0) routes.removeAt(i);
    } else if (i >= 0) {
      routes[i] = newRoute;
    } else {
      routes.add(newRoute);
    }
  }
}
