import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/translation_provider.dart';
import 'sign_language_player_screen.dart';
import 'platform_kiosk_screen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _dispatchTrainNumCtrl = TextEditingController(text: '0245');
  final TextEditingController _dispatchTrainNameCtrl = TextEditingController(text: 'Rajdhani Express');
  final TextEditingController _dispatchPlatformCtrl = TextEditingController(text: '2');
  final TextEditingController _dispatchCustomNoteCtrl = TextEditingController();
  String _dispatchEventType = 'arrival';
  int _simLabSubTab = 0; // 0 for YouTube, 1 for Video Upload

  final List<Map<String, String>> _stations = [
    {'code': 'MAQ', 'name': 'Mangaluru Central', 'sub': 'Dakshina Kannada / Southern Railway (SR)'},
    {'code': 'MAJN', 'name': 'Mangaluru Junction', 'sub': 'Dakshina Kannada / Southern Railway (SR)'},
    {'code': 'KBPR', 'name': 'Kabaka Puttur', 'sub': 'Dakshina Kannada / South Western Railway (SWR)'},
    {'code': 'UD', 'name': 'Udupi', 'sub': 'Coastal Karnataka / Konkan Railway (KR)'},
    {'code': 'SBC', 'name': 'KSR Bengaluru City Junction', 'sub': 'South Western Railway (SWR)'},
    {'code': 'MYS', 'name': 'Mysuru Junction', 'sub': 'South Western Railway (SWR)'},
    {'code': 'UBL', 'name': 'SSS Hubballi Junction', 'sub': 'South Western Railway (SWR)'},
    {'code': 'KLBG', 'name': 'Kalaburagi Junction', 'sub': 'Central Railway (CR)'},
    {'code': 'BGM', 'name': 'Belagavi', 'sub': 'South Western Railway (SWR)'},
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<TranslationProvider>();
    if (provider.youtubeUrl.isNotEmpty) {
      _youtubeController.text = provider.youtubeUrl;
    } else {
      _youtubeController.text = '';
    }
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _textController.dispose();
    _dispatchTrainNumCtrl.dispose();
    _dispatchTrainNameCtrl.dispose();
    _dispatchPlatformCtrl.dispose();
    _dispatchCustomNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AshWineTheme.screenBackgroundDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar with Station Selector
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _buildHeader(provider),
                ),
              ),

              // Mode Selector: Audio/Video Upload vs YouTube Audio vs Karnataka Presets vs Direct
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _buildModeTabs(provider),
                ),
              ),

              // Scrollable Content Body
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mode-Specific Input View
                          if (provider.inputMode == AnnouncementInputMode.quickDispatch)
                            _buildQuickDispatchSection(provider)
                          else if (provider.inputMode == AnnouncementInputMode.presets)
                            _buildKarnatakaPresetsSection(provider)
                          else if (provider.inputMode == AnnouncementInputMode.text)
                            _buildTextInputSection(provider)
                          else
                            _buildSimulationLabSection(provider),

                          const SizedBox(height: 16),

                          // Processing Indicator
                          if (provider.isProcessing) _buildProcessingCard(provider),

                          // Error Notification if any
                          if (provider.errorMessage != null) _buildErrorCard(provider),

                          // Result Hub: Audio Transcription, Translation & Proper Nouns
                          if (!provider.isProcessing && provider.originalTranscription.isNotEmpty)
                            _buildResultHub(provider),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        border: Border(bottom: BorderSide(color: AshWineTheme.cardBorder(context))),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _showStationPicker(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AshWineTheme.rose : AshWineTheme.exactAshWine.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.train,
                        color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        provider.selectedStationCode,
                        style: TextStyle(
                          color: isDark ? Colors.white : AshWineTheme.exactAshWine,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          provider.selectedStationName,
                          style: TextStyle(
                            color: AshWineTheme.textPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: isDark ? AshWineTheme.rose : AshWineTheme.mauve,
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      'Railway Public Address',
                      style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Launch Platform Kiosk Screen
              IconButton(
                tooltip: 'Platform Digital Signboard (Kiosk Display)',
                icon: Icon(
                  Icons.tv,
                  color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
                ),
              ),
              // Theme switcher
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return IconButton(
                    tooltip: settings.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                    icon: Icon(
                      settings.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                      color: settings.isDarkMode ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                      size: 20,
                    ),
                    onPressed: () => settings.toggleDarkMode(!settings.isDarkMode),
                  );
                },
              ),
              IconButton(
                tooltip: 'Station information',
                icon: Icon(
                  Icons.info_outline,
                  color: isDark ? AshWineTheme.rose : AshWineTheme.exactAshWine,
                  size: 20,
                ),
                onPressed: () => _showStationPicker(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs(TranslationProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Row(
        children: [
          _tabPill(
            label: 'Quick Dispatch',
            icon: Icons.bolt,
            isSelected: provider.inputMode == AnnouncementInputMode.quickDispatch,
            onTap: () => provider.setInputMode(AnnouncementInputMode.quickDispatch),
          ),
          _tabPill(
            label: 'Presets',
            icon: Icons.bookmark_added_outlined,
            isSelected: provider.inputMode == AnnouncementInputMode.presets,
            onTap: () => provider.setInputMode(AnnouncementInputMode.presets),
          ),
          _tabPill(
            label: 'Live PA / Text',
            icon: Icons.edit_note,
            isSelected: provider.inputMode == AnnouncementInputMode.text,
            onTap: () => provider.setInputMode(AnnouncementInputMode.text),
          ),
          _tabPill(
            label: 'Simulation Lab',
            icon: Icons.science_outlined,
            isSelected: provider.inputMode == AnnouncementInputMode.simulation ||
                provider.inputMode == AnnouncementInputMode.youtube ||
                provider.inputMode == AnnouncementInputMode.video,
            onTap: () => provider.setInputMode(AnnouncementInputMode.simulation),
          ),
        ],
      ),
    );
  }

  Widget _tabPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AshWineTheme.isDark(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AshWineTheme.textSecondary(context),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AshWineTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// STATION MASTER QUICK DISPATCH SECTION
  Widget _buildQuickDispatchSection(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    final quickTrains = [
      {'num': '0245', 'name': 'Rajdhani Express', 'pf': '2'},
      {'num': '20669', 'name': 'Vande Bharat Express', 'pf': '1'},
      {'num': '16589', 'name': 'Rani Chennamma', 'pf': '4'},
      {'num': '12627', 'name': 'Karnataka Express', 'pf': '1'},
      {'num': '11041', 'name': 'Chennai Express', 'pf': '1'},
    ];

    final eventTypes = [
      {'id': 'arrival', 'label': 'Arriving Shortly', 'icon': Icons.login_rounded},
      {'id': 'departure', 'label': 'Ready for Departure', 'icon': Icons.logout_rounded},
      {'id': 'platform_change', 'label': 'Platform Change', 'icon': Icons.alt_route_rounded},
      {'id': 'delay', 'label': 'Delayed (+15m)', 'icon': Icons.more_time_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AshWineTheme.exactAshWine.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AshWineTheme.champagne.withOpacity(0.5)),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: AshWineTheme.champagne,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Station Master Quick Dispatcher',
                      style: TextStyle(
                        color: AshWineTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Broadcast live accessible announcements & ISL gestures in seconds',
                      style: TextStyle(
                        color: AshWineTheme.textSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Open Kiosk Display button
              OutlinedButton.icon(
                icon: const Icon(Icons.tv, size: 14),
                label: const Text('Kiosk Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                  side: BorderSide(color: AshWineTheme.cardBorder(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Train Chips
          Text(
            'QUICK SELECT TRAIN',
            style: TextStyle(
              color: AshWineTheme.textMuted(context),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickTrains.map((tr) {
                final isSelected = _dispatchTrainNumCtrl.text == tr['num'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${tr['num']} • ${tr['name']}'),
                    selected: isSelected,
                    selectedColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                    backgroundColor: isDark ? const Color(0xFF2C2429) : AshWineTheme.cardBgSecondaryLight,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AshWineTheme.textPrimary(context),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AshWineTheme.champagne : AshWineTheme.cardBorder(context),
                      ),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _dispatchTrainNumCtrl.text = tr['num']!;
                          _dispatchTrainNameCtrl.text = tr['name']!;
                          _dispatchPlatformCtrl.text = tr['pf']!;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Train Number & Platform Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _dispatchTrainNumCtrl,
                  style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Train Number',
                    labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                    hintText: 'e.g. 0245',
                    prefixIcon: const Icon(Icons.numbers, size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF251D22) : AshWineTheme.cardBgSecondaryLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshWineTheme.champagne, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _dispatchPlatformCtrl,
                  style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Platform',
                    labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                    hintText: 'e.g. 2',
                    prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF251D22) : AshWineTheme.cardBgSecondaryLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshWineTheme.champagne, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Train Name Field
          TextField(
            controller: _dispatchTrainNameCtrl,
            style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Train Name / Service',
              labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
              hintText: 'e.g. Rajdhani Express',
              prefixIcon: const Icon(Icons.train, size: 18),
              filled: true,
              fillColor: isDark ? const Color(0xFF251D22) : AshWineTheme.cardBgSecondaryLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshWineTheme.champagne, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),

          const SizedBox(height: 16),

          // Event Type Status Chips
          Text(
            'ANNOUNCEMENT TYPE',
            style: TextStyle(
              color: AshWineTheme.textMuted(context),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eventTypes.map((ev) {
              final isSelected = _dispatchEventType == ev['id'];
              return ChoiceChip(
                avatar: Icon(
                  ev['icon'] as IconData,
                  size: 14,
                  color: isSelected ? Colors.white : AshWineTheme.textSecondary(context),
                ),
                label: Text(ev['label'] as String),
                selected: isSelected,
                selectedColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                backgroundColor: isDark ? const Color(0xFF2C2429) : AshWineTheme.cardBgSecondaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AshWineTheme.textPrimary(context),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AshWineTheme.champagne : AshWineTheme.cardBorder(context),
                  ),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _dispatchEventType = ev['id'] as String;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Dispatch Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: provider.isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.campaign, color: Colors.white, size: 20),
              label: Text(
                provider.isProcessing ? 'Translating & Synthesizing ISL...' : 'Broadcast Announcement & Synthesize ISL',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AshWineTheme.champagne, width: 1.2),
                ),
                elevation: 4,
              ),
              onPressed: provider.isProcessing
                  ? null
                  : () {
                      provider.dispatchTrainAnnouncement(
                        trainNumber: _dispatchTrainNumCtrl.text.trim().isEmpty ? '0245' : _dispatchTrainNumCtrl.text.trim(),
                        trainName: _dispatchTrainNameCtrl.text.trim().isEmpty ? 'Rajdhani Express' : _dispatchTrainNameCtrl.text.trim(),
                        platform: _dispatchPlatformCtrl.text.trim().isEmpty ? '2' : _dispatchPlatformCtrl.text.trim(),
                        eventType: _dispatchEventType,
                        customNote: _dispatchCustomNoteCtrl.text.trim(),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  /// ACOUSTIC BENCHMARK & SIMULATION LAB (YouTube & Video File Ingestion)
  Widget _buildSimulationLabSection(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulation Banner Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF282025) : AshWineTheme.cardBgSecondaryLight,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AshWineTheme.cardBorder(context))),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: AshWineTheme.champagne, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Acoustic Benchmark & Simulation Lab',
                            style: TextStyle(
                              color: AshWineTheme.textPrimary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AshWineTheme.champagne.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AshWineTheme.champagne, width: 0.8),
                            ),
                            child: const Text(
                              'RESEARCH / TESTING',
                              style: TextStyle(
                                color: AshWineTheme.champagne,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Used for evaluating Speech-to-Text accuracy on noisy recorded announcements without a live station mic.',
                        style: TextStyle(
                          color: AshWineTheme.textSecondary(context),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sub-Tab Switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _simLabSubTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _simLabSubTab == 0
                            ? (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AshWineTheme.cardBorder(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link, size: 14, color: _simLabSubTab == 0 ? Colors.white : AshWineTheme.textSecondary(context)),
                          const SizedBox(width: 6),
                          Text(
                            'YouTube URL Simulation',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _simLabSubTab == 0 ? FontWeight.w800 : FontWeight.w500,
                              color: _simLabSubTab == 0 ? Colors.white : AshWineTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _simLabSubTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _simLabSubTab == 1
                            ? (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AshWineTheme.cardBorder(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_file_outlined, size: 14, color: _simLabSubTab == 1 ? Colors.white : AshWineTheme.textSecondary(context)),
                          const SizedBox(width: 6),
                          Text(
                            'Audio/Video File Upload',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _simLabSubTab == 1 ? FontWeight.w800 : FontWeight.w500,
                              color: _simLabSubTab == 1 ? Colors.white : AshWineTheme.textSecondary(context),
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

          // Render Selected Lab Tool
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _simLabSubTab == 0
                ? _buildYouTubeInputSection(provider)
                : _buildVideoUploadSection(provider),
          ),
        ],
      ),
    );
  }

  /// VIDEO UPLOAD SECTION
  Widget _buildVideoUploadSection(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    final hasFile = provider.uploadedVideoName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AshWineTheme.exactAshWine.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack_outlined,
                color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Upload Audio / Video Announcement',
                style: TextStyle(
                  color: AshWineTheme.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: provider.isProcessing ? null : () => _showMediaUploadPicker(provider),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasFile
                      ? (isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine)
                      : AshWineTheme.cardBorder(context),
                  width: hasFile ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    hasFile ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                    size: 34,
                    color: hasFile
                        ? (isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine)
                        : AshWineTheme.textMuted(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasFile ? provider.uploadedVideoName! : 'Select Audio or Video File',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AshWineTheme.textPrimary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasFile ? 'Tap to change file' : 'MP3, WAV, M4A, OGG, MP4, WebM',
                    style: TextStyle(
                      color: AshWineTheme.textMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Two Quick Action Buttons: Audio vs Video
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                    side: BorderSide(color: AshWineTheme.cardBorder(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.mic, size: 16),
                  label: const Text('Audio (.mp3/.wav)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  onPressed: provider.isProcessing ? null : () => _pickAndProcessMedia(provider, isAudio: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AshWineTheme.rose : AshWineTheme.exactAshWine,
                    side: BorderSide(color: AshWineTheme.cardBorder(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text('Video (.mp4)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  onPressed: provider.isProcessing ? null : () => _pickAndProcessMedia(provider, isAudio: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshWineTheme.exactAshWine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.translate, size: 18),
              label: Text(
                provider.isProcessing ? 'Transcribing & Translating...' : 'Transcribe & Generate ISL',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: provider.isProcessing
                  ? null
                  : () => _showMediaUploadPicker(provider),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaUploadPicker(TranslationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AshWineTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Announcement Recording',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AshWineTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.audiotrack, color: AshWineTheme.champagne),
                  title: const Text('Upload Audio File (.mp3, .wav, .m4a)'),
                  subtitle: const Text('Direct acoustic audio transcription', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndProcessMedia(provider, isAudio: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library, color: AshWineTheme.rose),
                  title: const Text('Upload Video File (.mp4, .webm)'),
                  subtitle: const Text('Station video clip', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndProcessMedia(provider, isAudio: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AshWineTheme.mauve),
                  title: const Text('Record with Camera'),
                  subtitle: const Text('Capture live announcement from camera', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndProcessCamera(provider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndProcessMedia(TranslationProvider provider, {required bool isAudio}) async {
    try {
      final picked = await FilePicker.pickFile(
        type: isAudio ? FileType.audio : FileType.video,
      );
      if (picked != null) {
        final ext = picked.extension?.toLowerCase() ??
            (picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : '');
        final allowedAudios = {'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'};
        final allowedVideos = {'mp4', 'mov', 'webm', 'mkv', 'avi'};
        if (isAudio && !allowedAudios.contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFE53935),
                content: Text('Invalid format "${picked.name}". Only audio files (.mp3, .wav, .m4a) are allowed.'),
              ),
            );
          }
          return;
        } else if (!isAudio && !allowedVideos.contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFE53935),
                content: Text('Invalid format "${picked.name}". Only video files (.mp4, .mov, .webm) are allowed.'),
              ),
            );
          }
          return;
        }
        final bytes = await picked.readAsBytes();
        await provider.processVideoFile(bytes, picked.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  Future<void> _pickAndProcessCamera(TranslationProvider provider) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening live camera recorder with words for announcement... Look at the camera!'),
            backgroundColor: AshWineTheme.primaryDark,
          ),
        );
      }
      final res = await ApiService.recordWithCamera(
        token: 'ANNOUNCEMENT',
        category: 'announcements',
        durationSeconds: 4.5,
      );
      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live camera announcement captured successfully! Processing...'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera recording notice: $e')),
        );
      }
    }
  }

  /// YOUTUBE INPUT SECTION
  Widget _buildYouTubeInputSection(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AshWineTheme.exactAshWine.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link,
                color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'YouTube Video Link',
                style: TextStyle(
                  color: AshWineTheme.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // URL Input Field
          TextField(
            controller: _youtubeController,
            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Paste YouTube video link here...',
              hintStyle: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 12),
              filled: true,
              fillColor: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? AshWineTheme.rose : AshWineTheme.exactAshWine,
                size: 18,
              ),
              suffixIcon: IconButton(
                tooltip: 'Paste',
                icon: Icon(
                  Icons.content_paste,
                  color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                  size: 18,
                ),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null && data!.text!.isNotEmpty) {
                    setState(() => _youtubeController.text = data.text!);
                  }
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AshWineTheme.cardBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AshWineTheme.cardBorder(context)),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Process Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshWineTheme.exactAshWine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.translate, size: 18),
              label: const Text(
                'Extract & Translate',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: provider.isProcessing
                  ? null
                  : () {
                      final url = _youtubeController.text.trim();
                      if (url.isNotEmpty) {
                        provider.processYouTube(url);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  /// KARNATAKA PRESETS SECTION
  Widget _buildKarnatakaPresetsSection(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Preset Announcements',
              style: TextStyle(
                color: AshWineTheme.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AshWineTheme.champagne.withOpacity(0.15)
                    : AshWineTheme.cardBgSecondaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Presets',
                style: TextStyle(
                  color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _presetCard(
          title: 'Rajdhani Express (0245)',
          badge: 'Platform 2 • Arrival',
          badgeColor: AshWineTheme.champagne,
          station: 'Mangaluru Central (MAQ)',
          previewText:
              'Train number 0245 Rajdhani Express is arriving on platform number 2. Passengers please take note.',
          onTap: () {
            provider.loadPreset({
              'id': 'ann_rajdhani_exp_maq',
              'station_code': 'MAQ',
              'station_name': 'Mangaluru Central (Dakshina Kannada)',
              'transcription':
                  'May I have your attention please. Train number 0245 Rajdhani Express is arriving on platform number 2. Passengers please take note.',
              'translations': {
                'en':
                    'May I have your attention please. Train number 0245 Rajdhani Express is arriving on platform number 2. Passengers please take note.',
                'hi':
                    'यात्रीगण कृपया ध्यान दें। गाड़ी संख्या 0245 राजधानी एक्सप्रेस प्लेटफार्म नंबर 2 पर आ रही है।',
                'kn':
                    'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಗಾಡಿ ಸಂಖ್ಯೆ 0245 ರಾಜಧಾನಿ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 2 ಕ್ಕೆ ಬರಲಿದೆ.',
                'te':
                    'ప్రయాణికుల దృష్టికి. రైలు నెంబర్ 0245 రాజధాని ఎక్స్‌ప్రెస్ ప్లాట్‌ఫారమ్ నెంబర్ 2 కు చేరుకుంటుంది.',
                'ta':
                    'பயணிகள் கவனத்திற்கு. ரயில் எண் 0245 ராஜ்தானி எக்ஸ்பிரஸ் நடைமேடை எண் 2-க்கு வந்து சேரும்.',
                'mr':
                    'प्रवाशांच्या लक्ष्यासाठी. गाडी क्रमांक 0245 राजधानी एक्सप्रेस प्लॅटफॉर्म क्रमांक 2 वर येत आहे.',
                'bn':
                    'যাত্রীদের মনোযোগ আকর্ষণ করা হচ্ছে। ট্রেন নম্বর 0245 রাজধানী এক্সপ্রেস ২ নম্বর প্ল্যাটফর্মে আসছে।',
                'ml':
                    'യാത്രക്കാരുടെ ശ്രദ്ധയ്ക്ക്. ട്രെയിൻ നമ്പർ 0245 രാജധാനി എക്സ്പ്രസ് പ്ലാറ്റ്ഫോം നമ്പർ 2-ൽ എത്തും.',
                'gu':
                    'યાત્રીઓ ધ્યાન આપો. ટ્રેન નંબર 0245 રાજધાની એક્સપ્રેસ પ્લેટફોર્મ નંબર 2 પર આવી રહી છે.',
              },
              'latin_transliterations': {
                'en': 'May I have your attention please. Train number 0245 Rajdhani Express is arriving on platform number 2. Passengers please take note.',
                'hi': 'Yatriyon kripya dhyan dein. Gaadi sankhya 0245 Rajdhani Express platform number 2 par aa rahi hai.',
                'kn': 'Prayāṇikara gamanakke. Gāḍi saṅkhye 0245 Rājadhāni Express platform saṅkhye 2 kke baralide.',
              },
              'named_entities': [
                {'text': '0245', 'entity_type': 'TRAIN_NUMBER', 'label': 'Train 0245', 'fingerspell': ['0', '2', '4', '5']},
                {'text': 'Rajdhani Express', 'entity_type': 'TRAIN_NAME', 'label': 'Rajdhani Express'},
                {'text': 'Mangaluru Central', 'entity_type': 'STATION', 'label': 'Mangaluru Central'},
                {'text': '2', 'entity_type': 'PLATFORM', 'label': 'Platform 2', 'fingerspell': ['2']}
              ]
            });
          },
        ),
        const SizedBox(height: 10),
        _presetCard(
          title: 'Chennai Express (11041)',
          badge: 'Platform 1 • Arrival',
          badgeColor: AshWineTheme.champagne,
          station: 'Solapur (SUR) / Central',
          previewText:
              'Train 11041 Chennai Express from Mumbai CSMT to Chennai Central via Solapur is shortly arriving on platform number 1.',
          onTap: () {
            provider.loadPreset({
              'id': 'ann_chennai_exp_solapur',
              'station_code': 'SUR',
              'station_name': 'Solapur Railway Station',
              'transcription':
                  'May I have your attention please. Train number 11041 Chennai Express from Mumbai CSMT to Chennai Central via Solapur is shortly arriving on platform number 1. Passengers please take note.',
              'translations': {
                'te':
                    'ప్రయాణికుల దృష్టికి. సోలాపూర్ మీదుగా చెన్నై సెంట్రల్ వెళ్లే చెన్నై ఎక్స్‌ప్రెస్ కొద్దిసేపట్లో ప్లాట్‌ఫారమ్ ನంబರ್ 1 కు చేరుకుంటుంది.',
                'kn':
                    'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಸೋಲಾಪುರ ಮಾರ್ಗವಾಗಿ ಚೆನ್ನೈ ಸೆಂಟ್ರಲ್‌ಗೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 11041 ಚೆನ್ನೈ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 1 ಕ್ಕೆ ಬರಲಿದೆ.',
                'ta':
                    'பயணிகள் கவனத்திற்கு. சோலாப்பூர் வழியாக சென்னை சென்ட்ரல் செல்லும் சென்னை எக்ஸ்பிரஸ் விரைவில் நடைமேடை எண் 1-க்கு வந்து சேரும்.',
                'hi':
                    'यात्रियों का ध्यान आकर्षित किया जाता है। सोलापुर के रास्ते चेन्नई सेंट्रल जाने वाली गाड़ी संख्या 11041 चेन्नई एक्सप्रेस कुछ ही समय में प्लेटफार्म नंबर 1 पर आ रही है।',
                'mr':
                    'प्रवाशांच्या लक्ष्यासाठी. सोलापूर मार्गे चेन्नई सेंट्रलकडे जाणारी 11041 चेन्नई एक्सप्रेस काही वेळात प्लॅटफॉर्म क्रमांक 1 वर येत आहे.',
                'bn':
                    'যাত্রীদের মনোযোগ আকর্ষণ করা হচ্ছে। সোলাপুর হয়ে চেন্নাই সেন্ট্রালগামী ১১০৪১ চেন্নাই এক্সপ্রেস কিছুক্ষণের মধ্যে ১ নম্বর প্ল্যাটফর্মে আসছে।',
                'ml':
                    'യാത്രക്കാരുടെ ശ്രദ്ധയ്ക്ക്. സൊലാപ്പൂർ വഴി ചെന്നൈ സെൻട്രലിലേക്ക് പോകുന്ന 11041 ചെന്നൈ എക്സ്പ്രസ് ഉടൻ പ്ലാറ്റ്ഫോം നമ്പർ 1-ൽ എത്തും.',
                'gu':
                    'યાત્રીઓ ધ્યાન આપો. સોલાપુર થઈને ચેન્નાઈ સેન્ટ્રલ જતી ગાડી નંબર 11041 ચેન્નાઈ એક્સપ્રેસ થોડા સમયમાં પ્લેટફોર્મ નંબર 1 પર આવી રહી છે.',
                'en':
                    'May I have your attention please. Train number 11041 Chennai Express from Mumbai CSMT to Chennai Central via Solapur is shortly arriving on platform number 1. Passengers please take note.',
              },
              'latin_transliterations': {
                'te': 'Prayāṇikula druṣṭiki. Sōlāpūr mīdugā Chennai Central veḷḷē Chennai Express koddisēpaṭlō platform number 1 ku cērukuṇṭundi.',
                'kn': 'Prayāṇikara gamanakke. Sōlāpura mārgavāgi Chennai Centralge teraḷuva gāḍi saṅkhye 11041 Chennai Express kelavē kṣaṇagaḷalli platform saṅkhye 1 kke baralide.',
                'ta': 'Payaṇigaḷ gavanattiṟku. Sōlāppūr vaḻiyāga Chennai Central sellum Chennai Express viraivil naṭaimēṭai eṇ 1-kku vandhu sērum.',
                'hi': 'Yatriyon ka dhyan aakarshit kiya jaata hai. Solapur ke raaste Chennai Central jaane waali gaadi sankhya 11041 Chennai Express kuch hi samay mein platform number 1 par aa rahi hai.',
              },
              'named_entities': [
                {'text': '11041', 'entity_type': 'TRAIN_NUMBER', 'label': 'Train 11041', 'fingerspell': ['1', '1', '0', '4', '1']},
                {'text': 'Chennai Express', 'entity_type': 'TRAIN_NAME', 'label': 'Chennai Express'},
                {'text': 'Solapur', 'entity_type': 'STATION', 'label': 'Via Solapur'},
                {'text': '1', 'entity_type': 'PLATFORM', 'label': 'Platform 1', 'fingerspell': ['1']}
              ]
            });
          },
        ),
        const SizedBox(height: 10),
        _presetCard(
          title: 'Karnataka Express (12627)',
          badge: 'Platform 1 • Arrival',
          badgeColor: AshWineTheme.rose,
          station: 'KSR Bengaluru (SBC)',
          previewText:
              'Train 12627 Karnataka Express from KSR Bengaluru to New Delhi is arriving shortly on platform number 1.',
          onTap: () {
            provider.loadPreset({
              'id': 'ann_karnataka_exp_arrival',
              'station_code': 'SBC',
              'station_name': 'KSR Bengaluru City Junction',
              'transcription':
                  'May I have your attention please. Train number 12627 Karnataka Express from KSR Bengaluru to New Delhi is arriving shortly on platform number 1.',
              'translations': {
                'kn':
                    'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಕೆಎಸ್ಆರ್ ಬೆಂಗಳೂರಿನಿಂದ ನವದೆಹಲಿಗೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 12627 ಕರ್ನಾಟಕ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 1 ಕ್ಕೆ ಬರಲಿದೆ.',
                'hi':
                    'यात्रियों का ध्यान आकर्षित किया जाता है। गाड़ी संख्या 12627 कर्नाटक एक्सप्रेस प्लेटफार्म नंबर 1 पर आ रही है।',
              },
              'named_entities': [
                {'text': '12627', 'entity_type': 'TRAIN_NUMBER', 'label': 'Train 12627', 'fingerspell': ['1', '2', '6', '2', '7']},
                {'text': 'Karnataka Express', 'entity_type': 'TRAIN_NAME', 'label': 'Train Name'},
                {'text': '1', 'entity_type': 'PLATFORM', 'label': 'Platform 1'},
              ]
            });
          },
        ),
        const SizedBox(height: 10),
        _presetCard(
          title: 'Rani Chennamma (16589)',
          badge: 'Platform 4 • Rescheduled',
          badgeColor: AshWineTheme.champagne,
          station: 'SSS Hubballi (UBL)',
          previewText:
              'Train 16589 Rani Chennamma Express scheduled on platform 2 will now depart from platform number 4.',
          onTap: () {
            provider.loadPreset({
              'id': 'ann_rani_chennamma_platform',
              'station_code': 'UBL',
              'station_name': 'SSS Hubballi Junction',
              'transcription':
                  'Attention passengers. Train number 16589 Rani Chennamma Express scheduled to depart from platform number 2 will now depart from platform number 4.',
              'translations': {
                'kn':
                    'ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 2 ರಿಂದ ಹೊರಡಬೇಕಿದ್ದ ಗಾಡಿ ಸಂಖ್ಯೆ 16589 ರಾಣಿ ಚೆನ್ನಮ್ಮ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಈಗ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 4 ರಿಂದ ಹೊರಡಲಿದೆ.',
                'hi':
                    'यात्रीगण ध्यान दें। प्लेटफार्म नंबर 2 से प्रस्थान करने वाली गाड़ी संख्या 16589 रानी चेन्नम्मा एक्सप्रेस अब प्लेटफार्म नंबर 4 से रवाना होगी।',
              },
              'named_entities': [
                {'text': '16589', 'entity_type': 'TRAIN_NUMBER', 'label': 'Train 16589'},
                {'text': '4', 'entity_type': 'PLATFORM', 'label': 'New Platform 4'},
              ]
            });
          },
        ),
      ],
    );
  }

  Widget _presetCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required String station,
    required String previewText,
    required VoidCallback onTap,
  }) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AshWineTheme.exactAshWine.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AshWineTheme.textPrimary(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.play_circle_outline,
                      color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  previewText,
                  style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CUSTOM TEXT INPUT SECTION
  Widget _buildTextInputSection(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AshWineTheme.exactAshWine.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Input',
            style: TextStyle(
              color: AshWineTheme.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 3,
            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Type or paste railway announcement...',
              hintStyle: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 12),
              filled: true,
              fillColor: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AshWineTheme.cardBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AshWineTheme.cardBorder(context)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshWineTheme.exactAshWine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.translate, size: 16),
              label: const Text('Translate'),
              onPressed: () {
                final txt = _textController.text.trim();
                if (txt.isNotEmpty) {
                  provider.processText(txt);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// PROCESSING CARD
  Widget _buildProcessingCard(TranslationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AshWineTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshWineTheme.rose.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AshWineTheme.rose),
          const SizedBox(height: 14),
          Text(
            provider.processingStatus.isNotEmpty
                ? provider.processingStatus
                : 'Processing...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AshWineTheme.textPrimaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.18) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notice',
                  style: TextStyle(
                    color: isDark ? Colors.red[200] : Colors.red[900],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  provider.errorMessage!,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.red[800],
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// RESULT HUB: Original Announcement, Dynamic Language Tabs, Side-by-Side Translation, and ISL Button
  Widget _buildResultHub(TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    // List of all 9 languages
    final allLangs = [
      {'code': 'kn', 'native': 'ಕನ್ನಡ', 'name': 'Kannada', 'phonetic': 'Kannglish'},
      {'code': 'en', 'native': 'English', 'name': 'English', 'phonetic': 'English'},
      {'code': 'hi', 'native': 'हिन्दी', 'name': 'Hindi', 'phonetic': 'Hinglish'},
      {'code': 'te', 'native': 'తెలుగు', 'name': 'Telugu', 'phonetic': 'Tenglish'},
      {'code': 'ta', 'native': 'தமிழ்', 'name': 'Tamil', 'phonetic': 'Tanglish'},
      {'code': 'ml', 'native': 'മലയാളം', 'name': 'Malayalam', 'phonetic': 'Manglish'},
      {'code': 'mr', 'native': 'मराठी', 'name': 'Marathi', 'phonetic': 'Marathish'},
      {'code': 'bn', 'native': 'বাংলা', 'name': 'Bengali', 'phonetic': 'Banglish'},
      {'code': 'gu', 'native': 'ગુજરાતી', 'name': 'Gujarati', 'phonetic': 'Gujarati'},
    ];

    // Detect input language
    final detectedCode = provider.detectedLanguageCode;

    // Filter out the detected language from translation tabs
    // If input is English: exclude English, Kannada is first
    // If input is Kannada or non-English: exclude that language, English is first!
    List<Map<String, String>> availableTabs;
    if (detectedCode == 'en') {
      availableTabs = allLangs.where((lang) => lang['code'] != 'en').toList();
    } else {
      final englishTab = allLangs.firstWhere((l) => l['code'] == 'en');
      final otherTabs = allLangs.where((l) => l['code'] != 'en' && l['code'] != detectedCode).toList();
      availableTabs = [englishTab, ...otherTabs];
    }

    // Ensure selected targetLanguage is in availableTabs and not the detected language
    final isCurrentValid = availableTabs.any((t) => t['code'] == provider.targetLanguage);
    if (!isCurrentValid || provider.targetLanguage == detectedCode) {
      final defaultTarget = detectedCode == 'en' ? 'kn' : 'en';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setTargetLanguage(defaultTarget);
      });
    }

    final activeLang = allLangs.firstWhere(
      (l) => l['code'] == provider.targetLanguage,
      orElse: () => availableTabs.isNotEmpty ? availableTabs.first : allLangs.first,
    );

    String nativeText = '';
    String latinText = '';

    if (provider.allTranslations.containsKey(activeLang['code'])) {
      final raw = provider.allTranslations[activeLang['code']];
      if (raw is Map) {
        nativeText = raw['native']?.toString() ?? '';
        latinText = raw['latin']?.toString() ?? '';
      } else if (raw is String) {
        nativeText = raw;
      }
    }

    if (nativeText.isEmpty) {
      if (provider.targetLanguage == activeLang['code'] && provider.translatedAnnouncement.isNotEmpty) {
        nativeText = provider.translatedAnnouncement;
        latinText = provider.latinTransliteration;
      } else if (activeLang['code'] == 'en' && provider.originalTranscription.isNotEmpty) {
        nativeText = provider.originalTranscription;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Original Input (Extracted Words from Video / Link / Text)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AshWineTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AshWineTheme.cardBorder(context)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AshWineTheme.exactAshWine.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Extracted Announcement',
                        style: TextStyle(
                          color: AshWineTheme.textPrimary(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Detected: ${provider.getLanguageName(detectedCode).split(' ')[0]}',
                      style: TextStyle(
                        color: AshWineTheme.textMuted(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                provider.originalTranscription,
                style: TextStyle(
                  color: AshWineTheme.textPrimary(context),
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Language Tabs
        Text(
          'Translations',
          style: TextStyle(
            color: AshWineTheme.textPrimary(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal Language Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableTabs.map((l) {
              final isSelected = provider.targetLanguage == l['code'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => provider.setTargetLanguage(l['code']!),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine)
                          : (isDark ? AshWineTheme.surfaceDark : AshWineTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AshWineTheme.rose : AshWineTheme.exactAshWine)
                            : AshWineTheme.cardBorder(context),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${l['native']} (${l['name']})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AshWineTheme.textSecondaryDark : AshWineTheme.textPrimary(context)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Side-by-Side Translation (Native Script on left, Latin phonetic on right)
        _buildSideBySideTranslationCard(
          lang: activeLang,
          nativeText: nativeText,
          latinText: latinText,
          provider: provider,
        ),

        const SizedBox(height: 14),

        // 4. Detected Entities
        if (provider.namedEntities.isNotEmpty) ...[
          Text(
            'Entities Detected',
            style: TextStyle(
              color: AshWineTheme.textPrimary(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.namedEntities.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AshWineTheme.cardDark : AshWineTheme.cardBgSecondaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AshWineTheme.cardBorder(context)),
                ),
                child: Text(
                  '${e['label']}: ${e['text']}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AshWineTheme.textPrimary(context),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ] else ...[
          const SizedBox(height: 8),
        ],

        // 5. Button: View Indian Sign Language (ISL)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AshWineTheme.exactAshWine,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.sign_language, color: Colors.white, size: 20),
            label: const Text(
              'View ISL Signs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignLanguagePlayerScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Displays Native Script and Latin Script Side-by-Side in two equal columns
  Widget _buildSideBySideTranslationCard({
    required Map<String, String> lang,
    required String nativeText,
    required String latinText,
    required TranslationProvider provider,
  }) {
    final isDark = AshWineTheme.isDark(context);
    final isEnglish = lang['code'] == 'en';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Native Script
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AshWineTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: AshWineTheme.exactAshWine.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AshWineTheme.primaryDark : AshWineTheme.cardBgSecondaryLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AshWineTheme.cardBorder(context)),
                      ),
                      child: Text(
                        '${lang['native']} (${lang['name']})',
                        style: TextStyle(
                          color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            size: 18,
                            color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                          ),
                          tooltip: 'Listen',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => provider.speakCustomText(nativeText, lang['code']!),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            size: 16,
                            color: AshWineTheme.textMuted(context),
                          ),
                          tooltip: 'Copy',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: nativeText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied ${lang['name']} translation'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(
                  nativeText.isNotEmpty ? nativeText : 'Translation in progress...',
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right Column: Phonetic Latin Script (Kanglish / Tenglish / Hinglish / etc.)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AshWineTheme.cardBgSecondaryDark : AshWineTheme.cardBgSecondaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: AshWineTheme.exactAshWine.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? AshWineTheme.champagne : AshWineTheme.mauve).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEnglish ? 'English Standard' : '${lang['phonetic']} (Latin)',
                        style: TextStyle(
                          color: isDark ? AshWineTheme.champagne : AshWineTheme.mauve,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        size: 16,
                        color: AshWineTheme.textMuted(context),
                      ),
                      tooltip: 'Copy',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        final txt = latinText.isNotEmpty ? latinText : nativeText;
                        Clipboard.setData(ClipboardData(text: txt));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied ${lang['phonetic']} text'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(
                  latinText.isNotEmpty ? latinText : (isEnglish ? nativeText : 'Phonetic text generated...'),
                  style: TextStyle(
                    color: AshWineTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStationPicker(BuildContext context, TranslationProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AshWineTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Karnataka Railway Station',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AshWineTheme.textPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AshWineTheme.textMuted(context)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._stations.map((st) {
                final isSelected = st['code'] == provider.selectedStationCode;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isSelected ? AshWineTheme.primaryDark : null,
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AshWineTheme.cardDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AshWineTheme.cardBorderDark),
                    ),
                    child: Text(
                      st['code']!,
                      style: TextStyle(
                        color: isSelected ? AshWineTheme.champagne : AshWineTheme.rose,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    st['name']!,
                    style: TextStyle(
                      color: AshWineTheme.textPrimaryDark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    st['sub']!,
                    style: TextStyle(color: AshWineTheme.textMutedDark, fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AshWineTheme.champagne)
                      : null,
                  onTap: () {
                    provider.setStation(st['code']!, st['name']!);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
