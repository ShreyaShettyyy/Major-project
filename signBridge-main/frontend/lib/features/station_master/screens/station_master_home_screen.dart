import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/services/api_service.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/passenger_login_screen.dart';
import '../../auth/screens/station_master_login_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../translate/providers/translation_provider.dart';
import '../../translate/screens/platform_kiosk_screen.dart';
import '../../translate/screens/sign_language_player_screen.dart';

class StationMasterHomeScreen extends StatefulWidget {
  const StationMasterHomeScreen({super.key});

  @override
  State<StationMasterHomeScreen> createState() => _StationMasterHomeScreenState();
}

class _StationMasterHomeScreenState extends State<StationMasterHomeScreen> {
  int _activeInputModality = 0; // 0: Video, 1: Audio/Mic, 2: YouTube, 3: Custom Text, 4: Presets
  final TextEditingController _customTextCtrl = TextEditingController();
  final TextEditingController _youtubeCtrl = TextEditingController();
  final TextEditingController _trainNoCtrl = TextEditingController();
  final TextEditingController _trainNameCtrl = TextEditingController();
  final TextEditingController _platformCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  String? _youtubeErrorText;
  bool _isMicActive = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  String _liveSpeechWords = '';

  static const List<String> _quickDestinations = [
    'Thiruvananthapuram Central', 'Karwar', 'Mumbai LTT', 'Subrahmanya Road',
    'Vijayapura', 'KSR Bengaluru', 'Kanniyakumari', 'Madgaon', 'Coimbatore'
  ];

  static const List<Map<String, String>> _verifiedQuickTrains = [
    {'no': '20631', 'name': 'Vande Bharat Express', 'dest': 'Thiruvananthapuram Central'},
    {'no': '16595', 'name': 'Panchaganga Express', 'dest': 'Karwar'},
    {'no': '12620', 'name': 'Matsyagandha Express', 'dest': 'Mumbai LTT'},
    {'no': '56625', 'name': 'Passenger', 'dest': 'Subrahmanya Road'},
    {'no': '16649', 'name': 'Parasuram Express', 'dest': 'Kanniyakumari'},
    {'no': '17378', 'name': 'Vijayapura Express', 'dest': 'Vijayapura'},
    {'no': '10107', 'name': 'Madgaon MEMU Exp', 'dest': 'Mangaluru Central'},
    {'no': '22637', 'name': 'West Coast Superfast', 'dest': 'Mangaluru Central'},
    {'no': '12602', 'name': 'Mangaluru Mail', 'dest': 'MGR Chennai Central'},
    {'no': '22609', 'name': 'Intercity Superfast', 'dest': 'Coimbatore Junction'},
    {'no': '16585', 'name': 'Murdeshwar Express', 'dest': 'Murdeshwar'},
    {'no': '16515', 'name': 'Karwar Express', 'dest': 'Karwar'},
  ];

