import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/result_card.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});
  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SegmentedControl(
            labels: const ['BV', 'Acc.', 'Strabismus', 'Formulas'],
            selected: _seg,
            onChanged: (i) => setState(() => _seg = i),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              if (_seg == 0) _buildBV(),
              if (_seg == 1) _buildAcc(),
              if (_seg == 2) _buildStrab(),
              if (_seg == 3) _buildFormulas(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBV() => AppCard(child: Column(children: [
    _refItem('Convergence Insufficiency',
        [Pill.info('Exo near > dist'), Pill.info('Low AC/A'), Pill.info('Receded NPC')],
        'Exo at near >6Δ, receded NPC, reduced BO vergence. VT first-line; BI prism for relief.'),
    _refItem('Convergence Excess',
        [Pill.info('Eso at near'), Pill.info('High AC/A')],
        'Eso greater at near; high AC/A. Plus add or BI prism; VT.'),
    _refItem('Divergence Insufficiency',
        [Pill.info('Eso at distance'), Pill.info('Low AC/A')],
        'Eso at distance. Exclude VI nerve palsy. BI prism at distance.'),
    _refItem('Divergence Excess',
        [Pill.info('Exo at distance')],
        'Exo greater at distance. Test with +3.00 DS. Minus lens or BO prism/VT.'),
    _refItem('Basic Exophoria',
        [Pill.info('Equal exo'), Pill.info('Normal AC/A')],
        'Similar exo at both distances. VT or BO prism.'),
    _refItem('Basic Esophoria',
        [Pill.info('Equal eso'), Pill.info('Normal AC/A')],
        'Similar eso at both distances. BI prism or plus add.'),
    _refItem('Fusional Vergence Dysfunction',
        [Pill.info('Orthophoria'), Pill.info('Reduced BI & BO')],
        'Ortho but low vergence bilaterally. Vergence training.',
        isLast: true),
  ]));

  Widget _buildAcc() => AppCard(child: Column(children: [
    _refItem('Accommodative Insufficiency',
        [Pill.purple('Low amplitude'), Pill.purple('High lag'), Pill.purple('Fails minus')],
        'Amp below Hofstetter minimum; high MEM lag >0.75D; fails minus flipper. Facility training + plus adds.'),
    _refItem('Accommodative Excess',
        [Pill.purple('Spasm'), Pill.purple('Low lag'), Pill.purple('Fails plus')],
        'Ciliary spasm; MEM lag <0.25D; fails plus flipper. Plus lenses; cycloplegics short-term.'),
    _refItem('Accommodative Infacility',
        [Pill.purple('Slow facility'), Pill.purple('Fails both sides'), Pill.purple('Normal amp')],
        'Normal amplitude but fails both ± sides; <11 cpm bino. Flipper training.',
        isLast: true),
  ]));

  Widget _buildStrab() => AppCard(child: Column(children: [
    _refItem('Esotropia (ET)',
        [Pill.info('Convergent'), Pill.info('Manifest')],
        'Inward manifest deviation. Accommodative (RAET/NRAET), non-accommodative, decompensated.'),
    _refItem('Exotropia (XT)',
        [Pill.info('Divergent'), Pill.info('Manifest')],
        'Intermittent XT most common. Basic, DE type, CI type, true DE.'),
    _refItem('Hypertropia',
        [Pill.info('Vertical')],
        'Vertical deviation. DVD is special case associated with infantile ET.'),
    _refItem('Microtropia',
        [Pill.info('<10Δ'), Pill.info('Monofixation')],
        'Small-angle; central scotoma; peripheral fusion intact. Often missed on cover test.'),
    _refItem('Cyclotropia',
        [Pill.info('Torsional'), Pill.info('IV nerve')],
        'IV nerve palsy; Bielschowsky head tilt sign.',
        isLast: true),
  ]));

  Widget _buildFormulas(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg = kOkBg;
    final codeText = kOkText;

    Widget formula(String name, String eq, String? note) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          )),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: codeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(eq, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: codeText)),
          ),
          if (note != null) ...[
            const SizedBox(height: 3),
            Text(note, style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            )),
          ],
        ]),
      );
    }

    return AppCard(child: Column(children: [
      formula('AC/A (calculated)', 'AC/A = (IPD/10) + (Pn − Pd) / A', 'Normal: 3–5 Δ/D'),
      formula("Sheard's prism", 'P = (2/3)|ph| − (1/3) × CV', null),
      formula("Percival's prism", 'P = (1/3)G − (2/3)L', null),
      formula('Hofstetter min. amplitude', 'Min = 15 − 0.25 × Age', null),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Prism diopter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: codeBg, borderRadius: BorderRadius.circular(6)),
            child: Text('Δ = 100 × tan(angle°)',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: codeText)),
          ),
        ]),
      ),
    ]));
  }

  Widget _refItem(String name, List<Widget> tags, String desc, {bool isLast = false}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          )),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: tags),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
          )),
        ]),
      );
    });
  }
}
