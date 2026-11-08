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

  @override
  State<ToolWorkspaceScreen> createState() => _ToolWorkspaceScreenState();
}

class _ToolWorkspaceScreenState extends State<ToolWorkspaceScreen> {
  final _graphicalKey = GlobalKey<GraphicalAnalysisBodyState>();
  late int _index;

  @override
  void initState() {
    super.initState();
    final i = kTools.indexWhere((t) => t.id == widget.initialToolId);
    _index = i < 0 ? 0 : i;
  }

  void _switchTo(String id) {
    final i = kTools.indexWhere((t) => t.id == id);
    if (i >= 0 && i != _index) setState(() => _index = i);
  }

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
                fontSize: 11,
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
              child: const Text('Example', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: kTools.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = kTools[i];
                return ChoiceChip(
                  key: Key('tool-chip-${t.id}'),
                  label: Text(t.shortLabel),
                  selected: i == _index,
                  selectedColor: kPrimary.withValues(alpha: 0.15),
                  onSelected: (_) => _switchTo(t.id),
                );
              },
            ),
          ),
          Expanded(
            child: ToolWorkspaceScope(
              switchTo: _switchTo,
              child: IndexedStack(
                index: _index,
                children: [
                  const PhoriaScreen(),
                  const VergenceScreen(),
                  const AccommodationScreen(),
                  const AnalysisScreen(),
                  GraphicalAnalysisBody(key: _graphicalKey),
                  const DiagnosisScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
