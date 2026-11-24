import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../../core/services/api_service.dart';
import '../providers/translation_provider.dart';
import 'platform_kiosk_screen.dart';

class SignLanguagePlayerScreen extends StatefulWidget {
  const SignLanguagePlayerScreen({super.key});

  @override
  State<SignLanguagePlayerScreen> createState() => _SignLanguagePlayerScreenState();
}

class _SignLanguagePlayerScreenState extends State<SignLanguagePlayerScreen> {
  int _activeLetterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final prov = context.read<TranslationProvider>();
        if (!prov.isPlayingISL && prov.islSequence.isNotEmpty) {
          prov.playISL();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final sequence = provider.islSequence;
    final activeIndex = provider.activeGestureIndex.clamp(0, sequence.isEmpty ? 0 : sequence.length - 1);
    final currentItem = sequence.isNotEmpty ? sequence[activeIndex] : null;
    final isProperNoun = currentItem?['type'] == 'proper_noun_group' || currentItem?['is_name'] == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AshWineTheme.surface(context),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AshWineTheme.textPrimary(context),
                  size: 20,
                ),
                onPressed: () {
                  provider.pauseISL();
                  Navigator.of(context).pop();
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AshWineTheme.isDark(context) ? AshWineTheme.primaryDark : AshWineTheme.cardBgSecondaryLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AshWineTheme.cardBorder(context)),
                  ),
                  child: Text(
                    provider.selectedStationCode,
                    style: TextStyle(
                      color: AshWineTheme.isDark(context) ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ISL Gestures',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AshWineTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            Text(
              'Sign Player',
              style: TextStyle(fontSize: 12, color: AshWineTheme.textMuted(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Launch Full-Screen Platform Kiosk',
            icon: Icon(
              Icons.tv,
              color: AshWineTheme.isDark(context) ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Loop gesture sequence',
            icon: Icon(
              Icons.repeat,
              color: provider.isLooping ? AshWineTheme.champagne : AshWineTheme.textMutedDark,
            ),
            onPressed: () => provider.toggleLooping(),
          ),
          IconButton(
            tooltip: 'Attach Custom Sign Video',
            icon: const Icon(Icons.video_library_outlined, color: AshWineTheme.rose),
            onPressed: () => _showAttachCustomVideoDialog(context, provider),
          ),
        ],
      ),
      body: Container(
        decoration: AshWineTheme.screenBackgroundDecoration(context),
        child: sequence.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  // Top Announcement Preview Banner
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: _buildAnnouncementHeader(provider),
                    ),
                  ),

                  // Main Gesture & Fingerspelling Display
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (provider.isSequenceCompleted && !provider.isLooping)
                                _buildSequenceCompletedCard(provider)
                              else if (isProperNoun)
                                _buildProperNounFingerspellingCard(currentItem!)
                              else
                                _buildStandardSignCard(currentItem!),

                              const SizedBox(height: 20),

                              // Timeline Step Navigator
                              _buildTimelineNavigator(provider, sequence, activeIndex),

                              const SizedBox(height: 16),

                              // Multilingual Text Synchronizer
                              _buildMultilingualTextSync(provider),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Player Controls (Play, Step, Speed)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: _buildPlaybackControls(provider, sequence.length, activeIndex),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sign_language_outlined, size: 64, color: AshWineTheme.mauve.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No announcement loaded',
            style: TextStyle(color: AshWineTheme.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Load an announcement to view signs',
            style: TextStyle(color: AshWineTheme.textMutedDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementHeader(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AshWineTheme.exactAshWine.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AshWineTheme.primary.withOpacity(0.4) : AshWineTheme.cardBgSecondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign,
              color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.selectedStationName,
                  style: TextStyle(
                    color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.originalTranscription.isNotEmpty
                      ? provider.originalTranscription
                      : provider.translatedAnnouncement,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              provider.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
              color: provider.isSpeaking
                  ? AshWineTheme.champagne
                  : (isDark ? AshWineTheme.rose : AshWineTheme.exactAshWine),
              size: 22,
            ),
            onPressed: () => provider.speakTranslation(),
          ),
        ],
      ),
    );
  }

  /// Displayed when the full announcement gesture sequence has finished playing cleanly.
  /// Prevents infinite looping of the last gesture and gives users replay / review options.
  Widget _buildSequenceCompletedCard(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    final totalSigns = provider.islSequence.length;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? AshWineTheme.cardDark : AshWineTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AshWineTheme.champagne, width: 2),
        boxShadow: [
          BoxShadow(
            color: AshWineTheme.champagne.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AshWineTheme.champagne.withOpacity(0.35),
                  AshWineTheme.primaryDark.withOpacity(0.6),
                ],
              ),
              border: Border.all(color: AshWineTheme.champagne, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.check_circle_outline, size: 44, color: AshWineTheme.champagne),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ANNOUNCEMENT COMPLETE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AshWineTheme.champagne,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All $totalSigns Indian Sign Language gestures have finished.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AshWineTheme.textSecondaryDark : AshWineTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 22),
          // Replay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshWineTheme.champagne,
                foregroundColor: const Color(0xFF26101B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.replay, size: 20, color: Color(0xFF26101B)),
              label: const Text(
                'Replay ISL Announcement',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () => provider.replayISL(),
            ),
          ),
          const SizedBox(height: 10),
          // Step-by-step review button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : AshWineTheme.exactAshWine,
                side: BorderSide(color: AshWineTheme.cardBorder(context), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text(
                'Review From First Sign',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: () => provider.setGestureIndex(0),
            ),
          ),
        ],
      ),
    );
  }

  /// Visual representation for Standard Words (e.g. ATTENTION, TRAIN, PLATFORM, ARRIVE, CHILD)
  Widget _buildStandardSignCard(Map<String, dynamic> item) {
    final isDark = AshWineTheme.isDark(context);
    final label = item['label'] ?? '';
    final description = item['description'] ?? '';
    final iconName = item['icon'] ?? 'sign_language';

    final hasCustom = item['has_custom_video'] == true ||
        (item['custom_video_url'] != null && item['custom_video_url'].toString().isNotEmpty);
    final gifPath = item['custom_gif_url'] ??
        (hasCustom ? item['custom_video_url'].toString().replaceAll('.mp4', '.gif') : null);
    final fullMediaUrl = gifPath != null
        ? Uri.encodeFull(gifPath.toString().startsWith('http') ? gifPath.toString() : '${ApiService.baseUrl}$gifPath')
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AshWineTheme.cardDark : AshWineTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AshWineTheme.cardBorder(context), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AshWineTheme.primaryDark : AshWineTheme.exactAshWine).withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Word & Station Type Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AshWineTheme.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'INDIAN SIGN LANGUAGE (ISL)',
                  style: TextStyle(
                    color: AshWineTheme.rose,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AshWineTheme.champagne.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: AshWineTheme.champagne),
                    const SizedBox(width: 4),
                    Text(
                      '${((item['duration_ms'] ?? 1000) / 1000).toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: AshWineTheme.champagne,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Central Hand Gesture Display: High-Resolution Cinema Display
          if (hasCustom && fullMediaUrl != null) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 480),
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AshWineTheme.champagne, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AshWineTheme.primaryDark.withOpacity(0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    fullMediaUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Center(
                      child: Icon(_getIconForName(iconName), size: 64, color: AshWineTheme.textPrimaryDark),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.videocam, size: 12, color: Colors.greenAccent),
                          SizedBox(width: 4),
                          Text(
                            'AUTHENTIC ISL GESTURE',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AshWineTheme.rose.withOpacity(0.35),
                    AshWineTheme.primaryDark.withOpacity(0.6),
                  ],
                ),
                border: Border.all(color: AshWineTheme.rose.withOpacity(0.6), width: 2),
              ),
              child: Center(
                child: Icon(
                  _getIconForName(iconName),
                  size: 68,
                  color: AshWineTheme.textPrimaryDark,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // High-Visibility English Sign Badge (Guaranteed 100% visible across Light & Dark modes)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF26101B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshWineTheme.champagne, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.translate, size: 14, color: AshWineTheme.champagne),
                    const SizedBox(width: 6),
                    Text(
                      'ENGLISH WORD / GESTURE MEANING',
                      style: TextStyle(
                        color: AshWineTheme.champagne.withOpacity(0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Detailed Gesture Motion Guidance
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AshWineTheme.bgDark.withOpacity(0.5) : AshWineTheme.cardBgSecondaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: AshWineTheme.rose, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: isDark ? AshWineTheme.textSecondaryDark : AshWineTheme.textSecondaryLight,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PROPER NOUN & NAME FINGERSPELLING CARD
  /// Implements letter-by-letter manual fingerspelling (e.g. S-H-R-E-Y-A)
  Widget _buildProperNounFingerspellingCard(Map<String, dynamic> item) {
    final isDark = AshWineTheme.isDark(context);
    final nameText = item['name_text'] ?? item['label'] ?? '';
    final letters = (item['letters'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();

    if (_activeLetterIndex >= letters.length) {
      _activeLetterIndex = 0;
    }

    final currentLetter = letters.isNotEmpty ? letters[_activeLetterIndex] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26101B) : AshWineTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AshWineTheme.entityAmber.withOpacity(isDark ? 0.6 : 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AshWineTheme.entityAmber.withOpacity(isDark ? 0.18 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // NER Proper Noun Highlight Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AshWineTheme.properNounGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.person_pin, size: 15, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'PROPER NOUN / NAME DETECTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AshWineTheme.entityAmber.withOpacity(0.15)
                      : AshWineTheme.cardBgSecondaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Two-Handed ISL',
                  style: TextStyle(
                    color: AshWineTheme.entityAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Name Title
          Text(
            nameText.toUpperCase(),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AshWineTheme.entityAmber,
              letterSpacing: 3.0,
            ),
          ),

          const SizedBox(height: 6),
          Text(
            'Fingerspelling letter-by-letter in Indian Sign Language',
            style: TextStyle(fontSize: 12, color: AshWineTheme.textSecondary(context)),
          ),

          const SizedBox(height: 18),

          // Letter Selector Pills (S - H - R - E - Y - A)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AshWineTheme.bgDark.withOpacity(0.6) : AshWineTheme.cardBgSecondaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(letters.length, (idx) {
                final l = letters[idx];
                final char = l['char'] ?? '';
                final isSelected = idx == _activeLetterIndex;

                return InkWell(
                  onTap: () => setState(() => _activeLetterIndex = idx),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AshWineTheme.properNounGradient : null,
                      color: isSelected
                          ? null
                          : (isDark ? AshWineTheme.surfaceDark : AshWineTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AshWineTheme.entityAmber : AshWineTheme.cardBorder(context),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AshWineTheme.entityAmber.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        char,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AshWineTheme.textSecondaryDark : AshWineTheme.textPrimary(context)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 22),

          // Active Letter ISL Card Display
          if (currentLetter != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AshWineTheme.surfaceDark : AshWineTheme.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AshWineTheme.entityAmber.withOpacity(0.4)
                      : AshWineTheme.cardBorder(context),
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: AshWineTheme.exactAshWine.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final letterChar = (currentLetter['char'] ?? '').toString().toUpperCase();
                      final isLetterDigit = RegExp(r'^[0-9]$').hasMatch(letterChar);
                      final letterGifUrl = isLetterDigit
                          ? Uri.encodeFull('${ApiService.baseUrl}/assets/isl_dataset/numbers/$letterChar.gif')
                          : Uri.encodeFull('${ApiService.baseUrl}/assets/isl_dataset/alphabet/$letterChar.gif');

                      return Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        width: double.infinity,
                        height: 280,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AshWineTheme.entityAmber, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AshWineTheme.entityAmber.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          letterGifUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              letterChar,
                              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AshWineTheme.entityAmber),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AshWineTheme.properNounGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            currentLetter['char'] ?? '',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Letter ${currentLetter['char']} (ISL Sign)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AshWineTheme.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentLetter['handshape'] ?? 'Two-handed Sign',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AshWineTheme.champagne,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AshWineTheme.cardBorderDark),
                  const SizedBox(height: 8),
                  Text(
                    currentLetter['description'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AshWineTheme.textSecondaryDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AshWineTheme.entityAmber,
                          side: const BorderSide(color: AshWineTheme.entityAmber),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Prev Letter'),
                        onPressed: _activeLetterIndex > 0
                            ? () => setState(() => _activeLetterIndex--)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AshWineTheme.entityAmber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Next Letter'),
                        onPressed: _activeLetterIndex < letters.length - 1
                            ? () => setState(() => _activeLetterIndex++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sequential step timeline navigator
  Widget _buildTimelineNavigator(TranslationProvider provider, List<Map<String, dynamic>> seq, int active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sign Sequence Progression',
              style: TextStyle(
                color: AshWineTheme.textPrimaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Step ${active + 1} of ${seq.length}',
              style: const TextStyle(
                color: AshWineTheme.champagne,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: seq.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final item = seq[idx];
              final isCurrent = idx == active;
              final isName = item['is_name'] == true || item['type'] == 'proper_noun_group';
              final label = item['name_text'] ?? item['label'] ?? '';

              return InkWell(
                onTap: () => provider.setGestureIndex(idx),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (isName ? AshWineTheme.entityAmber : AshWineTheme.primaryLight)
                        : AshWineTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? (isName ? AshWineTheme.entityAmber : AshWineTheme.rose)
                          : AshWineTheme.cardBorderDark,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isName) ...[
                        Icon(
                          Icons.person,
                          size: 14,
                          color: isCurrent ? Colors.white : AshWineTheme.entityAmber,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                          color: isCurrent
                              ? Colors.white
                              : (isName ? AshWineTheme.entityAmber : AshWineTheme.textSecondaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Multilingual Text Synchronizer
  Widget _buildMultilingualTextSync(TranslationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AshWineTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshWineTheme.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.translate, size: 16, color: AshWineTheme.champagne),
              SizedBox(width: 8),
              Text(
                'Multilingual Announcement Text',
                style: TextStyle(
                  color: AshWineTheme.champagne,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _textRow('Announcement (English)', provider.originalTranscription.isNotEmpty ? provider.originalTranscription : provider.translatedAnnouncement),
          if (provider.targetLanguage != 'en' && provider.translatedAnnouncement.isNotEmpty) ...[
            const SizedBox(height: 8),
            _textRow('${provider.targetLangName} (Target)', provider.translatedAnnouncement),
          ],
        ],
      ),
    );
  }

  Widget _textRow(String lang, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang,
          style: TextStyle(color: AshWineTheme.textMutedDark, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: const TextStyle(color: AshWineTheme.textPrimaryDark, fontSize: 12.5, height: 1.35),
        ),
      ],
    );
  }

  /// Bottom Playback Control Bar
  Widget _buildPlaybackControls(TranslationProvider provider, int total, int activeIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AshWineTheme.surfaceDark,
        border: const Border(top: BorderSide(color: AshWineTheme.cardBorderDark)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Speed Chip
            PopupMenuButton<double>(
              initialValue: provider.playbackSpeed,
              tooltip: 'Playback speed',
              onSelected: (speed) => provider.setPlaybackSpeed(speed),
              color: AshWineTheme.surfaceDark,
              itemBuilder: (_) => [
                _speedItem(0.5),
                _speedItem(0.75),
                _speedItem(1.0),
                _speedItem(1.25),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AshWineTheme.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AshWineTheme.cardBorderDark),
                ),
                child: Text(
                  '${provider.playbackSpeed}x',
                  style: const TextStyle(
                    color: AshWineTheme.champagne,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Navigation Controls: Prev, Play/Pause, Next
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous sign',
                  icon: const Icon(Icons.skip_previous, color: AshWineTheme.textPrimaryDark, size: 28),
                  onPressed: activeIndex > 0 ? () => provider.stepGesture(-1) : null,
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => provider.togglePlayPauseISL(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AshWineTheme.wineHeroGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: AshWineTheme.rose, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AshWineTheme.primaryLight.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        provider.isPlayingISL
                            ? Icons.pause
                            : (provider.isSequenceCompleted ? Icons.replay : Icons.play_arrow),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Next sign',
                  icon: const Icon(Icons.skip_next, color: AshWineTheme.textPrimaryDark, size: 28),
                  onPressed: activeIndex < total - 1 ? () => provider.stepGesture(1) : null,
                ),
              ],
            ),

            // Loop Toggle
            IconButton(
              tooltip: 'Loop',
              icon: Icon(
                Icons.repeat,
                color: provider.isLooping ? AshWineTheme.champagne : AshWineTheme.textMutedDark,
              ),
              onPressed: () => provider.toggleLooping(),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<double> _speedItem(double val) {
    return PopupMenuItem<double>(
      value: val,
      child: Text(
        '${val}x Speed',
        style: const TextStyle(color: AshWineTheme.textPrimaryDark, fontSize: 13),
      ),
    );
  }

  IconData _getIconForName(String name) {
    switch (name) {
      case 'notifications_active':
        return Icons.notifications_active;
      case 'train':
        return Icons.train;
      case 'crop_portrait':
        return Icons.directions_railway;
      case 'flight_land':
        return Icons.input;
      case 'flight_takeoff':
        return Icons.output;
      case 'schedule':
        return Icons.schedule;
      case 'child_care':
        return Icons.child_care;
      case 'visibility':
        return Icons.visibility;
      case 'verified_user':
        return Icons.verified_user;
      case 'local_police':
        return Icons.local_police;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'login':
        return Icons.forward;
      case 'business':
        return Icons.apartment;
      case 'warning':
        return Icons.warning_amber;
      case 'luggage':
        return Icons.luggage;
      case 'pan_tool':
        return Icons.pan_tool;
      default:
        return Icons.sign_language;
    }
  }

  void _showAttachCustomVideoDialog(BuildContext context, TranslationProvider provider) {
    final activeItem = provider.islSequence.isNotEmpty && provider.activeGestureIndex < provider.islSequence.length
        ? provider.islSequence[provider.activeGestureIndex]
        : null;
    final initialToken = activeItem?['sign_code']?.toString() ?? 'ATTENTION';
    final tokenCtrl = TextEditingController(text: initialToken);
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AshWineTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> recordWithCamera() async {
              try {
                final token = tokenCtrl.text.trim().toUpperCase();
                if (token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a word or token name first (e.g. ATTENTION, TRAIN, S).')),
                  );
                  return;
                }
                setSheetState(() => isUploading = true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening live camera recorder with words for "$token"... Look at the camera!'),
                      backgroundColor: AshWineTheme.primaryDark,
                    ),
                  );
                }
                final res = await ApiService.recordWithCamera(
                  token: token,
                  category: 'words',
                  durationSeconds: 3.5,
                );
                setSheetState(() => isUploading = false);
                if (res['success'] == true) {
                  provider.setCustomVideoUrl(res['video_url']);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gesture for "$token" recorded and saved (muted playback)!'),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  }
                } else {
                  throw Exception(res['error'] ?? 'Camera recording was cancelled.');
                }
              } catch (e) {
                setSheetState(() => isUploading = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Camera notice: $e')),
                  );
                }
              }
            }

            Future<void> pickFromGallery() async {
              try {
                final token = tokenCtrl.text.trim().toUpperCase();
                final picked = await FilePicker.pickFile(
                  type: FileType.video,
                );
                if (picked != null) {
                  final ext = picked.extension?.toLowerCase() ??
                      (picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : '');
                  final allowedVideos = {'mp4', 'mov', 'webm', 'mkv', 'avi'};
                  if (!allowedVideos.contains(ext)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFE53935),
                          content: Text('Invalid format "${picked.name}". Only video files (.mp4, .mov, .webm) are allowed.'),
                        ),
                      );
                    }
                    return;
                  }
                  setSheetState(() => isUploading = true);
                  final bytes = await picked.readAsBytes();
                  final res = await ApiService.uploadCustomGestureVideo(
                    fileBytes: bytes,
                    fileName: '${token.isNotEmpty ? token : "GESTURE"}.mp4',
                    token: token.isNotEmpty ? token : "GESTURE",
                    category: 'words',
                  );
                  setSheetState(() => isUploading = false);
                  provider.setCustomVideoUrl(res['video_url']);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gesture video uploaded for "$token"!'),
                        backgroundColor: AshWineTheme.primaryDark,
                      ),
                    );
                  }
                }
              } catch (e) {
                setSheetState(() => isUploading = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.videocam, color: AshWineTheme.rose, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Record / Attach ISL Gesture',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AshWineTheme.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AshWineTheme.textMutedDark),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Record yourself performing the sign gesture using your camera or upload a video. Videos are automatically muted.',
                    style: TextStyle(fontSize: 12, color: AshWineTheme.textSecondaryDark, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Word / Token Input
                  TextField(
                    controller: tokenCtrl,
                    style: const TextStyle(color: AshWineTheme.textPrimaryDark, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Gesture Sign Word (Token)',
                      labelStyle: const TextStyle(color: AshWineTheme.rose, fontSize: 12),
                      hintText: 'e.g. ATTENTION, MANGALURU, CHILD, MISSING, PUTTUR',
                      hintStyle: const TextStyle(color: AshWineTheme.textMutedDark, fontSize: 11),
                      filled: true,
                      fillColor: AshWineTheme.cardDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AshWineTheme.cardBorderDark),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Camera Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AshWineTheme.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: isUploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 20),
                      label: Text(
                        isUploading ? 'Saving Video...' : 'Record with Camera (Muted)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      onPressed: isUploading ? null : recordWithCamera,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Gallery Pick Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AshWineTheme.champagne,
                        side: const BorderSide(color: AshWineTheme.cardBorderDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.video_library, size: 18),
                      label: const Text('Pick from Device Files / Gallery', style: TextStyle(fontSize: 12.5)),
                      onPressed: isUploading ? null : pickFromGallery,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Muted Audio Notice Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AshWineTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AshWineTheme.cardBorderDark),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, size: 14, color: AshWineTheme.champagne),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Audio is muted during gesture playback for silent visual clarity.',
                            style: TextStyle(fontSize: 11, color: AshWineTheme.champagne),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
