import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoappp/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  final List<_OnboardingData> _slides = [
    _OnboardingData(
      title: 'Stay Organized',
      subtitle: 'Manage all your tasks in one place. Set priorities, due dates and never miss anything important.',
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      iconData: Icons.task_alt_rounded,
      bubbleIcons: [
        Icons.flag_rounded,
        Icons.calendar_today_rounded,
        Icons.notifications_rounded,
        Icons.label_rounded,
      ],
    ),
    _OnboardingData(
      title: 'Focus & Flow',
      subtitle: 'Use smart focus sessions with auto breaks. Stay in the zone and get more done with less stress.',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      iconData: Icons.timer_rounded,
      bubbleIcons: [
        Icons.bolt_rounded,
        Icons.coffee_rounded,
        Icons.bar_chart_rounded,
        Icons.emoji_events_rounded,
      ],
    ),
    _OnboardingData(
      title: 'Achieve More',
      subtitle: 'Track your progress, build streaks and hit your goals every single day. Your productivity journey starts now.',
      gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      iconData: Icons.rocket_launch_rounded,
      bubbleIcons: [
        Icons.local_fire_department_rounded,
        Icons.star_rounded,
        Icons.trending_up_rounded,
        Icons.military_tech_rounded,
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _fadeController.reset();
      _fadeController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _goToApp();
    }
  }

  void _skip() => _goToApp();

  Future<void> _goToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _fadeController.reset();
                    _fadeController.forward();
                    setState(() => _currentPage = index);
                  },
                  itemCount: _slides.length,
                  itemBuilder: (_, index) => _buildSlide(_slides[index]),
                ),
              ),
              _buildBottomBar(slide),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_slides.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          if (_currentPage < _slides.length - 1)
            GestureDetector(
              onTap: _skip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildSlide(_OnboardingData data) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(data),
            const SizedBox(height: 48),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(_OnboardingData data) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: SizedBox(
        height: 260,
        width: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(data.iconData, size: 52, color: data.gradient[0]),
            ),
            ..._buildBubbles(data),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBubbles(_OnboardingData data) {
    final positions = [
      const Offset(-100, -60),
      const Offset(100, -60),
      const Offset(-100, 60),
      const Offset(100, 60),
    ];

    return List.generate(data.bubbleIcons.length, (i) {
      return Positioned(
        left: 130 + positions[i].dx,
        top: 130 + positions[i].dy,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (i * 150)),
          curve: Curves.elasticOut,
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(data.bubbleIcons[i], size: 22, color: data.gradient[0]),
          ),
        ),
      );
    });
  }

  Widget _buildBottomBar(_OnboardingData data) {
    final isLast = _currentPage == _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: GestureDetector(
        onTap: _nextPage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? 'Get Started' : 'Next',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: data.gradient[0],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                color: data.gradient[0],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData iconData;
  final List<IconData> bubbleIcons;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconData,
    required this.bubbleIcons,
  });
}