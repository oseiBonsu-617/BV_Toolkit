import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onLogIn,
  });

  final VoidCallback onComplete;
  final VoidCallback onLogIn;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _selectedTools = <String>{'Phoria', 'Vergence', 'Graphical'};
  String _selectedGoal = 'Rank clinical findings faster';
  int _page = 0;

  static const _tools = [
    _OnboardingOption('Phoria', Icons.remove_red_eye_outlined),
    _OnboardingOption('Vergence', Icons.compare_arrows_outlined),
    _OnboardingOption('Accom.', Icons.blur_on_outlined),
    _OnboardingOption('Graphical', Icons.stacked_line_chart_outlined),
    _OnboardingOption('Diagnose', Icons.fact_check_outlined),
    _OnboardingOption('Reference', Icons.menu_book_outlined),
    _OnboardingOption('Patients', Icons.people_outline),
    _OnboardingOption('Sessions', Icons.assignment_outlined),
    _OnboardingOption('Plans', Icons.route_outlined),
  ];

  static const _goals = [
    'Rank clinical findings faster',
    'Keep patient sessions organized',
    'Compare findings with norms',
    'Build diagnosis plans with confidence',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == 2) {
      widget.onComplete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0F0F0F)
        : const Color(0xFFF2F2F7);
    final disabled = _page == 1 && _selectedTools.length < 3;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _page == 0 ? 0 : 1,
                  child: IconButton(
                    onPressed: _page == 0 ? null : _back,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _WelcomePage(isDark: isDark),
                  _ToolsPage(
                    isDark: isDark,
                    selectedTools: _selectedTools,
                    onToggle: (label) {
                      setState(() {
                        if (_selectedTools.contains(label)) {
                          _selectedTools.remove(label);
                        } else {
                          _selectedTools.add(label);
                        }
                      });
                    },
                  ),
                  _GoalsPage(
                    isDark: isDark,
                    selectedGoal: _selectedGoal,
                    onSelect: (goal) => setState(() => _selectedGoal = goal),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                children: [
                  _Dots(current: _page, count: 3),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: disabled ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF303538),
                        disabledBackgroundColor: const Color(0xFFD1D1D6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(_page == 0 ? 'Get Started' : 'Continue'),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _page == 0
                        ? Padding(
                            key: const ValueKey('login-link'),
                            padding: const EdgeInsets.only(top: 18),
                            child: TextButton(
                              onPressed: widget.onLogIn,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF8E8E93)
                                            : const Color(0xFF6E6E73),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Log In',
                                      style: TextStyle(
                                        color: kPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(key: ValueKey('spacer'), height: 42),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        return Padding(
          padding: EdgeInsets.fromLTRB(28, compact ? 4 : 14, 28, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroMark(compact: compact),
              SizedBox(height: compact ? 30 : 42),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'BV Toolkit',
                  style: TextStyle(
                    fontSize: compact ? 46 : 56,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2F3336),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Clinical binocular vision tools for patient assessment, diagnosis, and clear follow-up planning.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.35,
                  color: isDark
                      ? const Color(0xFFAEAEB2)
                      : const Color(0xFF6E6E73),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: compact ? 26 : 40),
              const Text(
                'SWIPE TO DISCOVER MORE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAEAEB2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 174.0 : 210.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE2F4EE),
            ),
            child: const Icon(
              Icons.remove_red_eye_outlined,
              size: 96,
              color: kPrimaryDark,
            ),
          ),
          Positioned(
            right: 14,
            bottom: 18,
            child: Container(
              width: compact ? 58 : 66,
              height: compact ? 58 : 66,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5EA)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.stacked_line_chart_outlined,
                color: Color(0xFF303538),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsPage extends StatelessWidget {
  const _ToolsPage({
    required this.isDark,
    required this.selectedTools,
    required this.onToggle,
  });

  final bool isDark;
  final Set<String> selectedTools;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
      child: Column(
        children: [
          Text(
            'Which tools matter most in your clinic?',
            style: TextStyle(
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF2F3336),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Text(
            'Choose at least three so BV Toolkit opens around your workflow.',
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3A3A3C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 34),
          GridView.builder(
            itemCount: _OnboardingScreenState._tools.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final option = _OnboardingScreenState._tools[index];
              return _ToolTile(
                option: option,
                selected: selectedTools.contains(option.label),
                isDark: isDark,
                onTap: () => onToggle(option.label),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.option,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final _OnboardingOption option;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? const Color(0xFFEAF8F2) : Colors.white;
    return Material(
      color: selected
          ? const Color(0xFF303538)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF303538)
                  : (isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 31,
                color: selected
                    ? selectedColor
                    : (isDark ? Colors.white : const Color(0xFF303538)),
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  option.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? selectedColor
                        : (isDark ? Colors.white : const Color(0xFF303538)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({
    required this.isDark,
    required this.selectedGoal,
    required this.onSelect,
  });

  final bool isDark;
  final String selectedGoal;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
      child: Column(
        children: [
          Text(
            'What do you want BV Toolkit to help with?',
            style: TextStyle(
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF2F3336),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          ..._OnboardingScreenState._goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GoalTile(
                label: goal,
                selected: selectedGoal == goal,
                isDark: isDark,
                onTap: () => onSelect(goal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF303538)
          : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF303538)
                  : (isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA)),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF242628)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 10 : 9,
          height: active ? 10 : 9,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF303538) : const Color(0xFFD8D8DD),
          ),
        );
      }),
    );
  }
}

class _OnboardingOption {
  final String label;
  final IconData icon;

  const _OnboardingOption(this.label, this.icon);
}
