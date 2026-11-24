import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../../core/services/api_service.dart';
import '../providers/translation_provider.dart';

/// Platform Kiosk Screen - Style 1: Zen Silk & Morning Mist (Japandi Light)
///
/// Refined, calm, glare-free aesthetic designed for railway terminals:
/// - Porcelain white & bleached linen cards
/// - Muted deep sage green accents
/// - Subtle animated background silk waves that gently breathe
/// - High-clarity Indian Sign Language interpreter frame
/// - Accessible high-visibility Platform & Train Number badges
class PlatformKioskScreen extends StatefulWidget {
  const PlatformKioskScreen({super.key});

  @override
  State<PlatformKioskScreen> createState() => _PlatformKioskScreenState();
}

class _PlatformKioskScreenState extends State<PlatformKioskScreen>
    with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Real-time kiosk clock ticker
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Gentle, calming ambient silk wave motion in background (8s cycle)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _waveController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();

    final trainNumber = provider.namedEntities
            .firstWhere((e) => e['entity_type'] == 'TRAIN_NUMBER', orElse: () => {})['text']
            ?.toString() ??
        '16515';

    final trainName = provider.namedEntities
            .firstWhere((e) => e['entity_type'] == 'TRAIN_NAME', orElse: () => {})['text']
            ?.toString() ??
        'KARWAR EXPRESS';

    final platform = provider.namedEntities
            .firstWhere((e) => e['entity_type'] == 'PLATFORM', orElse: () => {})['text']
            ?.toString() ??
        '1';

    return Scaffold(
      backgroundColor: AshWineTheme.zenBg,
      body: Stack(
        children: [
          // 1. Kinetic Ambient Silk Waves Background Painter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ZenSilkWavePainter(_waveController.value),
                );
              },
            ),
          ),

          // 2. Foreground Kiosk Layout
          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                _buildKioskHeader(provider),

                // Main Display Split View
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 768;
                      if (isWide) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: ISL Sign Animation & Gesture Box
                              Expanded(
                                flex: 6,
                                child: _buildSignPlayerPane(provider),
                              ),
                              const SizedBox(width: 16),
                              // Right: Live Train Status & Multilingual Announcements
                              Expanded(
                                flex: 5,
                                child: _buildAnnouncementPane(provider, trainNumber, trainName, platform),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 420,
                                child: _buildSignPlayerPane(provider),
                              ),
                              const SizedBox(height: 16),
                              _buildAnnouncementPane(provider, trainNumber, trainName, platform),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Bottom Ticker / Accessibility Watermark
                _buildAccessibilityTicker(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskHeader(TranslationProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AshWineTheme.zenCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshWineTheme.zenCardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x082F3E3B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding & Station Information
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AshWineTheme.zenCardSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AshWineTheme.zenSage.withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  color: AshWineTheme.zenSage,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SignBridge',
                        style: TextStyle(
                          color: AshWineTheme.zenTextDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•  Indian Sign Language Railway Terminal',
                        style: TextStyle(
                          color: AshWineTheme.zenTextMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AshWineTheme.zenCardSecondary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AshWineTheme.zenSage.withOpacity(0.3)),
                        ),
                        child: Text(
                          provider.selectedStationCode,
                          style: const TextStyle(
                            color: AshWineTheme.zenSage,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Warm porcelain white, bleached linen cards, soft sage green, and ethereal flowing silk waves',
                    style: TextStyle(
                      color: AshWineTheme.zenTextMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Live Clock & Exit Controls
          Row(
            children: [
              // Active System Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AshWineTheme.zenCardSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AshWineTheme.zenSage.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AshWineTheme.zenSage,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active System • 24 fps',
                      style: TextStyle(
                        color: AshWineTheme.zenSage,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Live Time Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AshWineTheme.zenBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AshWineTheme.zenCardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AshWineTheme.zenSage, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_currentTime),
                      style: const TextStyle(
                        color: AshWineTheme.zenTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Exit Button
              IconButton(
                icon: const Icon(Icons.fullscreen_exit_rounded, color: AshWineTheme.zenTextMuted, size: 24),
                tooltip: 'Exit Kiosk Display',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignPlayerPane(TranslationProvider provider) {
    final sequence = provider.islSequence;
    final activeIndex = provider.activeGestureIndex.clamp(0, sequence.isEmpty ? 0 : sequence.length - 1);
    final currentItem = sequence.isNotEmpty ? sequence[activeIndex] : null;
    final gestureLabel = currentItem?['token']?.toString() ?? currentItem?['label']?.toString() ?? 'ARRIVING';

    final spokenAudioText = provider.allTranslations['en']?['native'] ??
        (provider.originalTranscription.isNotEmpty ? provider.originalTranscription : 'Train 16515 is arriving on Platform 1');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.zenCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AshWineTheme.zenCardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2F3E3B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Indian Sign Language Interpreter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INDIAN SIGN LANGUAGE INTERPRETER',
                style: TextStyle(
                  color: AshWineTheme.zenTextDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AshWineTheme.zenCardSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'WCAG 2.1 AAA Accessible',
                  style: TextStyle(
                    color: AshWineTheme.zenSage,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Studio Gesture Screen Box
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AshWineTheme.zenBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AshWineTheme.zenCardBorder),
              ),
              child: Builder(
                builder: (context) {
                  // Completion Card (stops loop cleanly)
                  if (provider.isSequenceCompleted && !provider.isLooping) {
                    return _buildKioskAnnouncementCompletedCard(provider);
                  }

                  if (provider.isProcessing || sequence.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: AshWineTheme.zenSage),
                          SizedBox(height: 16),
                          Text(
                            'Synthesizing Indian Sign Language gestures...',
                            style: TextStyle(
                              color: AshWineTheme.zenSage,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final hasCustom = currentItem?['has_custom_video'] == true ||
                      (currentItem?['custom_video_url'] != null && currentItem!['custom_video_url'].toString().isNotEmpty);
                  final gifPath = currentItem?['custom_gif_url'] ??
                      (hasCustom ? currentItem!['custom_video_url'].toString().replaceAll('.mp4', '.gif') : null);
                  final fullMediaUrl = gifPath != null
                      ? Uri.encodeFull(gifPath.toString().startsWith('http') ? gifPath.toString() : '${ApiService.baseUrl}$gifPath')
                      : null;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle studio ambient circular spotlight
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.85),
                          boxShadow: [
                            BoxShadow(
                              color: AshWineTheme.zenCardBorder.withOpacity(0.5),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),

                      // Gesture Video / Animation Frame (BoxFit.contain, uncropped)
                      if (hasCustom && fullMediaUrl != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              fullMediaUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => _buildDefaultPresenterGraphic(gestureLabel),
                            ),
                          ),
                        )
                      else
                        _buildDefaultPresenterGraphic(gestureLabel),

                      // Active Gesture Pill Badge (Center Bottom)
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                          decoration: BoxDecoration(
                            color: AshWineTheme.zenCardSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AshWineTheme.zenSage, width: 1.4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x102F3E3B),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '[ ${gestureLabel.toUpperCase()} ]',
                            style: const TextStyle(
                              color: AshWineTheme.zenSage,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),

                      // Top Token Sequence Tracker
                      Positioned(
                        top: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AshWineTheme.zenCardBorder),
                          ),
                          child: Text(
                            'TOKEN ${activeIndex + 1} OF ${sequence.isEmpty ? 1 : sequence.length}',
                            style: const TextStyle(
                              color: AshWineTheme.zenTextMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Speech Subtitle Banner Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AshWineTheme.zenCardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Speech: "$spokenAudioText"',
                    style: const TextStyle(
                      color: AshWineTheme.zenTextDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Synthesized to ISL',
                  style: TextStyle(
                    color: AshWineTheme.zenTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Playback Control Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AshWineTheme.zenCardSecondary,
                    foregroundColor: AshWineTheme.zenSage,
                    side: BorderSide(color: AshWineTheme.zenSage.withOpacity(0.5), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text(
                    'Replay Gesture',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  onPressed: () => provider.replayISL(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AshWineTheme.zenTextDark,
                    side: const BorderSide(color: AshWineTheme.zenCardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    provider.isPlayingISL ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                    color: AshWineTheme.zenSage,
                  ),
                  label: Text(
                    provider.isPlayingISL ? '1.0x Normal' : 'Paused',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  onPressed: () {
                    if (provider.isPlayingISL) {
                      provider.pauseISL();
                    } else {
                      provider.playISL();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AshWineTheme.zenTextMuted,
                    side: const BorderSide(color: AshWineTheme.zenCardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text(
                    'Expand Screen',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPresenterGraphic(String gestureLabel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AshWineTheme.zenCardSecondary,
            border: Border.all(color: AshWineTheme.zenSage, width: 2),
            boxShadow: [
              BoxShadow(
                color: AshWineTheme.zenSage.withOpacity(0.12),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.sign_language_rounded,
              size: 64,
              color: AshWineTheme.zenSage,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          gestureLabel,
          style: const TextStyle(
            color: AshWineTheme.zenTextDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Natural ISL Movement (24 fps)',
          style: TextStyle(
            color: AshWineTheme.zenTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildKioskAnnouncementCompletedCard(TranslationProvider provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AshWineTheme.zenBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AshWineTheme.zenCardSecondary,
              border: Border.all(color: AshWineTheme.zenSage, width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 48, color: AshWineTheme.zenSage),
          ),
          const SizedBox(height: 16),
          const Text(
            'ANNOUNCEMENT COMPLETE',
            style: TextStyle(
              color: AshWineTheme.zenTextDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All ISL gestures for this announcement concluded.',
            style: TextStyle(
              color: AshWineTheme.zenTextMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AshWineTheme.zenSage,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text(
              'Replay ISL Announcement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            onPressed: () => provider.replayISL(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementPane(
      TranslationProvider provider, String trainNumber, String trainName, String platform) {
    final kannadaText = provider.allTranslations['kn']?['native'] ?? provider.translatedAnnouncement;
    final hindiText = provider.allTranslations['hi']?['native'] ?? '';
    final englishText = provider.allTranslations['en']?['native'] ?? provider.originalTranscription;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.zenCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AshWineTheme.zenCardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2F3E3B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'TRAIN STATUS & ITINERARY',
            style: TextStyle(
              color: AshWineTheme.zenTextDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 14),

          // 1. Train Summary Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AshWineTheme.zenBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshWineTheme.zenCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainName.toUpperCase(),
                  style: const TextStyle(
                    color: AshWineTheme.zenTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Special Superfast Express',
                  style: TextStyle(
                    color: AshWineTheme.zenTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Train No. $trainNumber',
                      style: const TextStyle(
                        color: AshWineTheme.zenSage,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AshWineTheme.zenTextMuted)),
                    const SizedBox(width: 8),
                    const Text(
                      'On Time',
                      style: TextStyle(
                        color: AshWineTheme.zenSage,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. GIANT ASSIGNED PLATFORM BADGE (Exact match to Style 1 Mockup)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AshWineTheme.zenCardSecondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AshWineTheme.zenSage, width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSIGNED PLATFORM',
                      style: TextStyle(
                        color: AshWineTheme.zenSage,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PLATFORM $platform',
                      style: const TextStyle(
                        color: AshWineTheme.zenTextDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  'TRACK $platform',
                  style: const TextStyle(
                    color: AshWineTheme.zenSage,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. ISL SIGNED ENTITY TOKENS BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AshWineTheme.zenBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshWineTheme.zenCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ISL SIGNED ENTITY TOKENS',
                  style: TextStyle(
                    color: AshWineTheme.zenTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _buildSignedTokensList(provider, trainNumber, platform),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4. Multilingual Announcements Preview
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AshWineTheme.zenCardBorder),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _languageAnnouncementBlock(
                      lang: 'ಕನ್ನಡ (State Language)',
                      text: kannadaText,
                      color: const Color(0xFFD97706),
                    ),
                    const Divider(color: AshWineTheme.zenCardBorder, height: 18),
                    if (hindiText.isNotEmpty) ...[
                      _languageAnnouncementBlock(
                        lang: 'हिन्दी (National Language)',
                        text: hindiText,
                        color: AshWineTheme.zenSage,
                      ),
                      const Divider(color: AshWineTheme.zenCardBorder, height: 18),
                    ],
                    _languageAnnouncementBlock(
                      lang: 'English (Station Broadcast)',
                      text: englishText,
                      color: AshWineTheme.zenTextDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 5. Reassurance Footer Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Quiet Kinetic Motion Background',
                style: TextStyle(
                  color: AshWineTheme.zenSage,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Relaxing, glare-free aesthetic designed for passenger well-being',
                style: TextStyle(
                  color: AshWineTheme.zenTextMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSignedTokensList(
      TranslationProvider provider, String trainNumber, String platform) {
    // Collect sequence tokens or create default entity sequence representation
    final sequence = provider.islSequence;
    final activeIndex = provider.activeGestureIndex;

    final tokens = sequence.isNotEmpty
        ? sequence.map((e) => e['token']?.toString() ?? e['label']?.toString() ?? '').toList()
        : ['Attention', 'Train', trainNumber, 'Karwar', 'Arriving', 'Platform $platform'];

    return List.generate(tokens.length, (idx) {
      final token = tokens[idx];
      final isActive = idx == activeIndex && provider.isPlayingISL;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AshWineTheme.zenSage : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AshWineTheme.zenSage : AshWineTheme.zenCardBorder,
            width: 1,
          ),
        ),
        child: Text(
          isActive ? '$token [ACTIVE]' : token,
          style: TextStyle(
            color: isActive ? Colors.white : AshWineTheme.zenTextDark,
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    });
  }

  Widget _languageAnnouncementBlock({
    required String lang,
    required String text,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(
              lang,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          text.isNotEmpty ? text : 'Waiting for announcement...',
          style: const TextStyle(
            color: AshWineTheme.zenTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityTicker(TranslationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.accessible_rounded, color: AshWineTheme.zenSage, size: 15),
              SizedBox(width: 8),
              Text(
                'RPwD Act 2016 Compliant Accessible Indian Railways Visual Information System',
                style: TextStyle(color: AshWineTheme.zenTextMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Text(
            'Style 1: Zen Silk & Morning Mist (Japandi Light)',
            style: TextStyle(
              color: AshWineTheme.zenSage,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders gentle, ethereal, flowing silk waves in the background
class _ZenSilkWavePainter extends CustomPainter {
  final double animationValue;

  _ZenSilkWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Warm stone silk mist (deepest)
    _drawFlowingWave(
      canvas: canvas,
      size: size,
      color: const Color(0x35E8E3DA),
      amplitude: 38,
      frequency: 0.003,
      speedOffset: animationValue * 2 * math.pi,
      yBase: h * 0.76,
    );

    // Layer 2: Pale cashmere contour
    _drawFlowingWave(
      canvas: canvas,
      size: size,
      color: const Color(0x28D9D2C5),
      amplitude: 28,
      frequency: 0.004,
      speedOffset: (animationValue + 0.33) * 2 * math.pi,
      yBase: h * 0.82,
    );

    // Layer 3: Soft mist sage wave
    _drawFlowingWave(
      canvas: canvas,
      size: size,
      color: const Color(0x2284A98C),
      amplitude: 22,
      frequency: 0.005,
      speedOffset: (animationValue + 0.66) * 2 * math.pi,
      yBase: h * 0.88,
    );

    // Layer 4: Muted deep sage accent line
    final path = Path();
    path.moveTo(0, h * 0.92);
    for (double x = 0; x <= w; x += 10) {
      final y = h * 0.92 +
          math.sin(x * 0.006 + animationValue * 2 * math.pi) * 14 +
          math.cos(x * 0.003) * 6;
      path.lineTo(x, y);
    }
    final paintStroke = Paint()
      ..color = const Color(0x2852796F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, paintStroke);
  }

  void _drawFlowingWave({
    required Canvas canvas,
    required Size size,
    required Color color,
    required double amplitude,
    required double frequency,
    required double speedOffset,
    required double yBase,
  }) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, yBase);

    for (double x = 0; x <= size.width; x += 10) {
      final y = yBase +
          math.sin(x * frequency + speedOffset) * amplitude +
          math.cos(x * (frequency * 0.5) + speedOffset * 0.8) * (amplitude * 0.4);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ZenSilkWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
