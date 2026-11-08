import 'package:flutter/material.dart';
import '../../data/reference_data.dart';
import '../../theme.dart';
import '../../widgets/profile_avatar_button.dart';
import '../../widgets/result_card.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key, this.request});

  /// Set to an entry title to show that entry, found and opened. The screen
  /// resets it to null once handled, so the same title can be asked again.
  final ValueNotifier<String?>? request;

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'Vergence anomalies';
  final _focusNode = FocusNode();

  /// The entry a request asked for; its tile starts expanded.
  String? _openTitle;

  /// Bumped on each request so the tiles are rebuilt and the requested one
  /// opens again even if the user had closed it.
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    widget.request?.addListener(_onRequest);
    _onRequest();
  }

  @override
  void didUpdateWidget(ReferenceScreen old) {
    super.didUpdateWidget(old);
    if (old.request != widget.request) {
      old.request?.removeListener(_onRequest);
      widget.request?.addListener(_onRequest);
      _onRequest();
    }
  }

  void _onRequest() {
    final title = widget.request?.value;
    if (title == null) return;
    _searchCtrl.text = title;
    _focusNode.unfocus();
    setState(() {
      _query = title;
      _openTitle = title;
      _requestCount++;
    });
    widget.request!.value = null;
  }

  @override
  void dispose() {
    widget.request?.removeListener(_onRequest);
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<ReferenceEntry> get _shown {
    if (_query.isNotEmpty) {
      return kReferenceEntries.where((e) => e.matches(_query)).toList();
    }
    return kReferenceEntries.where((e) => e.cat == _category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearching = _query.isNotEmpty;
    final entries = _shown;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reference'),
            Text(
              'Norms & conditions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
        actions: const [ProfileAvatarButton()],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          if (!isSearching) _buildCategoryChips(isDark),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results for "$_query"',
                    subtitle: 'Try a condition name, symptom, or abbreviation',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: entries.length,
                    itemBuilder: (_, i) =>
                        _buildEntry(entries[i], isDark, isSearching),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: (v) => setState(() => _query = v.trim()),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                      _focusNode.unfocus();
                    },
                    child: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: Color(0xFF8E8E93),
                    ),
                  )
                : null,
            hintText: 'Search conditions, norms, formulas…',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: kReferenceCategories.map((cat) {
          final selected = cat == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? kPrimary
                    : (isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? kPrimary
                      : (isDark
                            ? const Color(0xFF48484A)
                            : const Color(0xFFD1D1D6)),
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6E6E73)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntry(ReferenceEntry e, bool isDark, bool showCategoryBadge) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('reference-entry-${e.title}-$_requestCount'),
            initiallyExpanded: e.title == _openTitle,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: primaryOf(context),
            collapsedIconColor: const Color(0xFF8E8E93),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCategoryBadge) ...[
                  _catPill(e.cat),
                  const SizedBox(height: 4),
                ],
                Text(
                  e.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: e.tags.take(4).map((t) => Pill.info(t)).toList(),
                ),
              ],
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Body
                  Text(
                    e.body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark
                          ? const Color(0xFFEBEBEB)
                          : const Color(0xFF3A3A3C),
                    ),
                  ),
                  // Code block
                  if (e.code != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kOkBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.code!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13.5,
                          color: kOkText,
                        ),
                      ),
                    ),
                  ],
                  // Bullets
                  if (e.bullets != null) ...[
                    const SizedBox(height: 8),
                    ...e.bullets!.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5, right: 8),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: kPrimary.withAlpha(180),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isDark
                                      ? const Color(0xFFD1D1D6)
                                      : const Color(0xFF3A3A3C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Management
                  if (e.management != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 13,
                            color: primaryOf(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.management!,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: isDark
                                    ? const Color(0xFFD1D1D6)
                                    : const Color(0xFF3A3A3C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catPill(String cat) {
    return switch (cat) {
      'Vergence anomalies' => Pill.normal(cat),
      'Accommodative anomalies' => Pill.purple(cat),
      'Strabismus' => Pill.info(cat),
      'Norms' => Pill.warn(cat),
      'Tests' => Pill(cat, bg: kBadgeBlueBg, fg: kBadgeBlueText),
      'Formulas' => Pill(
        cat,
        bg: const Color(0xFFEEEDFE),
        fg: const Color(0xFF3C3489),
      ),
      _ => Pill.info(cat),
    };
  }
}
