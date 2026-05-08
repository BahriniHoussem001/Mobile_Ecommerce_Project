// lib/views/auth/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late AnimationController _overlayController;

  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _overlayFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _titleFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
        );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    _overlayFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _subtitleController.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    _overlayController.forward();
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient mimicking the draped fabric photo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFD8D0C8), // cool grey top
                  Color(0xFFF0E8DE), // warm cream mid
                  Color(0xFFFAF6F2), // near-white bottom
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Decorative arc — simulates the fabric drape
          Positioned(
            left: -80,
            bottom: 180,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE8DDD2).withOpacity(0.85),
                    const Color(0xFFF5EDE3).withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Subtle second arc
          Positioned(
            left: -140,
            bottom: 60,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDDD3C8).withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Title — upper-centre
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: const Column(
                  children: [
                    Text(
                      'The',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 52,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1B3A6B),
                        height: 1.1,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Atelier',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 58,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1B3A6B),
                        height: 1.0,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Subtitle — bottom
          Positioned(
            bottom: 68,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: const Column(
                children: [
                  Text(
                    'Refined Style for the',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2E4F80),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Modern Era',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3A6B),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fade-to-white transition overlay
          FadeTransition(
            opacity: _overlayFade,
            child: Container(color: const Color(0xFFFAF6F2)),
          ),
        ],
      ),
    );
  }
}
