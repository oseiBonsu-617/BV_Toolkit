import 'package:flutter/material.dart';

class ToolDef {
  final String id, name, shortLabel, description, group;
  final IconData icon;
  const ToolDef({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.group,
    required this.icon,
  });
}

const List<ToolDef> kTools = [
  ToolDef(
    id: 'phoria',
    name: 'Phoria & ratios',
    shortLabel: 'Phoria',
    description: 'AC/A and CA/C',
    group: 'Measurements',
    icon: Icons.remove_red_eye_outlined,
  ),
  ToolDef(
    id: 'vergence',
    name: 'Vergence & NPC',
    shortLabel: 'Vergence',
    description: 'Ranges vs. norms',
    group: 'Measurements',
    icon: Icons.compare_arrows,
  ),
  ToolDef(
    id: 'accommodation',
    name: 'Accommodation',
    shortLabel: 'Acc.',
    description: 'Norms & ranges',
    group: 'Measurements',
    icon: Icons.zoom_in_outlined,
  ),
  ToolDef(
    id: 'analysis',
    name: "Sheard's & Percival's",
    shortLabel: "Sheard's",
    description: 'Prism criteria',
    group: 'Analysis',
    icon: Icons.balance_outlined,
  ),
  ToolDef(
    id: 'graphical',
    name: 'Graphical analysis',
    shortLabel: 'ZCSBV',
    description: 'ZCSBV plot',
    group: 'Analysis',
    icon: Icons.stacked_line_chart_outlined,
  ),
  ToolDef(
    id: 'diagnose',
    name: 'Diagnose',
    shortLabel: 'Diagnose',
    description: 'Ranked BV diagnosis',
    group: 'Diagnosis',
    icon: Icons.medical_services_outlined,
  ),
];

const List<String> kToolGroups = ['Measurements', 'Analysis', 'Diagnosis'];

ToolDef? toolById(String id) {
  for (final t in kTools) {
    if (t.id == id) return t;
  }
  return null;
}

class ShortcutDef {
  final String id, name;
  final IconData icon;
  const ShortcutDef({required this.id, required this.name, required this.icon});
}

final List<ShortcutDef> kShortcuts = [
  for (final t in kTools) ShortcutDef(id: t.id, name: t.name, icon: t.icon),
  const ShortcutDef(id: 'patients', name: 'Patients', icon: Icons.people_outline),
  const ShortcutDef(id: 'reference', name: 'Reference', icon: Icons.menu_book_outlined),
];

const List<String> kDefaultShortcuts = ['phoria', 'vergence', 'graphical'];

const int kMinShortcuts = 3;