  bool _isValidYouTubeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(
      r'^(https?:\/\/)?(www\.|m\.)?(youtube\.com\/(watch\?v=|shorts\/|embed\/)|youtu\.be\/)[a-zA-Z0-9_\-]{6,}',
      caseSensitive: false,
    );
    return regex.hasMatch(trimmed);
  }

  void _syncAnnouncementText([String status = 'Arrival']) {
    final trainNo = _trainNoCtrl.text.trim().isNotEmpty ? _trainNoCtrl.text.trim() : '20631';
    final trainName = _trainNameCtrl.text.trim().isNotEmpty ? _trainNameCtrl.text.trim() : 'Vande Bharat Express';
    final dest = _destCtrl.text.trim().isNotEmpty ? _destCtrl.text.trim() : 'Thiruvananthapuram Central';
    final pf = _platformCtrl.text.trim();
    final pfText = pf.isNotEmpty ? 'on platform number $pf' : 'on designated platform (TBA)';
    final provider = context.read<TranslationProvider>();
    final currentStn = provider.stationMasterStationName;

    setState(() {
      if (status == 'Departure') {
        _customTextCtrl.text =
            'May I have your attention please. Train number $trainNo $trainName to $dest is ready for departure at $currentStn $pfText. Passengers please take note.';
      } else if (status == 'Delay 15m') {
        _customTextCtrl.text =
            'Attention passengers. Train number $trainNo $trainName to $dest is running delayed by 15 minutes and will arrive at $currentStn $pfText.';
      } else if (status == 'Platform Change') {
        _customTextCtrl.text =
            'Attention passengers, platform change announcement. Train number $trainNo $trainName to $dest will now arrive at $currentStn $pfText.';
      } else {
        _customTextCtrl.text =
            'May I have your attention please. Train number $trainNo $trainName to $dest is arriving at $currentStn $pfText. Passengers please take note.';
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _customTextCtrl.dispose();
    _youtubeCtrl.dispose();
    _trainNoCtrl.dispose();
    _trainNameCtrl.dispose();
    _platformCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _officialPresets = [
    {
      'trainNo': '20631',
      'trainName': 'Vande Bharat Express',
      'platform': '1',
      'route': 'Mangaluru Central ➔ Thiruvananthapuram Central',
      'dest': 'Thiruvananthapuram Central',
      'status': 'Departure',
      'text': 'May I have your attention please. Train number 20631 Vande Bharat Express from Mangaluru Central to Thiruvananthapuram Central is ready for departure on platform number 1. Passengers please take note.',
    },
    {
      'trainNo': '12620',
      'trainName': 'Matsyagandha Express',
      'platform': '2',
      'route': 'Mangaluru Central ➔ Mumbai LTT (via Konkan Railway)',
      'dest': 'Mumbai LTT',
      'status': 'Departure',
      'text': 'May I have your attention please. Train number 12620 Matsyagandha Express from Mangaluru Central to Lokmanya Tilak Terminus Mumbai is ready for departure on platform number 2.',
    },
    {
      'trainNo': '16595',
      'trainName': 'Panchaganga Express',
      'platform': '1',
      'route': 'KSR Bengaluru ➔ Karwar (via SBHR, KBPR, BNTL, SL, MULK)',
      'dest': 'Karwar',
      'status': 'Arrival',
      'text': 'May I have your attention please. Train number 16595 Panchaganga Express from KSR Bengaluru to Karwar via Subrahmanya Road, Kabaka Puttur, Bantwal, and Surathkal is arriving on platform number 1.',
    },
    {
      'trainNo': '56625',
      'trainName': 'Passenger',
      'platform': '2',
      'route': 'Mangaluru Central ➔ Subrahmanya Road (via DK Rural Halts)',
      'dest': 'Subrahmanya Road',
      'status': 'Arrival',
      'text': 'May I have your attention please. Train number 56625 Passenger from Mangaluru Central to Subrahmanya Road is arriving on platform number 2.',
    },
    {
      'trainNo': '17378',
      'trainName': 'Vijayapura Express',
      'platform': '3',
      'route': 'Mangaluru Central ➔ Vijayapura (via Hassan, Hubballi)',
      'dest': 'Vijayapura',
      'status': 'Departure',
      'text': 'May I have your attention please. Train number 17378 Vijayapura Express from Mangaluru Central to Vijayapura is ready for departure on platform number 3.',
    },
    {
      'trainNo': 'ALERT',
      'trainName': 'Security & Safety Alert',
      'platform': 'ALL',
      'route': 'Station Wide • Universal Commuter Notice',
      'dest': 'All Platforms',
      'status': 'Security Notice',
      'text': 'Security alert. If you notice any suspicious, unclaimed, or unattended baggage on railway premises, please do not touch it. Immediately alert the on-duty Railway Protection Force or call railway helpline 139.',
    },
  ];


  void _showStationMasterDutyStationPicker(BuildContext context, TranslationProvider provider) {
    final stations = ApiService.verifiedDakshinaKannadaStations;
    showModalBottomSheet(
      context: context,
      backgroundColor: AshWineTheme.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: AshWineTheme.champagne, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select Duty Station',
                      style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                Text(
                  'Switch your console duty station to dispatch announcements locally for that station',
                  style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: stations.length,
                    separatorBuilder: (_, __) => Divider(color: AshWineTheme.cardBorder(context), height: 1),
                    itemBuilder: (_, idx) {
                      final st = stations[idx];
                      final isSelected = provider.stationMasterStationCode == st['code'];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${st['name']} (${st['code']})',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AshWineTheme.champagne : AshWineTheme.textPrimary(context),
                          ),
                        ),
                        subtitle: Text('${st['zone']} • Category ${st['category']}'),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AshWineTheme.champagne, size: 20) : null,
                        onTap: () {
                          provider.setStationMasterStation(st['code']!, st['name']!);
                          Navigator.of(ctx).pop();
                          _syncAnnouncementText();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Duty station changed to ${st['name']} (${st['code']})')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrainMasterSelector(BuildContext context, TranslationProvider provider) {
    final allTrains = ApiService.verifiedTrainMasterRecords;
    final currentStn = provider.stationMasterStationCode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AshWineTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filterQuery = '';
        bool onlyMyStation = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTrains = allTrains.where((t) {
              if (onlyMyStation) {
                final stops = (t['dk_stops'] as List<String>?) ?? [];
                if (!stops.contains(currentStn)) return false;
              }
              if (filterQuery.trim().isEmpty) return true;
              final q = filterQuery.trim().toLowerCase();
              final num = t['train_number']?.toString().toLowerCase() ?? '';
              final name = t['train_name']?.toString().toLowerCase() ?? '';
              final orig = t['origin_name']?.toString().toLowerCase() ?? '';
              final dest = t['destination_name']?.toString().toLowerCase() ?? '';
              return num.contains(q) || name.contains(q) || orig.contains(q) || dest.contains(q);
            }).toList();

            final isDark = AshWineTheme.isDark(context);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AshWineTheme.champagne,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.train, color: Color(0xFF231C21), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Train Master Records (33 Verified)',
                                  style: TextStyle(
                                    color: AshWineTheme.textPrimary(context),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Indian Railways authorized trains serving Dakshina Kannada',
                                  style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search train number, name, or station (e.g. 16595, Panchaganga, Karwar)...',
                          hintStyle: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          setModalState(() => filterQuery = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text('All Trains (${allTrains.length})'),
                            selected: !onlyMyStation,
                            selectedColor: AshWineTheme.champagne,
                            onSelected: (val) => setModalState(() => onlyMyStation = false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Stopping at $currentStn'),
                            selected: onlyMyStation,
                            selectedColor: AshWineTheme.champagne,
                            onSelected: (val) => setModalState(() => onlyMyStation = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollCtrl,
                          itemCount: filteredTrains.length,
                          separatorBuilder: (_, __) => Divider(color: AshWineTheme.cardBorder(context), height: 1),
                          itemBuilder: (_, idx) {
                            final t = filteredTrains[idx];
                            final trainNum = t['train_number'] ?? '';
                            final trainName = t['train_name'] ?? '';
                            final orig = t['origin_name'] ?? '';
                            final dest = t['destination_name'] ?? '';
                            final days = t['running_days'] ?? '';
                            final dkStops = (t['dk_stops'] as List<String>?)?.join(', ') ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AshWineTheme.champagne,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  trainNum,
                                  style: const TextStyle(
                                    color: Color(0xFF231C21),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                trainName,
                                style: TextStyle(
                                  color: AshWineTheme.textPrimary(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$orig ➔ $dest',
                                    style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'DK Stops: $dkStops • Runs: $days',
                                    style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 10.5),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () {
                                  _trainNoCtrl.text = trainNum;
                                  _trainNameCtrl.text = trainName;
                                  _destCtrl.text = dest;
                                  _syncAnnouncementText('Arrival');
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Selected Train $trainNum: $trainName')),
                                  );
                                },
                                child: const Text('Use', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final isDark = AshWineTheme.isDark(context);

    return Scaffold(
      backgroundColor: AshWineTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AshWineTheme.surface(context),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AshWineTheme.champagne,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFF231C21), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        'Station Master Console',
                        style: TextStyle(
                          color: AshWineTheme.textPrimary(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF16A34A)),
                        ),
                        child: const Text(
                          '● DISPATCH LIVE',
                          style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${provider.stationMasterStationName} • PA Control',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _showStationMasterDutyStationPicker(context, provider),
                        child: Text(
                          '[Change]',
                          style: TextStyle(color: AshWineTheme.champagne, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                tooltip: settings.isDarkMode ? 'Light Mode' : 'Dark Mode',
                icon: Icon(
                  settings.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                  color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                  size: 20,
                ),
                onPressed: () => settings.toggleDarkMode(!settings.isDarkMode),
              );
            },
          ),
          // Launch Kiosk Button
          IconButton(
            tooltip: 'Launch Platform Signboard Display',
            icon: const Icon(Icons.tv, color: AshWineTheme.champagne, size: 22),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
            ),
          ),
          // Menu Options
          PopupMenuButton<String>(
            tooltip: 'Console Menu',
            icon: Icon(Icons.more_vert, color: AshWineTheme.textPrimary(context)),
            color: AshWineTheme.surface(context),
            onSelected: (val) {
              if (val == 'passenger') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PassengerLoginScreen()),
                );
              } else if (val == 'sign_player') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignLanguagePlayerScreen()),
                );
              } else if (val == 'history') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              } else if (val == 'logout') {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const StationMasterLoginScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sign_player',
                child: Row(
                  children: [
                    Icon(Icons.sign_language, size: 18, color: AshWineTheme.champagne),
                    SizedBox(width: 10),
                    Text('Preview ISL Player'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: AshWineTheme.champagne),
                    SizedBox(width: 10),
                    Text('Broadcast History Log'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'passenger',
                child: Row(
                  children: [
                    Icon(Icons.person_pin_circle_outlined, size: 18, color: AshWineTheme.rose),
                    SizedBox(width: 10),
                    Text('Switch to Passenger Portal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Staff Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Operational Banner
                _buildOperationalBanner(context, provider),

                const SizedBox(height: 18),

                // 5 MODALITY SELECTOR BAR (Prominent, High Visibility)
                Text(
                  'SELECT ANNOUNCEMENT INPUT MODALITY',
                  style: TextStyle(
                    color: AshWineTheme.textMuted(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _buildModalityTabs(context),

                const SizedBox(height: 16),

                // ACTIVE MODALITY VIEW
                _buildActiveModalityContent(context, provider),

                // STAGED ANNOUNCEMENT CARD (IF PENDING REVIEW) OR AWAITING INPUT STATE
                if (provider.hasStagedAnnouncement) ...[
                  const SizedBox(height: 20),
                  _buildStagedAnnouncementCard(context, provider),
                ] else ...[
                  const SizedBox(height: 20),
                  _buildAwaitingInputCard(context),
                ],

                const SizedBox(height: 20),

                // LIVE PLATFORM SIGNBOARD MONITOR CARD
                _buildActivePlatformMonitorCard(context, provider),

                const SizedBox(height: 20),

                // RECENT BROADCAST HISTORY LOG
                _buildBroadcastLogCard(context, provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationalBanner(BuildContext context, TranslationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AshWineTheme.wineHeroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.champagne.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AshWineTheme.primaryDark.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AshWineTheme.champagne.withOpacity(0.6)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.sensors, size: 14, color: AshWineTheme.champagne),
                    SizedBox(width: 6),
                    Text(
                      'SOUTHERN RAILWAY • MAQ CONTROL DESK',
                      style: TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w900, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AshWineTheme.champagne,
                  foregroundColor: const Color(0xFF231C21),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.tv, size: 16),
                label: const Text('Open Kiosk Signboard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Station Public Address & Visual ISL Dispatcher',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Broadcast real-time acoustic announcements translated synchronously to 9 Indian regional languages and Indian Sign Language (ISL) animations on all platform monitors and passenger devices.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildModalityTabs(BuildContext context) {
    final isDark = AshWineTheme.isDark(context);
    final modalities = [
      {'icon': Icons.video_file, 'label': '1. Video Upload (.mp4)'},
      {'icon': Icons.mic, 'label': '2. Audio / Mic Stream'},
      {'icon': Icons.smart_display, 'label': '3. YouTube Link'},
      {'icon': Icons.edit_note, 'label': '4. Custom Text'},
      {'icon': Icons.flash_on, 'label': '5. Station Presets'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modalities.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isSelected = _activeInputModality == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeInputModality = idx),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine)
                      : (isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AshWineTheme.champagne : AshWineTheme.cardBorder(context),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: isSelected ? AshWineTheme.champagne : AshWineTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AshWineTheme.textPrimary(context),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveModalityContent(BuildContext context, TranslationProvider provider) {
    switch (_activeInputModality) {
      case 0:
        return _buildVideoUploadCard(context, provider);
      case 1:
        return _buildAudioMicCard(context, provider);
      case 2:
        return _buildYouTubeCard(context, provider);
      case 3:
        return _buildCustomTextCard(context, provider);
      case 4:
      default:
        return _buildPresetsCard(context, provider);
    }
  }

  void _toggleLiveMic(TranslationProvider provider) async {
    if (!_isMicActive) {
      bool available = false;
      try {
        if (!_speechInitialized) {
          _speechInitialized = await _speech.initialize(
            onStatus: (status) {
              if ((status == 'done' || status == 'notListening') && mounted && _isMicActive) {
                // finished
              }
            },
            onError: (err) {
              debugPrint('Speech error: $err');
            },
          );
        }
        available = _speechInitialized;
      } catch (e) {
        debugPrint('STT init error: $e');
        available = false;
      }

      setState(() {
        _isMicActive = true;
        _liveSpeechWords = '';
      });

      if (available) {
        try {
          await _speech.listen(
            onResult: (result) {
              if (mounted) {
                setState(() {
                  _liveSpeechWords = result.recognizedWords;
                  if (_liveSpeechWords.isNotEmpty) {
                    _customTextCtrl.text = _liveSpeechWords;
                  }
                });
              }
            },
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              cancelOnError: true,
              partialResults: true,
            ),
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live microphone active. Speak your station announcement...')),
        );
      }
    } else {
      try {
        await _speech.stop();
      } catch (_) {}
      setState(() => _isMicActive = false);

      final spoken = _liveSpeechWords.trim().isNotEmpty
          ? _liveSpeechWords.trim()
          : _customTextCtrl.text.trim();

      if (spoken.isNotEmpty) {
        final validation = provider.validateTextRelevance(spoken);
        if (!validation['is_railway']) {
          provider.stageCustomAnnouncement(
            trainNo: '',
            trainName: 'Live Mic Input',
            platform: '',
            destination: '',
            customText: spoken,
            isRailway: false,
            reason: validation['reason']?.toString() ?? 'Non-railway speech detected',
            category: validation['category']?.toString() ?? 'non_railway',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFFE53935),
                content: Text('Warning: Microphone speech contains non-railway content. Held in staging desk.'),
              ),
            );
          }
        } else {
          provider.stageCustomAnnouncement(
            trainNo: '',
            trainName: 'Live Station Mic',
            platform: '',
            destination: '',
            customText: spoken,
            isRailway: true,
            reason: validation['reason']?.toString() ?? 'Verified railway speech',
            category: validation['category']?.toString() ?? 'train_announcement',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone speech captured & staged for Station Master review!')),
            );
          }
        }
      }
    }
  }

  /// 1. VIDEO FILE UPLOAD CARD
  Widget _buildVideoUploadCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.video_library_rounded, color: AshWineTheme.champagne, size: 20),
              SizedBox(width: 8),
              Text(
                'Upload Railway Announcement Video File (.mp4)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upload recorded station CCTV, passenger announcement clips, or briefing videos to transcribe speech, identify train numbers, and generate ISL sequences.',
            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              try {
                final picked = await FilePicker.pickFile(
                  type: FileType.video,
                );
                if (picked != null) {
                  final ext = picked.extension?.toLowerCase() ?? (picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : '');
                  final allowedVideos = {'mp4', 'mov', 'webm', 'mkv', 'avi'};
                  if (!allowedVideos.contains(ext)) {
                    if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].contains(ext)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFE53935),
                          content: Text('Cannot upload audio file "${picked.name}" as video. Please select a video file (.mp4, .mov, .webm, .mkv, .avi) or switch to the Audio Upload tab.'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFE53935),
                          content: Text('Invalid file format "${picked.name}". Only video files (.mp4, .mov, .webm, .mkv, .avi) are allowed.'),
                        ),
                      );
                    }
                    return;
                  }
                  final bytes = await picked.readAsBytes();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Analyzing & transcribing video: ${picked.name}...')),
                  );
                  await provider.processVideoFile(bytes, picked.name);
                  return;
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFE53935),
                      content: Text('Could not access video file: $e'),
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22171E) : AshWineTheme.cardBgSecondaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AshWineTheme.champagne.withOpacity(0.5) : AshWineTheme.exactAshWine.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AshWineTheme.champagne.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: AshWineTheme.champagne, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Click to browse & upload .mp4 video file',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports MP4, MOV, WebM (Speech recognition & train extraction)',
                    style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
          if (provider.isProcessing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AshWineTheme.champagne.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AshWineTheme.champagne),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    provider.processingStatus.isNotEmpty ? provider.processingStatus : 'Analyzing video...',
                    style: const TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          if (provider.uploadedVideoName != null && !provider.isProcessing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AshWineTheme.champagne.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AshWineTheme.champagne, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Processed: ${provider.uploadedVideoName}',
                      style: const TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 2. AUDIO RECORDING / MIC STREAM CARD
  Widget _buildAudioMicCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.mic, color: AshWineTheme.champagne, size: 20),
              SizedBox(width: 8),
              Text(
                'Live Microphone Audio & Station Track Upload',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Speak directly into the station master microphone or upload recorded .wav/.mp3 audio announcements for real-time speech-to-text and ISL gesture translation.',
            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
          ),
          if (_isMicActive) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF38121E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AshWineTheme.rose),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, color: AshWineTheme.champagne, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _liveSpeechWords.isNotEmpty
                          ? 'Listening: "$_liveSpeechWords"'
                          : 'Listening for announcement speech...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              // Microphone Push-to-Talk Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMicActive ? const Color(0xFF8B1E3F) : (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_isMicActive ? Icons.stop_circle : Icons.mic, size: 22),
                  label: Text(
                    _isMicActive ? 'Stop Live Mic & Dispatch' : 'Start Live Mic Speech',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  onPressed: () => _toggleLiveMic(provider),
                ),
              ),
              const SizedBox(width: 12),
              // Real Audio File Upload Button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AshWineTheme.textPrimary(context),
                    side: BorderSide(color: AshWineTheme.cardBorder(context)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.audio_file, color: AshWineTheme.champagne, size: 20),
                  label: const Text(
                    'Upload Audio (.wav/.mp3)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: () async {
                    try {
                      final picked = await FilePicker.pickFile(
                        type: FileType.audio,
                      );
                      if (picked != null) {
                        final ext = picked.extension?.toLowerCase() ?? (picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : '');
                        final allowedAudios = {'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'};
                        if (!allowedAudios.contains(ext)) {
                          if (['mp4', 'mov', 'webm', 'mkv', 'avi'].contains(ext)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFE53935),
                                content: Text('Cannot upload video file "${picked.name}" as audio. Please select an audio file (.mp3, .wav, .m4a, .aac, .ogg, .flac) or switch to the Video Upload tab.'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFE53935),
                                content: Text('Invalid file format "${picked.name}". Only audio files (.mp3, .wav, .m4a, .aac, .ogg, .flac) are allowed.'),
                              ),
                            );
                          }
                          return;
                        }
                        final bytes = await picked.readAsBytes();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Analyzing & transcribing audio: ${picked.name}...')),
                        );
                        await provider.processVideoFile(bytes, picked.name);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFE53935),
                            content: Text('Audio picker error: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. YOUTUBE LINK INGESTION CARD
  Widget _buildYouTubeCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.smart_display_rounded, color: AshWineTheme.rose, size: 20),
              SizedBox(width: 8),
              Text(
                'YouTube Railway Announcement Audio Extraction',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Paste any public railway announcement YouTube link to extract its audio track, transcribe spoken text, and review before broadcasting to passengers.',
            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _youtubeCtrl,
            enabled: !provider.isProcessing,
            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14),
            onChanged: (val) {
              if (_youtubeErrorText != null) {
                setState(() => _youtubeErrorText = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=...',
              errorText: _youtubeErrorText,
              prefixIcon: const Icon(Icons.link, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshWineTheme.champagne)),
            ),
          ),
          const SizedBox(height: 12),

          // Real-time Extraction Progress Display
          if (provider.isProcessing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E1723) : AshWineTheme.cardBgSecondaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AshWineTheme.champagne.withOpacity(0.6), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AshWineTheme.champagne),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Extracting YouTube Audio Stream (~3-8s)...',
                          style: TextStyle(
                            color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.processingStatus.isNotEmpty
                        ? provider.processingStatus
                        : 'Extracting audio stream, running railway speech recognition, and staging for Station Master review...',
                    style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AshWineTheme.champagne),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AshWineTheme.champagne,
                  foregroundColor: const Color(0xFF231C21),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: provider.isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF231C21)),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(
                  provider.isProcessing ? 'Processing YouTube Audio...' : 'Process YouTube Audio',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                onPressed: provider.isProcessing
                    ? null
                    : () {
                        final url = _youtubeCtrl.text.trim();
                        if (url.isEmpty) {
                          setState(() => _youtubeErrorText = 'Please enter a YouTube video URL.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFE53935),
                              content: Text('Please paste a YouTube announcement URL into the box first.'),
                            ),
                          );
                          return;
                        }
                        if (!_isValidYouTubeUrl(url)) {
                          setState(() => _youtubeErrorText = 'Invalid URL. Only YouTube links (youtube.com or youtu.be) are supported.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFE53935),
                              content: Text('Invalid link: Only YouTube video links (youtube.com or youtu.be) are allowed.'),
                            ),
                          );
                          return;
                        }
                        setState(() => _youtubeErrorText = null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading & extracting YouTube audio stream...')),
                        );
                        provider.processYouTube(url);
                      },
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AshWineTheme.textPrimary(context),
                  side: BorderSide(color: AshWineTheme.cardBorder(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.train, size: 16, color: AshWineTheme.champagne),
                label: const Text('Sample Railway Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                onPressed: provider.isProcessing
                    ? null
                    : () {
                        _youtubeCtrl.text = 'https://www.youtube.com/watch?v=20608_VandeBharat_MAQ';
                        setState(() => _youtubeErrorText = null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inserted sample railway link. Tap "Process YouTube Audio" to run.')),
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. CUSTOM TEXT ANNOUNCEMENT CARD
  Widget _buildCustomTextCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note, color: AshWineTheme.champagne, size: 20),
              SizedBox(width: 8),
              Text(
                'Type Custom Public Address Announcement',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Train Master Integration: Direct Search & Select Button
          InkWell(
            onTap: () => _showTrainMasterSelector(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B1D25) : AshWineTheme.cardBgSecondaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AshWineTheme.champagne.withOpacity(0.7), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AshWineTheme.champagne,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.dataset, color: Color(0xFF231C21), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select from Train Master Records (33 Trains)',
                          style: TextStyle(
                            color: AshWineTheme.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Tap to browse all verified Indian Railways trains, routes & stopping halts',
                          style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AshWineTheme.champagne),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Quick Train Name Chips from Verified Trains
          Text(
            'QUICK SELECT VERIFIED TRAIN:',
            style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _verifiedQuickTrains.map((t) {
              final isSelected = _trainNoCtrl.text.trim() == t['no'];
              return ChoiceChip(
                label: Text('${t['no']} ${t['name']}'),
                selected: isSelected,
                selectedColor: AshWineTheme.champagne,
                backgroundColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF231C21) : AshWineTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                onSelected: (_) {
                  _trainNoCtrl.text = t['no']!;
                  _trainNameCtrl.text = t['name']!;
                  _destCtrl.text = t['dest']!;
                  _syncAnnouncementText('Arrival');
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Quick Destination Selector Chips
          Text(
            'QUICK SELECT DESTINATION:',
            style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickDestinations.map((d) {
              final isSelected = _destCtrl.text.trim().toLowerCase() == d.toLowerCase();
              return ChoiceChip(
                label: Text(d),
                selected: isSelected,
                selectedColor: AshWineTheme.champagne,
                backgroundColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF231C21) : AshWineTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                onSelected: (_) {
                  _destCtrl.text = d;
                  final matching = _verifiedQuickTrains.firstWhere(
                    (tr) => tr['dest']!.toLowerCase().contains(d.toLowerCase()) || d.toLowerCase().contains(tr['dest']!.toLowerCase()),
                    orElse: () => _verifiedQuickTrains.first,
                  );
                  _trainNoCtrl.text = matching['no']!;
                  _trainNameCtrl.text = matching['name']!;
                  _syncAnnouncementText('Arrival');
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Quick Preset Template Buttons
          Row(
            children: [
              Text(
                'STATUS TEMPLATES:',
                style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _templateBtn('Arrival', () => _syncAnnouncementText('Arrival')),
                    _templateBtn('Departure', () => _syncAnnouncementText('Departure')),
                    _templateBtn('Delay 15m', () => _syncAnnouncementText('Delay 15m')),
                    _templateBtn('Platform Change', () => _syncAnnouncementText('Platform Change')),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Attributes Row: Train No, Name, Platform, Destination (with live 2-way sync)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _trainNoCtrl,
                  onChanged: (_) => _syncAnnouncementText(),
                  decoration: InputDecoration(
                    labelText: 'Train No.',
                    hintText: 'e.g. 20608',
                    labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _trainNameCtrl,
                  onChanged: (_) => _syncAnnouncementText(),
                  decoration: InputDecoration(
                    labelText: 'Train Name',
                    hintText: 'e.g. Vande Bharat Express',
                    labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _platformCtrl,
                  onChanged: (_) => _syncAnnouncementText(),
                  decoration: InputDecoration(
                    labelText: 'Platform',
                    hintText: 'e.g. 1',
                    labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _destCtrl,
                  onChanged: (_) => _syncAnnouncementText(),
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g. Puttur',
                    labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom Announcement Text Area
          TextField(
            controller: _customTextCtrl,
            maxLines: 3,
            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14, height: 1.35),
            decoration: InputDecoration(
              hintText: 'Type railway announcement (e.g. Train arrival/departure, platform change, missing child or lost item alert)...',
              filled: true,
              fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
            ),
          ),

          const SizedBox(height: 14),

          // Broadcast Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshWineTheme.champagne,
                foregroundColor: const Color(0xFF231C21),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Broadcast Announcement to Platform Displays & Passengers',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
              onPressed: () {
                final text = _customTextCtrl.text.trim();
                final trainNo = _trainNoCtrl.text.trim();
                final trainName = _trainNameCtrl.text.trim();
                final platform = _platformCtrl.text.trim();
                final destination = _destCtrl.text.trim();

                if (text.isEmpty && trainNo.isEmpty && trainName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFE53935),
                      content: Text('Please enter announcement text or train details before broadcasting.'),
                    ),
                  );
                  return;
                }

                final effectiveText = text.isNotEmpty
                    ? text
                    : 'May I have your attention please. Train number ${trainNo.isNotEmpty ? trainNo : "20608"} ${trainName.isNotEmpty ? trainName : "Express"} to ${destination.isNotEmpty ? destination : "Puttur"} is arriving on platform number ${platform.isNotEmpty ? platform : "1"}. Passengers please take note.';

                // Validate relevance
                final validation = provider.validateTextRelevance(effectiveText);
                if (!validation['is_railway']) {
                  provider.stageCustomAnnouncement(
                    trainNo: trainNo,
                    trainName: trainName.isNotEmpty ? trainName : 'Custom Text',
                    platform: platform,
                    destination: destination,
                    customText: effectiveText,
                    isRailway: false,
                    reason: validation['reason']?.toString() ?? 'Non-railway content detected',
                    category: validation['category']?.toString() ?? 'non_railway',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFE53935),
                      content: Text('Warning: Non-railway content detected. Staged for review — direct broadcast blocked.'),
                    ),
                  );
                  return;
                }

                provider.broadcastCustomAnnouncement(
                  trainNo: trainNo,
                  trainName: trainName,
                  platform: platform,
                  destination: destination,
                  originStationCode: provider.stationMasterStationCode,
                  originStationName: provider.stationMasterStationName,
                  customText: effectiveText,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Dispatched ${trainName.isNotEmpty ? trainName : "Announcement"} (Platform ${platform.isNotEmpty ? platform : "1"}) to platform kiosks and passenger screens!',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateBtn(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text('+ $label'),
      backgroundColor: AshWineTheme.cardBgSecondaryLight,
      labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      onPressed: onTap,
    );
  }

  /// 5. STATION OFFICIAL PRESETS CARD
  Widget _buildPresetsCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.flash_on, color: AshWineTheme.champagne, size: 20),
              SizedBox(width: 8),
              Text(
                'Official Station Presets (1-Tap Fast Broadcast)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Instantly dispatch verified railway announcements with zero configuration. Pre-cached across 9 regional languages with synchronized ISL gestures.',
            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Column(
            children: _officialPresets.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF251A22) : AshWineTheme.cardBgSecondaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AshWineTheme.cardBorder(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AshWineTheme.champagne,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p['trainNo']!,
                        style: const TextStyle(color: Color(0xFF231C21), fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p['trainName']!,
                                style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AshWineTheme.champagne.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
                                ),
                                child: Text(
                                  'PF ${p['platform']}',
                                  style: const TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w800, fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p['route']!,
                            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Dispatch', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      onPressed: () {
                        if (p['trainNo'] == '20631') {
                          provider.broadcastVandeBharat20631();
                        } else if (p['trainNo'] == '12620') {
                          provider.broadcastMatsyagandha12620();
                        } else if (p['trainNo'] == '16595') {
                          provider.broadcastPanchaganga16595();
                        } else if (p['trainNo'] == '56625') {
                          provider.broadcastSubrahmanyaPassenger56625();
                        } else if (p['trainNo'] == 'ALERT') {
                          provider.broadcastEmergencySecurityAlert();
                        } else if (p['trainNo'] == '0245') {
                          provider.broadcastVaranasiRajdhani();
                        } else if (p['trainNo'] == '20608') {
                          provider.broadcastPutturVandeBharat();
                        } else {
                          provider.processText(p['text']!);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dispatched ${p['trainName']} announcement!')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// LIVE PLATFORM SIGNBOARD MONITOR CARD
  Widget _buildActivePlatformMonitorCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    final hasActive = provider.hasActiveBroadcast;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                children: const [
                  Icon(Icons.monitor, color: AshWineTheme.champagne, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'PLATFORM SIGNBOARD LIVE MONITOR FEED',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AshWineTheme.champagne.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AshWineTheme.champagne.withOpacity(0.5)),
                ),
                child: Text(
                  hasActive ? '● BROADCASTING' : 'STANDBY',
                  style: const TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasActive ? provider.originalTranscription : 'Standby: No active announcement broadcasting. Select a modality above to dispatch.',
            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 12),
          Text(
            'Regional Display Subtitle (Kannada):',
            style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            hasActive ? provider.translatedAnnouncement : '(Awaiting broadcast dispatch)',
            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AshWineTheme.textPrimary(context),
                    side: BorderSide(color: AshWineTheme.cardBorder(context)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.tv, size: 16),
                  label: const Text('Open Kiosk Fullscreen Signboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.sign_language, size: 16),
                  label: const Text('Preview ISL Avatar Player', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignLanguagePlayerScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// RECENT BROADCAST LOG CARD
  Widget _buildBroadcastLogCard(BuildContext context, TranslationProvider provider) {
    final history = provider.history;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history, color: AshWineTheme.champagne, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Recent Broadcast Dispatches',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ],
              ),
              Text(
                '${history.length} Announcements Logged',
                style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text('No announcements dispatched in this session yet.', style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 12)),
              ),
            )
          else
            Column(
              children: history.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.originalText ?? item.translation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// VERIFICATION GATE: STAGED ANNOUNCEMENT CARD
  Widget _buildStagedAnnouncementCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    final staged = provider.stagedAnnouncement;
    if (staged == null) return const SizedBox.shrink();

    final isRailway = provider.isStagedRailwayAnnouncement;
    final reason = provider.stagedValidationReason;
    final transcription = staged['audio_transcription']?.toString() ??
        staged['transcription']?.toString() ??
        staged['original_text']?.toString() ??
        '';
    final detectedLang = staged['detected_language']?.toString() ??
        staged['source_language']?.toString() ??
        'English';
    final category = staged['announcement_category']?.toString() ??
        (isRailway ? 'Railway Announcement' : 'Non-Railway Audio');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRailway ? AshWineTheme.champagne : const Color(0xFFE53935),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isRailway ? AshWineTheme.champagne : const Color(0xFFE53935)).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isRailway ? AshWineTheme.champagne : const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isRailway ? Icons.verified_user : Icons.warning_rounded,
                        color: isRailway ? const Color(0xFF231C21) : Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MASTER APPROVAL GATE • STAGED AUDIO',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                          ),
                          Text(
                            isRailway
                                ? 'Extracted railway announcement awaiting your dispatch approval'
                                : 'Audio verification warning: non-railway content detected',
                            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isRailway
                      ? AshWineTheme.champagne.withOpacity(0.18)
                      : const Color(0xFFE53935).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isRailway ? AshWineTheme.champagne : const Color(0xFFE53935),
                  ),
                ),
                child: Text(
                  isRailway ? 'REVIEW PENDING' : 'RESTRICTED',
                  style: TextStyle(
                    color: isRailway ? AshWineTheme.champagne : const Color(0xFFE53935),
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),

          // Non-Railway Warning Banner if applicable
          if (!isRailway) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B151A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE53935), width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Warning: Non-Railway Audio Detected',
                          style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reason.isNotEmpty
                              ? reason
                              : 'The extracted content does not match railway operational announcements or passenger safety notices (e.g., lost child/purse, safety alert). Direct broadcast to passenger kiosks has been held for review.',
                          style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Extracted Transcription
          Text(
            'EXTRACTED TRANSCRIPTION:',
            style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
            ),
            child: Text(
              transcription.isNotEmpty ? transcription : '(No speech detected in audio stream)',
              style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 12),

          // Details Row: Detected Language, Category
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                backgroundColor: isDark ? const Color(0xFF2D1E28) : AshWineTheme.cardBgSecondaryLight,
                label: Text('Language: $detectedLang'),
                labelStyle: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 11.5, fontWeight: FontWeight.w600),
                avatar: const Icon(Icons.language, size: 16, color: AshWineTheme.champagne),
              ),
              Chip(
                backgroundColor: isDark ? const Color(0xFF2D1E28) : AshWineTheme.cardBgSecondaryLight,
                label: Text('Category: $category'),
                labelStyle: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 11.5, fontWeight: FontWeight.w600),
                avatar: Icon(
                  isRailway ? Icons.train : Icons.music_note,
                  size: 16,
                  color: isRailway ? AshWineTheme.champagne : const Color(0xFFE53935),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Action Buttons: Approve vs Discard
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRailway ? AshWineTheme.champagne : (isDark ? const Color(0xFF3B2630) : const Color(0xFFD6D3D5)),
                    foregroundColor: isRailway ? const Color(0xFF231C21) : (isDark ? Colors.white38 : Colors.black38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(isRailway ? Icons.check_circle_outline : Icons.block, size: 18),
                  label: Text(
                    isRailway
                        ? 'Approve & Broadcast to Platform Displays & Passengers'
                        : 'Broadcast Blocked (Non-Railway Content)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                  onPressed: isRailway
                      ? () {
                          provider.approveStagedAnnouncement();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Approved announcement dispatched to platform displays and passenger apps!')),
                          );
                        }
                      : null, // STRICTLY DISABLED FOR SONGS AND NON-RAILWAY CONTENT!
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                  onPressed: () {
                    provider.discardStagedAnnouncement();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staged announcement discarded.')),
                    );
                  },
                ),
              ),
            ],
          ),
          if (!isRailway) ...[
            const SizedBox(height: 10),
            Text(
              'Station Master Verification Rule: Songs or unrelated audio cannot be dispatched to passenger screens. Only genuine train announcements (arrival, departure, delays, platform changes) or station passenger safety alerts (missing child/person, lost wallet/phone) are permitted.',
              style: TextStyle(color: isDark ? const Color(0xFFE57373) : const Color(0xFFC62828), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  /// IDLE STANDBY CARD WHEN NO ANNOUNCEMENT IS STAGED
  Widget _buildAwaitingInputCard(BuildContext context) {
    final isDark = AshWineTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AshWineTheme.champagne.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: AshWineTheme.champagne,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ANNOUNCEMENT STAGING DESK • AWAITING INPUT',
            style: TextStyle(
              color: AshWineTheme.textPrimary(context),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'No announcement currently staged. Upload an audio or video file, enter a YouTube link, or type custom announcement text above. Extracted content will be validated and staged here for review before broadcasting to passengers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AshWineTheme.textMuted(context),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
