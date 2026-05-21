import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/result_card.dart';
import 'patients/patient_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(icon: Icons.table_chart_outlined, text: "Morgan's norms"),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: borderColor, width: 0.5),
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
                children: [
                  _headerRow(['Test', 'Dist', 'Near'], context),
                  _dataRow(['Phoria', '1Δ exo', '3Δ exo'], context, highlight: true),
                  _dataRow(['BI break', '7Δ', '21Δ'], context),
                  _dataRow(['BO break', '19Δ', '21Δ'], context),
                  _dataRow(['NPC break', '≤ 5 cm', ''], context, highlight: true, colSpan2: true),
                  _dataRow(['Acc. facility', '≥ 11 cpm', ''], context, colSpan2: true),
                ],
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            _tile(context, Icons.remove_red_eye_outlined, 'Phoria & AC/A',
                'Classify & calculate ratio', 1),
            _tile(context, Icons.open_with, 'Vergence & NPC',
                'Ranges vs. norms', 2),
            _tile(context, Icons.balance_outlined, 'Analysis',
                "Sheard's & Percival's", 3),
            _tile(context, Icons.medical_services_outlined, 'Diagnose',
                'Ranked BV diagnosis', 4,
                highlighted: true, badge: 'New'),
            _patientsTile(context),
          ],
        ),
      ],
    );
  }

  TableRow _headerRow(List<String> cells, BuildContext context) {
    return TableRow(
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Text(c,
            style: TextStyle(
              fontSize: 10,
              textBaseline: TextBaseline.alphabetic,
              letterSpacing: 0.4,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6E6E73),
            )),
      )).toList(),
    );
  }

  TableRow _dataRow(List<String> cells, BuildContext context,
      {bool highlight = false, bool colSpan2 = false}) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
      color: highlight ? kPrimary : null,
    );
    if (colSpan2) {
      return TableRow(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Text(cells[0], style: const TextStyle(fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Text(cells[1], style: style),
        ),
        const SizedBox.shrink(),
      ]);
    }
    return TableRow(
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Text(c, style: style),
      )).toList(),
    );
  }

  Widget _patientsTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PatientListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.people_outline, size: 20, color: kPrimary),
          const SizedBox(height: 6),
          const Text('Patients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('Records & profiles',
              style: TextStyle(fontSize: 11, height: 1.35,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73))),
        ]),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String desc, int tab,
      {bool highlighted = false, String? badge}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onNavigate(tab),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border.all(
            color: highlighted ? kPrimary : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
            width: highlighted ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: kPrimary),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 4),
                  Pill.normal(badge),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(desc,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                )),
          ],
        ),
      ),
    );
  }
}
