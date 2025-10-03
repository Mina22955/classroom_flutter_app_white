import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _logoMoveAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale: pop-in and slightly grow while moving up
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    // Logo vertical movement upwards (in pixels)
    _logoMoveAnimation = Tween<double>(
      begin: 0.0,
      end: -36.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutQuad,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();

    // Wait a bit then start text animation
    await Future.delayed(const Duration(milliseconds: 500));
    await _textController.forward();

    // Wait a bit more then navigate to login
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7FAFF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Soft blobs and caps
          Positioned(
            left: -30,
            top: 60,
            child: _blob(120, const Color(0xFF0A84FF).withOpacity(0.20)),
          ),
          Positioned(
            right: -40,
            bottom: -20,
            child: _blob(160, const Color(0xFF007AFF).withOpacity(0.18)),
          ),
          Positioned(
            right: 24,
            top: 90,
            child: Icon(Icons.school,
                color: const Color(0xFF0A84FF).withOpacity(0.14), size: 40),
          ),
          Positioned(
            left: 30,
            bottom: 120,
            child: Icon(Icons.school,
                color: const Color(0xFF0A84FF).withOpacity(0.14), size: 28),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation: move up while scaling
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _logoMoveAnimation.value),
                      child: Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0A84FF),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF0A84FF).withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Animated text
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return _buildHandwritingText();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          radius: 0.9,
        ),
      ),
    );
  }

  Widget _buildHandwritingText() {
    const text = "Aamana classroom";

    // Use a connected script font and reveal the text smoothly from left to right
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: _textAnimation.value.clamp(0.0, 1.0),
        child: Text(
          text,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 40,
            color: Color(0xFF0A84FF),
            fontFamily: 'WindSong',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.0,
          ),
        ),
      ),
    );
  }
}
