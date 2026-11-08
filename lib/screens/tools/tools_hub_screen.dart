import 'package:flutter/material.dart';
import '../../config/tools.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';
import 'tool_workspace_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final group in kToolGroups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Text(
                group,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ),
            for (final t in kTools.where((t) => t.group == group))
              AppCard(
                child: ListTile(
                  key: Key('tool-row-${t.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(t.icon, color: kPrimary),
                  title: Text(t.name),
                  subtitle: Text(t.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    appRoute(ToolWorkspaceScreen(initialToolId: t.id)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
