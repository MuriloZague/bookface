import 'package:flutter/material.dart';

import '../theme.dart';
import 'login_screen.dart';

/// Splash art animada. Mostra o logo do "bookface" com animação de
/// fade + escala e, ao terminar, navega para a tela de login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _wordmarkController;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;

  @override
  void initState() {
    super.initState();

    // Animação do logo: aparece com um "pop" (escala + fade).
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    // Animação do wordmark "bookface": sobe suavemente com fade.
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordmarkFade = CurvedAnimation(
      parent: _wordmarkController,
      curve: Curves.easeIn,
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _wordmarkController,
      curve: Curves.easeOut,
    ));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _logoController.forward();
    await _wordmarkController.forward();
    // Segura o logo por um instante antes de trocar de tela.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondary) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _wordmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            // Logo + wordmark centralizados.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const _BookfaceLogo(size: 120),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _wordmarkSlide,
                    child: FadeTransition(
                      opacity: _wordmarkFade,
                      child: const Text(
                        'bookface',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rodapé com marca, estilo apps de rede social.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: FadeTransition(
                  opacity: _wordmarkFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'de',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Murilo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo desenhado do "bookface": um círculo branco com um "b"
/// estilizado (lembra o "f" do Facebook).
class _BookfaceLogo extends StatelessWidget {
  const _BookfaceLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'b',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.7,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
