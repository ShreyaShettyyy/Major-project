import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cardController.isAnimating && !_cardController.isCompleted) {
      return Scaffold(backgroundColor: AshWineTheme.bg(context));
    }
    final auth = context.watch<AuthProvider>();
    final isDark = AshWineTheme.isDark(context);

    return Scaffold(
      body: Container(
        decoration: AshWineTheme.screenBackgroundDecoration(context),
        child: Stack(
          children: [
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
                        // Back button & Theme toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AshWineTheme.surface(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AshWineTheme.cardBorder(context)),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: isDark
                                      ? AshWineTheme.champagne
                                      : AshWineTheme.exactAshWine,
                                  size: 16,
                                ),
                              ),
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

                        const SizedBox(height: 28),

                        Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AshWineTheme.textPrimary(context),
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 24),

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
                          child: _emailSent
                              ? Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AshWineTheme.champagne
                                            .withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.mark_email_read_rounded,
                                        color: AshWineTheme.champagne,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Reset Link Sent',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AshWineTheme.textPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Check your email inbox for password reset instructions.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AshWineTheme.textMuted(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AshWineTheme.exactAshWine,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Back to Sign In'),
                                      ),
                                    ),
                                  ],
                                )
                              : Form(
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

                                      if (auth.error != null) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.red
                                                    .withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Colors.redAccent,
                                                  size: 16),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: auth.isLoading
                                              ? null
                                              : _resetPassword,
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'Send Reset Link',
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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