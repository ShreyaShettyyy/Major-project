import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _tabIndex = 0;
  late TextEditingController _headingCtrl;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TranslationProvider>();
    _headingCtrl = TextEditingController(text: provider.passengerDestination);
  }

  @override
  void dispose() {
    _headingCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _languages = const [
    {'code': 'kn', 'label': 'ಕನ್ನಡ', 'name': 'Kannada'},
    {'code': 'hi', 'label': 'हिन्दी', 'name': 'Hindi'},
    {'code': 'en', 'label': 'English', 'name': 'English'},
    {'code': 'te', 'label': 'తెలుగు', 'name': 'Telugu'},
    {'code': 'ta', 'label': 'தமிழ்', 'name': 'Tamil'},
    {'code': 'mr', 'label': 'मराठी', 'name': 'Marathi'},
    {'code': 'bn', 'label': 'বাংলা', 'name': 'Bengali'},
    {'code': 'ml', 'label': 'മലയാളം', 'name': 'Malayalam'},
    {'code': 'gu', 'label': 'ગુજરાતી', 'name': 'Gujarati'},
  ];

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
                color: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_subway_rounded, color: Colors.white, size: 18),
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
                        'SignBridge Passenger',
                        style: TextStyle(
                          color: AshWineTheme.textPrimary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AshWineTheme.champagne.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'COMMUTER',
                          style: TextStyle(color: AshWineTheme.champagne, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${provider.selectedStationName} • Visual Announcements',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11),
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
          // Switch to Staff Console
          PopupMenuButton<String>(
            tooltip: 'Options',
            icon: Icon(Icons.more_vert, color: AshWineTheme.textPrimary(context)),
            color: AshWineTheme.surface(context),
            onSelected: (val) {
              if (val == 'staff') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const StationMasterLoginScreen()),
                );
              } else if (val == 'kiosk') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
                );
              } else if (val == 'logout') {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PassengerLoginScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'kiosk',
                child: Row(
                  children: [
                    Icon(Icons.tv, size: 18, color: AshWineTheme.champagne),
                    SizedBox(width: 10),
                    Text('View Platform Signboard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'staff',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 18, color: AshWineTheme.rose),
                    SizedBox(width: 10),
                    Text('Switch to Station Master Console'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.grey),
                    SizedBox(width: 10),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, provider),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AshWineTheme.surface(context),
          border: Border(top: BorderSide(color: AshWineTheme.cardBorder(context))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navBtn(0, Icons.campaign_rounded, 'Live Board'),
                _navBtn(1, Icons.sign_language_rounded, 'ISL Signs'),
                _navBtn(2, Icons.my_location_rounded, 'My Trip & Alerts'),
                _navBtn(3, Icons.history_rounded, 'History'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(int index, IconData icon, String label) {
    final isSelected = _tabIndex == index;
    final isDark = AshWineTheme.isDark(context);
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AshWineTheme.primaryLight.withOpacity(0.3) : AshWineTheme.cardBgSecondaryLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AshWineTheme.rose.withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine)
                  : AshWineTheme.textMuted(context),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : AshWineTheme.exactAshWine,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  void _showStationPicker(BuildContext context, TranslationProvider provider) {
    final stations = ApiService.verifiedDakshinaKannadaStations;
    final isDark = AshWineTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AshWineTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    const Icon(Icons.location_on, color: AshWineTheme.champagne, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select Your Boarding Station',
                      style: TextStyle(
                        color: AshWineTheme.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Text(
                  'Confirmed active passenger boarding stations in Dakshina Kannada',
                  style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11.5),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: stations.length,
                    separatorBuilder: (_, __) => Divider(color: AshWineTheme.cardBorder(context), height: 1),
                    itemBuilder: (_, idx) {
                      final st = stations[idx];
                      final isSelected = provider.selectedStationCode == st['code'];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${st['name']} (${st['code']})',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AshWineTheme.champagne : AshWineTheme.textPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          '${st['zone']} • ${st['division']} Division • Category ${st['category']}',
                          style: TextStyle(fontSize: 11, color: AshWineTheme.textMuted(context)),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AshWineTheme.champagne, size: 20)
                            : null,
                        onTap: () {
                          provider.setPassengerStation(st['code']!, st['name']!);
                          Navigator.of(ctx).pop();
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

  Widget _buildEmergencyAlertBanner(BuildContext context, TranslationProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF881337), Color(0xFF4C0519)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDA4AF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CRITICAL SAFETY / SECURITY ALERT',
                        style: TextStyle(
                          color: Color(0xFF881337),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ALL COMMUTERS PLEASE TAKE NOTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF881337),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.sign_language, size: 16),
                label: const Text('Watch ISL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                onPressed: () => setState(() => _tabIndex = 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.translatedAnnouncement,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (provider.latinTransliteration.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    provider.latinTransliteration,
                    style: const TextStyle(
                      color: Color(0xFFFECDD3),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.phone_in_talk, size: 14, color: Color(0xFFFDA4AF)),
              SizedBox(width: 6),
              Text(
                'Railway Helpline: 139  •  RPF Emergency Assistance Active',
                style: TextStyle(color: Color(0xFFFECDD3), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherStationNotice(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    final otherStation = provider.broadcastStationName.isNotEmpty
        ? provider.broadcastStationName
        : provider.broadcastStationCode;
    final trainLabel = provider.broadcastTrainNo.isNotEmpty
        ? 'Train ${provider.broadcastTrainNo} ${provider.broadcastTrainName}'
        : 'A train announcement';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D24) : AshWineTheme.cardBgSecondaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AshWineTheme.champagne.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cell_tower, size: 20, color: AshWineTheme.champagne),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AshWineTheme.champagne,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DISPATCHED AT $otherStation'.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF231C21), fontWeight: FontWeight.w900, fontSize: 9.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Your station: ${provider.selectedStationCode}',
                        style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$trainLabel was announced at $otherStation Station.',
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This platform announcement is active for commuters boarding at $otherStation. Your boarding station (${provider.selectedStationName}) has no local dispatch at this moment.',
                  style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(
                    'Switch View to $otherStation Station',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                  ),
                  onPressed: () {
                    provider.setPassengerStation(provider.broadcastStationCode, provider.broadcastStationName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Switched boarding station to $otherStation')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedTrainsList(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF251A21) : const Color(0xFFFAF5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.train, size: 16, color: AshWineTheme.champagne),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Verified Scheduled Trains to ${provider.passengerDestination.toUpperCase()}:',
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${provider.matchedTrains.length} Found',
                style: const TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.matchedTrains.take(3).map((t) {
            final trainNo = t['train_number']?.toString() ?? '';
            final trainName = t['train_name']?.toString() ?? '';
            final depTime = t['departure_time']?.toString() ?? '--:--';
            final dest = t['destination_name']?.toString() ?? '';
            final isWatched = provider.watchedTrainNumber == trainNo;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E151B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isWatched ? AshWineTheme.champagne : AshWineTheme.cardBorder(context),
                  width: isWatched ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AshWineTheme.champagne,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trainNo,
                      style: const TextStyle(color: Color(0xFF231C21), fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainName,
                          style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Departs $depTime • Towards $dest',
                          style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      provider.setWatchedTrainNumber(trainNo);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Now watching Train $trainNo ($trainName)')),
                      );
                    },
                    child: Text(
                      isWatched ? 'WATCHING' : 'WATCH',
                      style: TextStyle(
                        color: isWatched ? const Color(0xFF16A34A) : AshWineTheme.champagne,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TranslationProvider provider) {
    if (_tabIndex == 1) {
      return const SignLanguagePlayerScreen();
    } else if (_tabIndex == 2) {
      return _buildMyTripTab(context, provider);
    } else if (_tabIndex == 3) {
      return const HistoryScreen();
    }
    return _buildLiveBoardTab(context, provider);
  }

  Widget _buildLiveBoardTab(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    final hasActive = provider.hasActiveBroadcast;
    final hasAlert = provider.hasTripAlert;
    final isEmergency = provider.isEmergencyOrSafetyAlert;
    final isForMyStation = provider.isBroadcastForPassengerStation;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Universal Emergency Alert: Preserved for all commuters across all stations
              if (isEmergency) ...[
                _buildEmergencyAlertBanner(context, provider),
              ],

              // 1. "Where are you heading?" Search Bar
              _buildDestinationSearchBar(context, provider),

              const SizedBox(height: 14),

              // Station Isolation Check:
              // If an announcement was issued for another station (e.g. Surathkal when passenger is at Mangaluru Central),
              // keep current station in Waiting Standby mode and show an informational cross-station notice.
              if (!hasActive || !isForMyStation) ...[
                if (hasActive && !isForMyStation) ...[
                  _buildOtherStationNotice(context, provider),
                ],
                _buildWaitingStandbyCard(context, provider),
                const SizedBox(height: 16),
              ] else ...[
                // 2. High-Priority Trip Alert Notification Banner (when destination matches)
                if (hasAlert) ...[
                  _buildTripAlertNotificationBanner(context, provider),
                  const SizedBox(height: 14),
                ] else if (provider.passengerDestination.isNotEmpty) ...[
                  _buildDifferentRouteStatusBanner(context, provider),
                ],

                // 3. Instant Pre-Translated Language Selector Chips (0 wait time)
                _buildInstantLanguageChips(context, provider),

                const SizedBox(height: 16),

                // 4. Highlighted Train Announcement Card (Train No, Platform, Route, Sign Player)
                _buildHighlightedAnnouncementCard(context, provider),

                const SizedBox(height: 16),
              ],

              // 6. Platform Kiosk Display Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AshWineTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AshWineTheme.cardBorder(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AshWineTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tv, color: AshWineTheme.champagne, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Signboard Screen',
                            style: TextStyle(
                              color: AshWineTheme.textPrimary(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Preview the high-contrast digital kiosk feed installed on platform tracks.',
                            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlatformKioskScreen()),
                      ),
                      child: const Text('Open Kiosk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Destination Search Bar with Quick Chips
  Widget _buildDestinationSearchBar(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boarding Station Badge & Change Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trip_origin_rounded, color: AshWineTheme.champagne, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Boarding Station: ',
                        style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                      ),
                      Flexible(
                        child: Text(
                          '${provider.selectedStationName} (${provider.selectedStationCode})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AshWineTheme.textPrimary(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showStationPicker(context, provider),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AshWineTheme.champagne.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, size: 13, color: AshWineTheme.champagne),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(color: AshWineTheme.champagne, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.near_me_rounded, color: AshWineTheme.champagne, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Where are you heading today?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (provider.passengerDestination.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AshWineTheme.champagne.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'WATCHING: ${provider.passengerDestination.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AshWineTheme.champagne,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _headingCtrl,
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your destination (e.g. Varanasi, Bengaluru, Mumbai...)',
                    hintStyle: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      borderSide: const BorderSide(color: AshWineTheme.champagne),
                    ),
                  ),
                  onSubmitted: (val) {
                    provider.setPassengerDestination(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AshWineTheme.champagne,
                  foregroundColor: const Color(0xFF231C21),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.setPassengerDestination(_headingCtrl.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Now watching announcements for: ${_headingCtrl.text}')),
                  );
                },
                child: const Text('Set Trip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _quickDestChip('Thiruvananthapuram', provider),
              _quickDestChip('Bengaluru', provider),
              _quickDestChip('Mumbai', provider),
              _quickDestChip('Subrahmanya Road', provider),
              _quickDestChip('Karwar', provider),
              _quickDestChip('Vijayapura', provider),
            ],
          ),
          if (provider.matchedTrains.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildMatchedTrainsList(context, provider),
          ],
        ],
      ),
    );
  }

  Widget _quickDestChip(String label, TranslationProvider provider) {
    final isSelected = provider.passengerDestination.toLowerCase() == label.toLowerCase();
    final isDark = AshWineTheme.isDark(context);
    return InkWell(
      onTap: () {
        _headingCtrl.text = label;
        provider.setPassengerDestination(label);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine)
              : (isDark ? const Color(0xFF281E25) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AshWineTheme.champagne : AshWineTheme.cardBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AshWineTheme.textPrimary(context),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  /// Standby Card when station is awaiting announcement
  Widget _buildWaitingStandbyCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AshWineTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF281E26) : AshWineTheme.cardBgSecondaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radio_button_checked_rounded,
              color: AshWineTheme.champagne,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for Station Broadcast',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AshWineTheme.textPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Station: ${provider.selectedStationName}',
            style: const TextStyle(color: AshWineTheme.champagne, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'No active railway announcements for ${provider.selectedStationName} at this moment. When the on-duty Station Master dispatches an announcement for ${provider.selectedStationCode}, live multi-lingual subtitles and sign language gestures will display here immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AshWineTheme.textSecondary(context),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Different Route Status Banner (when announcement is for another train/destination)
  Widget _buildDifferentRouteStatusBanner(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D24) : AshWineTheme.cardBgSecondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshWineTheme.cardBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AshWineTheme.champagne.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, size: 16, color: AshWineTheme.champagne),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                children: [
                  const TextSpan(text: 'Watching for destination: '),
                  TextSpan(
                    text: provider.passengerDestination.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AshWineTheme.champagne),
                  ),
                  const TextSpan(text: ' • The announcement below is for a different route.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// High-Priority Notification Banner for Passenger's Destination / Train (Ash Wine Theme)
  Widget _buildTripAlertNotificationBanner(BuildContext context, TranslationProvider provider) {
    String trainNo = '';
    String trainName = 'Express Train';
    String platform = provider.currentPlatformDisplay;
    String dest = provider.passengerDestination;

    for (final ent in provider.namedEntities) {
      if (ent['entity_type'] == 'TRAIN_NUMBER') trainNo = ent['text']?.toString() ?? trainNo;
      if (ent['entity_type'] == 'TRAIN_NAME') trainName = ent['text']?.toString() ?? trainName;
      if (ent['entity_type'] == 'PLATFORM') {
        final pf = ent['text']?.toString().trim() ?? '';
        if (pf.isNotEmpty && pf != '0') platform = pf;
      }
      if (ent['entity_type'] == 'DESTINATION') dest = ent['text']?.toString() ?? dest;
    }

    final platformText = provider.hasPlatformAssigned ? 'Platform $platform' : 'Platform: Standby / TBA';
    final alertHeading = 'Your train to ${dest.toUpperCase()} (${trainNo.isNotEmpty ? "Train $trainNo " : ""}$trainName) is arriving on $platformText!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AshWineTheme.wineHeroGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshWineTheme.champagne.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AshWineTheme.primaryDark.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, color: AshWineTheme.champagne, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AshWineTheme.champagne,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TRIP ALERT NOTIFICATION',
                        style: TextStyle(color: Color(0xFF231C21), fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DESTINATION: ${provider.passengerDestination.toUpperCase()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alertHeading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Visual sign language & multi-language subtitles are active.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AshWineTheme.champagne,
              foregroundColor: const Color(0xFF231C21),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.sign_language, size: 16),
            label: const Text(
              'Watch ISL',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            onPressed: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }

  /// Instant Language Selector Chips (0 Wait Time)
  Widget _buildInstantLanguageChips(BuildContext context, TranslationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.translate, size: 16, color: AshWineTheme.champagne),
                SizedBox(width: 6),
                Text(
                  'Instant Announcement Language (0ms Delay)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AshWineTheme.champagne.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
              ),
              child: const Text('PRE-TRANSLATED', style: TextStyle(color: AshWineTheme.champagne, fontSize: 9.5, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _languages.map((l) {
              final isSelected = provider.targetLanguage == l['code'];
              final isDark = AshWineTheme.isDark(context);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${l['label']} • ${l['name']}'),
                  selected: isSelected,
                  selectedColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                  backgroundColor: isDark ? const Color(0xFF281E25) : AshWineTheme.cardBgSecondaryLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AshWineTheme.textPrimary(context),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AshWineTheme.champagne : AshWineTheme.cardBorder(context),
                  ),
                  onSelected: (val) {
                    if (val) provider.setTargetLanguage(l['code']!);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Highlighted Announcement Card (Train No, Platform, Route, Sign Player)
  Widget _buildHighlightedAnnouncementCard(BuildContext context, TranslationProvider provider) {
    final isDark = AshWineTheme.isDark(context);

    // Extract highlight attributes dynamically
    String trainNo = '';
    String trainName = 'Express Train';
    String platform = provider.currentPlatformDisplay;
    String destination = '';
    String route = provider.selectedStationName;

    for (final ent in provider.namedEntities) {
      if (ent['entity_type'] == 'TRAIN_NUMBER') trainNo = ent['text']?.toString() ?? trainNo;
      if (ent['entity_type'] == 'TRAIN_NAME') trainName = ent['text']?.toString() ?? trainName;
      if (ent['entity_type'] == 'PLATFORM') platform = ent['text']?.toString() ?? platform;
      if (ent['entity_type'] == 'DESTINATION') {
        destination = ent['text']?.toString() ?? '';
        route = 'Mangaluru Central ➔ $destination';
      }
    }

    if (destination.isEmpty) {
      final destMatch = RegExp(r'(?:to|bound for|heading to|towards)\s+([A-Za-z]+)', caseSensitive: false)
          .firstMatch(provider.originalTranscription);
      if (destMatch != null) {
        destination = destMatch.group(1)!;
        route = 'Mangaluru Central ➔ $destination';
      } else {
        route = 'Mangaluru Central Line';
      }
    }

    if (trainNo.isEmpty) {
      final numMatch = RegExp(r'\b(0?\d{3,5})\b').firstMatch(provider.originalTranscription);
      if (numMatch != null) trainNo = numMatch.group(1)!;
    }

    final hasAlert = provider.hasTripAlert;
    final isDifferentRoute = !hasAlert && provider.passengerDestination.isNotEmpty;

    String headerTitle = 'CURRENT STATION ANNOUNCEMENT';
    String statusBadge = 'ARRIVING SHORTLY';

    if (hasAlert) {
      headerTitle = 'YOUR TRAIN ANNOUNCEMENT';
      statusBadge = 'YOUR TRIP • PLATFORM $platform';
    } else if (isDifferentRoute) {
      headerTitle = 'STATION BROADCAST • OTHER ROUTE';
      statusBadge = 'OTHER ROUTE (WATCHING: ${provider.passengerDestination.toUpperCase()})';
    }

    final nativeText = provider.translatedAnnouncement;
    final latinText = provider.latinTransliteration;

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
          // Header with Live Beacon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: hasAlert ? AshWineTheme.champagne : (isDifferentRoute ? AshWineTheme.rose : AshWineTheme.champagne),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        headerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasAlert ? AshWineTheme.champagne : AshWineTheme.textMuted(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasAlert ? AshWineTheme.champagne.withOpacity(0.22) : (isDifferentRoute ? AshWineTheme.rose.withOpacity(0.2) : AshWineTheme.champagne.withOpacity(0.18)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: hasAlert ? AshWineTheme.champagne : (isDifferentRoute ? AshWineTheme.rose.withOpacity(0.6) : AshWineTheme.champagne.withOpacity(0.6))),
                  ),
                  child: Text(
                    statusBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasAlert ? AshWineTheme.champagne : (isDifferentRoute ? AshWineTheme.rose : AshWineTheme.champagne),
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // HIGHLIGHTED BADGES ROW: Train No, Platform, Route
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Train Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AshWineTheme.champagne,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.numbers, size: 14, color: Color(0xFF231C21)),
                    const SizedBox(width: 4),
                    Text(
                      trainNo.isNotEmpty ? 'Train $trainNo' : trainName,
                      style: const TextStyle(color: Color(0xFF231C21), fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Platform Badge (Rule 8: Safe platform display)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room, size: 14, color: AshWineTheme.champagne),
                    const SizedBox(width: 4),
                    Text(
                      provider.hasPlatformAssigned ? 'Platform $platform' : 'Platform: Standby / TBA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Route Badge (From ➔ To)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AshWineTheme.cardDark : const Color(0xFF38121E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AshWineTheme.cardBorder(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route_outlined, size: 14, color: AshWineTheme.champagne),
                    const SizedBox(width: 6),
                    Text(
                      route,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Train Name Title
          Text(
            trainName,
            style: TextStyle(
              color: AshWineTheme.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          // Native Translation Text (Large, Clear, Ash Wine Themed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF251A21) : const Color(0xFFF9F3F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AshWineTheme.cardBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.targetLangName,
                      style: TextStyle(color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                        size: 20,
                        color: provider.isSpeaking ? const Color(0xFF16A34A) : AshWineTheme.champagne,
                      ),
                      tooltip: provider.isSpeaking ? 'Stop announcement' : 'Listen to announcement in ${provider.targetLangName}',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        provider.speakTranslation(nativeText, provider.targetLanguage);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nativeText,
                  style: TextStyle(
                    color: AshWineTheme.textPrimary(context),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (latinText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    latinText,
                    style: TextStyle(
                      color: AshWineTheme.textSecondary(context),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Original Spoken Audio Reference
          Text(
            'Original PA Announcement:',
            style: TextStyle(color: AshWineTheme.textMuted(context), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            provider.originalTranscription,
            style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12, height: 1.3),
          ),

          const SizedBox(height: 18),

          // Action Buttons: Watch Sign Language & View Kiosk
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AshWineTheme.primaryLight : AshWineTheme.exactAshWine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.sign_language, size: 18),
                  label: const Text('Watch Sign Language Gestures', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  onPressed: () => setState(() => _tabIndex = 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// My Trip & Visual Watch Tab
  Widget _buildMyTripTab(BuildContext context, TranslationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Journey Alerts & Train Tracking',
                style: TextStyle(
                  color: AshWineTheme.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Receive instant visual notifications whenever station announcements mention your train number or destination station.',
                style: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildDestinationSearchBar(context, provider),
              const SizedBox(height: 16),
              if (provider.hasTripAlert) _buildTripAlertNotificationBanner(context, provider),
              const SizedBox(height: 24),
              Text(
                'Watched Preferences',
                style: TextStyle(color: AshWineTheme.textPrimary(context), fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                tileColor: AshWineTheme.surface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AshWineTheme.cardBorder(context)),
                ),
                leading: const Icon(Icons.location_on, color: AshWineTheme.rose),
                title: const Text('Destination Station', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text(provider.passengerDestination.isNotEmpty ? provider.passengerDestination : 'Not specified'),
                trailing: TextButton(
                  onPressed: () => _headingCtrl.text = '',
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                tileColor: AshWineTheme.surface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AshWineTheme.cardBorder(context)),
                ),
                leading: const Icon(Icons.train, color: AshWineTheme.champagne),
                title: const Text('Train Number Watch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text('Train ${provider.watchedTrainNumber}'),
                trailing: TextButton(
                  onPressed: () => provider.setWatchedTrainNumber('0245'),
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
