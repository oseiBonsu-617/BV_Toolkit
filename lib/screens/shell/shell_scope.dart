import 'package:flutter/widgets.dart';
import '../../config/tools.dart';

/// Indices of the four bottom-bar tabs.
abstract final class ShellTab {
  static const home = 0, patients = 1, tools = 2, reference = 3;
}

/// Lets screens inside the main shell switch tabs and open tools or patients.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.openTab,
    required this.openTabAtRoot,
    required this.openTool,
    required this.openPatient,
    required this.openReference,
    required super.child,
  });

  final void Function(int tab) openTab;

  /// Shows [tab] popped back to its first screen (e.g. the patient list).
  final void Function(int tab) openTabAtRoot;
  final void Function(String toolId) openTool;
  final void Function(String patientId) openPatient;

  /// Shows the Reference tab with the entry titled [entryTitle] found and
  /// opened.
  final void Function(String entryTitle) openReference;

  static ShellScope of(BuildContext c) {
    final scope = c.dependOnInheritedWidgetOfExactType<ShellScope>();
    assert(scope != null, 'No ShellScope found in context');
    return scope!;
  }

  /// Opens a Home shortcut: a tool id, `'patients'` or `'reference'`.
  void openShortcut(String id) {
    if (toolById(id) != null) {
      openTool(id);
    } else if (id == 'patients') {
      openTab(ShellTab.patients);
    } else if (id == 'reference') {
      openTab(ShellTab.reference);
    }
  }

  // The callbacks are stable for the lifetime of the shell.
  @override
  bool updateShouldNotify(ShellScope old) => false;
}
