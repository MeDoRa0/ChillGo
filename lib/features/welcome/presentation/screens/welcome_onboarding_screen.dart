import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/chillgo_brand.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'package:chillgo/features/welcome/domain/repositories/welcome_onboarding_repository.dart';

part '../widgets/welcome_onboarding_screen/welcome_artworks.dart';
part '../widgets/welcome_onboarding_screen/welcome_onboarding_page.dart';
part '../widgets/welcome_onboarding_screen/welcome_progress.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key, required this.welcomeRepository});

  final WelcomeOnboardingRepository welcomeRepository;

  @override
  State<WelcomeOnboardingScreen> createState() =>
      _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  static const _lastPageIndex = 2;

  late final PageController _pageController;
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_currentPage == _lastPageIndex) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isCompleting = true);
    try {
      await widget.welcomeRepository.complete();
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your progress. Try again.'),
        ),
      );
      setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SunshineBackground(
        child: SafeArea(
          child: ResponsiveContent(
            maxWidth: 430,
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPages()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ChillGo',
                    style: TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: ChillGoColors.coral,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_currentPage < _lastPageIndex)
            TextButton(
              onPressed: _isCompleting ? null : _finishOnboarding,
              child: const Text('Skip'),
            ),
        ],
      ),
    );
  }

  Widget _buildPages() {
    return PageView(
      controller: _pageController,
      onPageChanged: (page) => setState(() => _currentPage = page),
      children: const [
        _WelcomeOnboardingPage(
          artwork: _WelcomeBrandArtwork(),
          title: 'Bring your people together',
          description:
              'Turn the group chat into a plan everyone can actually join.',
        ),
        _WelcomeOnboardingPage(
          artwork: _CrewPlanArtwork(),
          title: 'One crew. One clear plan.',
          description:
              'Create a crew, invite friends, and keep every outing easy to find.',
        ),
        _WelcomeOnboardingPage(
          artwork: _LiveMeetupArtwork(),
          title: 'Know when everyone’s close',
          description:
              'Share useful meetup updates without the “where are you?” chaos.',
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final isLastPage = _currentPage == _lastPageIndex;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Column(
        children: [
          _WelcomeProgress(currentPage: _currentPage, pageCount: 3),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCompleting ? null : _advance,
              icon: _isCompleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(isLastPage ? 'Get started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
