import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../home/screens/home_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../translate/providers/translation_provider.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'passenger_login_screen.dart';
import 'station_master_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.initialization;
      if (auth.isLoggedIn && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignBridgeHome()),
        );
      }
    });

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );
    _cardController.forward();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset > 0) {
      _bgController.stop();
    } else {
      if (!_bgController.isAnimating) {
        _bgController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignBridgeHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = AshWineTheme.isDark(context);

    return Scaffold(
      body: Container(
        decoration: AshWineTheme.screenBackgroundDecoration(context),
        child: Stack(
          children: [
            // Ambient Ash Wine floating orbs
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _bgController,
                  builder: (_, __) => CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _AshWineBgPainter(_bgController.value, isDark),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _cardAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(_cardAnimation),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Top Bar with Logo & Theme Switcher
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AshWineTheme.ashWineGradient,
                                    borderRadius: BorderRadius.circular(13),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AshWineTheme.exactAshWine
                                            .withValues(alpha: 0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.sign_language,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'SignBridge',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AshWineTheme.textPrimary(context),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            Consumer<SettingsProvider>(
                              builder: (context, settings, _) {
                                return IconButton(
                                  tooltip: settings.isDarkMode
                                      ? 'Light Mode'
                                      : 'Dark Mode',
                                  icon: Icon(
                                    settings.isDarkMode
                                        ? Icons.light_mode
                                        : Icons.dark_mode_outlined,
                                    color: isDark
                                        ? AshWineTheme.champagne
                                        : AshWineTheme.exactAshWine,
                                    size: 22,
                                  ),
                                  onPressed: () => settings
                                      .toggleDarkMode(!settings.isDarkMode),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Two Distinct Dashboard Portals
                        Text(
                          'Choose Your Portal',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AshWineTheme.textPrimary(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Passenger View & Station Master Console are strictly separated dashboards.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AshWineTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 1. Passenger Portal Card
                        InkWell(
                          onTap: () {
                            context.read<TranslationProvider>().setUserRole(AppUserRole.passenger);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PassengerLoginScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? const LinearGradient(
                                      colors: [Color(0xFF321A2A), Color(0xFF20131B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFFFBF6F8), Color(0xFFF3E7ED)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AshWineTheme.rose.withOpacity(0.5) : AshWineTheme.exactAshWine.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AshWineTheme.exactAshWine,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Text(
                                            'Passenger Portal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                              color: AshWineTheme.textPrimary(context),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AshWineTheme.champagne.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('ALL COMMUTERS', style: TextStyle(color: AshWineTheme.champagne, fontSize: 9.5, fontWeight: FontWeight.w900)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Instant regional translations, destination alerts & ISL signs.',
                                        style: TextStyle(fontSize: 11.5, color: AshWineTheme.textSecondary(context)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AshWineTheme.champagne),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 2. Station Master Console Card
                        InkWell(
                          onTap: () {
                            context.read<TranslationProvider>().setUserRole(AppUserRole.stationMaster);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StationMasterLoginScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF22171E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AshWineTheme.champagne.withOpacity(0.5) : AshWineTheme.cardBorder(context),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AshWineTheme.champagne,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF22171E), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Text(
                                            'Station Master Console',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                              color: AshWineTheme.textPrimary(context),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16A34A).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('STAFF ONLY', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9.5, fontWeight: FontWeight.w900)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Video, audio, YouTube & text dispatch to station displays.',
                                        style: TextStyle(fontSize: 11.5, color: AshWineTheme.textSecondary(context)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AshWineTheme.champagne),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Form Card Header
                        Text(
                          'Direct Account Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AshWineTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AshWineTheme.surface(context),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: AshWineTheme.cardBorder(context)),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : AshWineTheme.exactAshWine
                                        .withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  hint: 'you@example.com',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  isDark: isDark,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _passCtrl,
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePass,
                                  isDark: isDark,
                                  suffix: GestureDetector(
                                    onTap: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                    child: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AshWineTheme.textMuted(context),
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your password';
                                    }
                                    if (v.length < 6) {
                                      return 'At least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                // Error notification
                                if (auth.error != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.red
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded,
                                            color: Colors.redAccent, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 22),

                                // Sign in button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AshWineTheme.exactAshWine,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: auth.isLoading ? null : _login,
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Forgot password
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen()),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: isDark
                                    ? AshWineTheme.champagne
                                    : AshWineTheme.exactAshWine,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Register
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                    color: AshWineTheme.textMuted(context),
                                    fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: isDark
                                        ? AshWineTheme.champagne
                                        : AshWineTheme.exactAshWine,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Guest
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const SignBridgeHome()),
                            ),
                            child: Text(
                              'Continue as Guest',
                              style: TextStyle(
                                  color: AshWineTheme.textMuted(context),
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: AshWineTheme.textPrimary(context),
      ),
      cursorColor:
          isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AshWineTheme.textMuted(context),
          fontSize: 13,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: AshWineTheme.textMuted(context).withValues(alpha: 0.6),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
          size: 18,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor:
            isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AshWineTheme.cardBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AshWineTheme.cardBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AshWineTheme.champagne
                : AshWineTheme.exactAshWine,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _AshWineBgPainter extends CustomPainter {
  final double t;
  final bool isDark;
  _AshWineBgPainter(this.t, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      _Orb(
        cx: size.width * 0.85,
        cy: size.height * 0.12 + math.sin(t * math.pi * 2) * 25,
        r: 150,
        color: (isDark ? AshWineTheme.champagne : AshWineTheme.rose)
            .withValues(alpha: isDark ? 0.08 : 0.12),
      ),
      _Orb(
        cx: size.width * 0.1,
        cy: size.height * 0.45 + math.cos(t * math.pi * 2) * 20,
        r: 130,
        color: AshWineTheme.exactAshWine
            .withValues(alpha: isDark ? 0.25 : 0.08),
      ),
      _Orb(
        cx: size.width * 0.6,
        cy: size.height * 0.85 + math.sin(t * math.pi) * 20,
        r: 140,
        color: (isDark ? AshWineTheme.rose : AshWineTheme.champagne)
            .withValues(alpha: isDark ? 0.08 : 0.10),
      ),
    ];

    for (final orb in orbs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, orb.color.withValues(alpha: 0)],
        ).createShader(
            Rect.fromCircle(center: Offset(orb.cx, orb.cy), radius: orb.r));
      canvas.drawCircle(Offset(orb.cx, orb.cy), orb.r, paint);
    }
  }

  @override
  bool shouldRepaint(_AshWineBgPainter old) =>
      old.t != t || old.isDark != isDark;
}

class _Orb {
  final double cx, cy, r;
  final Color color;
  const _Orb({
    required this.cx,
    required this.cy,
    required this.r,
    required this.color,
  });
}