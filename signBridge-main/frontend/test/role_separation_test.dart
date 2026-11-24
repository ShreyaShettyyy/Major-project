import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_bridge/core/theme/ash_wine_theme.dart';
import 'package:sign_bridge/features/passenger/screens/passenger_home_screen.dart';
import 'package:sign_bridge/features/station_master/screens/station_master_home_screen.dart';
import 'package:sign_bridge/features/translate/providers/translation_provider.dart';
import 'package:sign_bridge/features/settings/providers/settings_provider.dart';
import 'package:sign_bridge/features/auth/providers/auth_provider.dart';

Widget _createTestableWidget(Widget child, TranslationProvider translationProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TranslationProvider>.value(value: translationProvider),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      theme: AshWineTheme.lightTheme,
      darkTheme: AshWineTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PassengerHomeScreen starts in clean idle waiting state and activates on station broadcast', (tester) async {
    final provider = TranslationProvider();
    provider.setUserRole(AppUserRole.passenger);
    provider.setPassengerDestination('Varanasi');

    await tester.pumpWidget(_createTestableWidget(const PassengerHomeScreen(), provider));
    await tester.pump();

    // Verify Passenger Commuter title & Destination Search
    expect(find.text('SignBridge Passenger'), findsOneWidget);
    expect(find.text('COMMUTER'), findsOneWidget);
    expect(find.text('Where are you heading today?'), findsOneWidget);

    // Initial state: Waiting for broadcast (no premature trip alert or fake announcement)
    expect(find.text('Waiting for Station Broadcast'), findsOneWidget);
    expect(find.text('TRIP ALERT NOTIFICATION'), findsNothing);

    // Now Station Master broadcasts Varanasi announcement
    provider.broadcastVaranasiRajdhani();
    await tester.pump();

    // Verify Trip Alert Notification is now displayed
    expect(find.text('TRIP ALERT NOTIFICATION'), findsOneWidget);

    // Verify Train and Platform Highlights
    expect(find.text('Train 0245'), findsOneWidget);
    expect(find.text('Platform 2'), findsOneWidget);

    // Verify languages are present
    expect(find.text('ಕನ್ನಡ • Kannada'), findsOneWidget);
    expect(find.text('हिन्दी • Hindi'), findsOneWidget);
    expect(find.text('English • English'), findsOneWidget);

    // Verify STATION MASTER CONTROLS ARE NOT PRESENT
    expect(find.text('1. Video Upload (.mp4)'), findsNothing);
    expect(find.text('2. Audio / Mic Stream'), findsNothing);
    expect(find.text('3. YouTube Link'), findsNothing);
    expect(find.text('SELECT ANNOUNCEMENT INPUT MODALITY'), findsNothing);
  });

  testWidgets('StationMasterHomeScreen exposes all 5 input modalities and platform monitor without passenger trip search', (tester) async {
    final provider = TranslationProvider();
    provider.setUserRole(AppUserRole.stationMaster);

    await tester.pumpWidget(_createTestableWidget(const StationMasterHomeScreen(), provider));
    await tester.pump();

    // Verify Station Master Console title
    expect(find.text('Station Master Console'), findsOneWidget);
    expect(find.text('● DISPATCH LIVE'), findsOneWidget);

    // Verify ALL 5 MODALITIES ARE PROMINENTLY PRESENT
    expect(find.text('1. Video Upload (.mp4)'), findsOneWidget);
    expect(find.text('2. Audio / Mic Stream'), findsOneWidget);
    expect(find.text('3. YouTube Link'), findsOneWidget);
    expect(find.text('4. Custom Text'), findsOneWidget);
    expect(find.text('5. Station Presets'), findsOneWidget);

    // Verify PASSENGER-ONLY TRIP SEARCH IS NOT PRESENT
    expect(find.text('Where are you heading today?'), findsNothing);
    expect(find.text('PASSENGER PORTAL'), findsNothing);
  });
}
