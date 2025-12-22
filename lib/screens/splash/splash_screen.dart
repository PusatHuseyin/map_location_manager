import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/location_provider.dart';
import '../../providers/routes_provider.dart';
import '../../services/database_service.dart';
import '../home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  String _statusMessage = 'Baslatiliyor...';
  double _progress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Rotate animation (continuous)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotateController);

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Database baslat
      await _updateStatus('Veritabani hazirlaniyor...', 0.2);
      await Future.delayed(const Duration(milliseconds: 600));
      await DatabaseService().database;

      // Step 2: Konum izinlerini kontrol et
      await _updateStatus('Konum izinleri kontrol ediliyor...', 0.4);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        final locationProvider = context.read<LocationProvider>();
        final hasPermission = await locationProvider.checkPermissions();

        if (!hasPermission) {
          await _updateStatus('Konum izni bekleniyor...', 0.5);
          await Future.delayed(const Duration(milliseconds: 600));

          final permissionGranted = await locationProvider.checkPermissions();

          if (!permissionGranted) {
            setState(() {
              _statusMessage = 'Konum izni gerekli';
              _hasError = true;
            });
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      // Step 3: Verileri yukle
      await _updateStatus('Veriler yukleniyor...', 0.7);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        final locationProvider = context.read<LocationProvider>();
        final routesProvider = context.read<RoutesProvider>();

        await locationProvider.loadLocations();
        await routesProvider.loadRoutes();
      }

      await _updateStatus('Tamamlandı!', 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Bir hata olustu';
        _hasError = true;
        _progress = 0.0;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _updateStatus(String message, double progress) async {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDark,
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo & App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Animated Map Icon
                        AnimatedBuilder(
                          animation: _rotateAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotateAnimation.value * 0.1,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0.9),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  size: 70,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 48),

                        // App Name with Style
                        const Text(
                          'MAP LOCATION',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3.0,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'MANAGER',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Colors.white70,
                            letterSpacing: 8.0,
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Progress Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Progress Bar
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            width:
                                MediaQuery.of(context).size.width *
                                0.8 *
                                _progress,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Color(0xFFE3F2FD)],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Status Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_hasError)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _statusMessage,
                                key: ValueKey<String>(_statusMessage),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Progress Percentage
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
