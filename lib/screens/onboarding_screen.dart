import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/tools.dart';
import '../services/preferences_service.dart';
import '../widgets/shortcut_grid.dart';
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
  final _selected = List<String>.of(kDefaultShortcuts);
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_page == 1) {
      await context.read<PreferencesService>().setHomeShortcuts(_selected);
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
    final disabled = _page == 1 && _selected.length < kMinShortcuts;

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
                    selected: _selected,
                    onToggle: (id) {
                      setState(() {
                        if (_selected.contains(id)) {
                          _selected.remove(id);
                        } else {
                          _selected.add(id);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                children: [
                  _Dots(current: _page, count: 2),
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
                                    TextSpan(
                                      text: 'Log In',
                                      style: TextStyle(
                                        color: primaryOf(context),
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
                  fontSize: 15,
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
              color: Color(0xFFE4ECF5),
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
    required this.selected,
    required this.onToggle,
  });

  final bool isDark;
  final List<String> selected;
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
          ShortcutGrid(
            selected: selected,
            onToggle: onToggle,
            crossAxisCount: 2,
          ),
        ],
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
