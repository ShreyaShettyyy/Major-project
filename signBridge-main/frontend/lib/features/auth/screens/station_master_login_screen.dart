import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../../core/services/api_service.dart';
import '../../station_master/screens/station_master_home_screen.dart';
import '../../translate/providers/translation_provider.dart';
import '../providers/auth_provider.dart';
import 'passenger_login_screen.dart';

class StationMasterLoginScreen extends StatefulWidget {
  const StationMasterLoginScreen({super.key});

  @override
  State<StationMasterLoginScreen> createState() => _StationMasterLoginScreenState();
}

class _StationMasterLoginScreenState extends State<StationMasterLoginScreen> {
  final _staffIdCtrl = TextEditingController(text: 'SM-MAQ-402');
  final _passwordCtrl = TextEditingController(text: 'station123');
  String _stationCode = 'MAQ';
  String _stationName = 'Mangaluru Central (Southern Railway)';
  bool _obscure = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _stations = ApiService.verifiedDakshinaKannadaStations;

  @override
  void initState() {
    super.initState();
    _loadVerifiedStations();
  }

  void _loadVerifiedStations() async {
    final list = await ApiService.fetchVerifiedStations(district: 'Dakshina Kannada');
    if (mounted && list.isNotEmpty) {
      setState(() {
        _stations = list;
      });
    }
  }

  @override
  void dispose() {
    _staffIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _enterStationMasterConsole() async {
    setState(() => _isLoading = true);
    final provider = context.read<TranslationProvider>();
    provider.setUserRole(AppUserRole.stationMaster);
    provider.setStation(_stationCode, _stationName);

    final auth = context.read<AuthProvider>();
    await auth.login('${_staffIdCtrl.text.trim().toLowerCase()}@railnet.gov.in', _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StationMasterHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AshWineTheme.isDark(context);

    return Scaffold(
      backgroundColor: AshWineTheme.bg(context),
      body: Container(
        decoration: AshWineTheme.screenBackgroundDecoration(context),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Railways Staff Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AshWineTheme.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AshWineTheme.champagne.withOpacity(0.8),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AshWineTheme.primaryDark.withOpacity(0.6),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 42,
                        color: AshWineTheme.champagne,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Station Master Console',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AshWineTheme.textPrimary(context),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Official PA Announcement & ISL Platform Dispatch Suite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AshWineTheme.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Security & Division Notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AshWineTheme.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AshWineTheme.cardBorder(context)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_outlined, size: 16, color: AshWineTheme.champagne),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Authorized Railway Operators & Public Address Dispatchers Only.',
                              style: TextStyle(
                                color: AshWineTheme.champagne,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Station & Staff Credentials Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AshWineTheme.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AshWineTheme.cardBorder(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Station Picker
                          Text(
                            'Select Duty Station',
                            style: TextStyle(
                              color: AshWineTheme.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AshWineTheme.cardBorder(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _stationCode,
                                dropdownColor: AshWineTheme.surface(context),
                                style: TextStyle(
                                  color: AshWineTheme.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                items: _stations.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s['code'],
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AshWineTheme.champagne.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            s['code']!,
                                            style: const TextStyle(
                                              color: AshWineTheme.champagne,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            s['name']!,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final found = _stations.firstWhere((s) => s['code'] == val);
                                    setState(() {
                                      _stationCode = found['code']!;
                                      _stationName = found['name']!;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Staff Designation ID
                          TextField(
                            controller: _staffIdCtrl,
                            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Station Master ID / Designation',
                              labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Password / Authorization Token
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Security Password / Key',
                              labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.key_outlined, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Login / Authorize Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AshWineTheme.champagne,
                                foregroundColor: const Color(0xFF21191F),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF21191F)),
                                    )
                                  : const Icon(Icons.login_rounded, size: 20),
                              label: const Text(
                                'Access Master Console',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              onPressed: _isLoading ? null : _enterStationMasterConsole,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Switch to Passenger Portal Link
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F171D) : AshWineTheme.cardBgSecondaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AshWineTheme.cardBorder(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_pin_circle_outlined,
                            size: 16,
                            color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Traveling as a Passenger? ',
                            style: TextStyle(
                              color: AshWineTheme.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const PassengerLoginScreen()),
                              );
                            },
                            child: const Text(
                              'Passenger Portal →',
                              style: TextStyle(
                                color: AshWineTheme.champagne,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
