import 'package:flutter/material.dart';
import '../../config/tools.dart';
import '../../theme.dart';
import 'accommodation_screen.dart';
import 'analysis_screen.dart';
import 'diagnosis_screen.dart';
import 'graphical_analysis_screen.dart';
import 'phoria_screen.dart';
import 'vergence_screen.dart';

class ToolWorkspaceScope extends InheritedWidget {
  const ToolWorkspaceScope({
    super.key,
    required this.switchTo,
    required super.child,
  });

  final void Function(String toolId) switchTo;

  static ToolWorkspaceScope? maybeOf(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<ToolWorkspaceScope>();

  @override
  bool updateShouldNotify(ToolWorkspaceScope old) => false;
}

class ToolWorkspaceScreen extends StatefulWidget {
  const ToolWorkspaceScreen({super.key, required this.initialToolId});
  final String initialToolId;

  /// Name of the route [route] builds.
  static const routeName = 'tool-workspace';

  /// A page route to a workspace opened on [initialToolId]. Its settings
  /// carry the workspace's key, so the shell can switch it in place.
  static Route<void> route(String initialToolId) {
    final key = GlobalKey<ToolWorkspaceScreenState>();
    return appRoute(
      ToolWorkspaceScreen(key: key, initialToolId: initialToolId),
      settings: RouteSettings(name: routeName, arguments: key),
    );
  }

  /// The workspace shown by a [route] built by [ToolWorkspaceScreen.route].
  static ToolWorkspaceScreenState? stateOf(Route<dynamic> route) {
    final key = route.settings.arguments;
    return key is GlobalKey<ToolWorkspaceScreenState> ? key.currentState : null;
  }

  @override
  State<ToolWorkspaceScreen> createState() => ToolWorkspaceScreenState();
}

class ToolWorkspaceScreenState extends State<ToolWorkspaceScreen> {
  final _graphicalKey = GlobalKey<GraphicalAnalysisBodyState>();
  final _chipKeys = {for (final t in kTools) t.id: GlobalKey()};
  late int _index;

  @override
  void initState() {
    super.initState();
    final i = kTools.indexWhere((t) => t.id == widget.initialToolId);
    _index = i < 0 ? 0 : i;
    _revealSelectedChip();
  }

  /// Shows the tool [id]; every tool keeps what was typed into it.
  void switchTo(String id) {
    final i = kTools.indexWhere((t) => t.id == id);
    if (i >= 0 && i != _index) {
      setState(() => _index = i);
      _revealSelectedChip();
    }
  }

  /// After the frame, scrolls the switcher strip just enough to show the
  /// selected chip in full.
  void _revealSelectedChip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chipKeys[kTools[_index].id]!.currentContext;
      if (!mounted || chip == null) return;
      // At most one of these moves the strip: the chip is cut off either at
      // the end or at the start.
      for (final policy in const [
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ]) {
        Scrollable.ensureVisible(
          chip,
          alignmentPolicy: policy,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// The body of each tool. The stack below is built in [kTools] order from
  /// this, so a chip and the body it shows can't drift apart.
  Widget _bodyFor(String id) => switch (id) {
    'phoria' => const PhoriaScreen(),
    'vergence' => const VergenceScreen(),
    'accommodation' => const AccommodationScreen(),
    'analysis' => const AnalysisScreen(),
    'graphical' => GraphicalAnalysisBody(key: _graphicalKey),
    'diagnose' => const DiagnosisScreen(),
    _ => throw StateError('No body for tool "$id"'),
  };

  @override
  Widget build(BuildContext context) {
    final tool = kTools[_index];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tool.name),
            Text(
              tool.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        actions: [
          if (tool.id == 'graphical')
            TextButton(
              key: const Key('tool-example'),
              onPressed: () => _graphicalKey.currentState?.loadExample(),
              child: const Text('Example', style: TextStyle(fontSize: 15)),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            // Not a lazy list: every chip is built, so any of them can be
            // scrolled into view.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, t) in kTools.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    KeyedSubtree(
                      key: _chipKeys[t.id],
                      child: ChoiceChip(
                        key: Key('tool-chip-${t.id}'),
                        label: Text(t.shortLabel),
                        selected: i == _index,
                        selectedColor: kPrimary.withValues(alpha: 0.15),
                        onSelected: (_) => switchTo(t.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ToolWorkspaceScope(
              switchTo: switchTo,
              child: IndexedStack(
                index: _index,
                children: [for (final t in kTools) _bodyFor(t.id)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
