import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/ash_wine_theme.dart';
import '../../../core/services/api_service.dart';
import '../../passenger/screens/passenger_home_screen.dart';
import '../../translate/providers/translation_provider.dart';
import '../providers/auth_provider.dart';
import 'station_master_login_screen.dart';

class PassengerLoginScreen extends StatefulWidget {
  const PassengerLoginScreen({super.key});

  @override
  State<PassengerLoginScreen> createState() => _PassengerLoginScreenState();
}

class _PassengerLoginScreenState extends State<PassengerLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'passenger@signbridge.rail');
  final _passCtrl = TextEditingController(text: 'password123');
  String _selectedStationCode = 'MAQ';
  String _selectedStationName = 'Mangaluru Central';
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _enterPassengerPortal({bool isGuest = false}) async {
    setState(() => _isLoading = true);
    final provider = context.read<TranslationProvider>();
    provider.setUserRole(AppUserRole.passenger);
    provider.setStation(_selectedStationCode, _selectedStationName);

    if (!isGuest) {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PassengerHomeScreen()),
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
                    // Header Brand
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AshWineTheme.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AshWineTheme.rose.withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AshWineTheme.exactAshWine.withOpacity(0.4),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_subway_rounded,
                        size: 42,
                        color: AshWineTheme.champagne,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SignBridge Passenger',
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
                      'Live Railway Station Visual Announcements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AshWineTheme.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Verified Passenger Station Selection (Current Boarding Location)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AshWineTheme.champagne.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on, size: 16, color: AshWineTheme.champagne),
                              SizedBox(width: 6),
                              Text(
                                'Select Your Current Boarding Station',
                                style: TextStyle(
                                  color: AshWineTheme.champagne,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedStationCode,
                              dropdownColor: AshWineTheme.surface(context),
                              style: TextStyle(
                                color: AshWineTheme.textPrimary(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              items: _stations.map((s) {
                                final code = s['code']?.toString() ?? 'MAQ';
                                final name = s['name']?.toString() ?? 'Mangaluru Central';
                                final div = s['division']?.toString() ?? '';
                                return DropdownMenuItem<String>(
                                  value: code,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AshWineTheme.champagne.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          code,
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
                                          div.isNotEmpty ? '$name ($div)' : name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedStationCode = val;
                                    final match = _stations.firstWhere(
                                      (s) => s['code'] == val,
                                      orElse: () => {'code': val, 'name': val},
                                    );
                                    _selectedStationName = match['name']?.toString() ?? val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Primary Fast Pass Button: 1-Tap Passenger Screen Entry
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
                            : const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: const Text(
                          'Continue to Passenger Screen (Fast Access)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        onPressed: _isLoading ? null : () => _enterPassengerPortal(isGuest: true),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider with Text
                    Row(
                      children: [
                        Expanded(child: Divider(color: AshWineTheme.cardBorder(context))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR PASSENGER SIGN IN',
                            style: TextStyle(
                              color: AshWineTheme.textMuted(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AshWineTheme.cardBorder(context))),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Form Fields (Email & Password)
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Passenger Email / Mobile',
                        labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF261D23) : AshWineTheme.cardBgSecondaryLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshWineTheme.cardBorder(context))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: TextStyle(color: AshWineTheme.textPrimary(context), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: AshWineTheme.textSecondary(context), fontSize: 12),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
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

                    const SizedBox(height: 14),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AshWineTheme.textPrimary(context),
                          side: BorderSide(color: AshWineTheme.cardBorder(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : () => _enterPassengerPortal(isGuest: false),
                        child: const Text('Sign In to My Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Switch to Station Master Console Link
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
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                            color: isDark ? AshWineTheme.champagne : AshWineTheme.exactAshWine,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Are you Railway Staff? ',
                            style: TextStyle(
                              color: AshWineTheme.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const StationMasterLoginScreen()),
                              );
                            },
                            child: const Text(
                              'Station Master Sign In →',
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
