import 'package:flutter/material.dart';
import '../config/tools.dart';
import 'shortcut_grid.dart';

/// Full-screen picker for Home shortcuts. Returns the new list on Save,
/// or null on Cancel.
Future<List<String>?> showHomeShortcutsPicker(
  BuildContext context, {
  required List<String> initial,
}) {
  return Navigator.of(context, rootNavigator: true).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _HomeShortcutsPicker(initial: initial),
    ),
  );
}

class _HomeShortcutsPicker extends StatefulWidget {
  const _HomeShortcutsPicker({required this.initial});
  final List<String> initial;

  @override
  State<_HomeShortcutsPicker> createState() => _HomeShortcutsPickerState();
}

class _HomeShortcutsPickerState extends State<_HomeShortcutsPicker> {
  late final List<String> _selected = List.of(widget.initial);

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selected.length >= kMinShortcuts;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 80,
        leading: TextButton(
          key: const Key('picker-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        title: const Text('Home shortcuts'),
        centerTitle: true,
        actions: [
          TextButton(
            key: const Key('picker-save'),
            onPressed: canSave
                ? () => Navigator.of(context).pop(List<String>.of(_selected))
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose at least $kMinShortcuts.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            ShortcutGrid(selected: _selected, onToggle: _toggle),
          ],
        ),
      ),
    );
  }
}
