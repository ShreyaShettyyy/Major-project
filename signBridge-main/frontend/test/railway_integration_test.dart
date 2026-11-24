import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_bridge/core/services/api_service.dart';
import 'package:sign_bridge/core/theme/ash_wine_theme.dart';
import 'package:sign_bridge/features/passenger/screens/passenger_home_screen.dart';
import 'package:sign_bridge/features/station_master/screens/station_master_home_screen.dart';
import 'package:sign_bridge/features/translate/providers/translation_provider.dart';
import 'package:sign_bridge/features/settings/providers/settings_provider.dart';
import 'package:sign_bridge/features/auth/providers/auth_provider.dart';

Widget _createTestWidget(Widget child, TranslationProvider translationProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TranslationProvider>.value(value: translationProvider),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      theme: AshWineTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Railway Station Inventory & Review State Verification', () {
    test('Verified Dakshina Kannada station list contains exactly 14 confirmed active passenger stations', () {
      final stations = ApiService.verifiedDakshinaKannadaStations;
      expect(stations.length, equals(14));

      final codes = stations.map((s) => s['code']).toSet();
      final expectedActiveCodes = {
        'MAQ', 'MAJN', 'SL', 'MULK', 'BNTL', 'KBPR', 'SBHR',
        'ULL', 'YDM', 'BAJE', 'KDBA', 'KNYR', 'NRF', 'NRJ'
      };
      expect(codes, equals(expectedActiveCodes));

      // Rule 9: Strictly verify that non-boarding, technical, goods, closed, and out-of-district candidates are NOT selectable
      final prohibitedReviewCodes = [
        'YDK',  // Sakleshpur, Hassan District (Western Ghats technical crossing loop)
        'SVGL', // Shrivagilu (technical crossing post, 0 commercial stops)
        'TKOT', // Tokkottu (closed halt)
        'TOK',  // Thokur (KR/SR operational boundary cabin)
        'KNKD', // Kankanadi (decommissioned code, historical alias for MAJN)
        'FRG',  // Faringapete (inactive halt)
        'NTVT', // Nethravathi (block cabin)
        'PNMB', // Panamburu (port freight yard)
        'HMB',  // Harebetta (inactive)
        'KLKH', // Kalladaka (inactive)
        'PADL', // Padil (bypass goods cabin)
      ];

      for (final code in prohibitedReviewCodes) {
        expect(codes.contains(code), isFalse, reason: 'Location $code must remain in review state');
      }
    });
  });

  group('Train Master Records Integration (33 Verified Trains)', () {
    test('ApiService contains all 33 authorized Indian Railways train master records', () {
      final trains = ApiService.verifiedTrainMasterRecords;
      expect(trains.length, equals(33));

      final trainNumbers = trains.map((t) => t['train_number']).toSet();

      // Check key trains requested by user
      expect(trainNumbers.contains('20631'), isTrue); // Vande Bharat Express MAQ -> TVC
      expect(trainNumbers.contains('20632'), isTrue); // Vande Bharat Express TVC -> MAQ
      expect(trainNumbers.contains('16595'), isTrue); // Panchaganga Express SBC -> KAWR
      expect(trainNumbers.contains('16596'), isTrue); // Panchaganga Express KAWR -> SBC
      expect(trainNumbers.contains('12619'), isTrue); // Matsyagandha Express LTT -> MAQ
      expect(trainNumbers.contains('12620'), isTrue); // Matsyagandha Express MAQ -> LTT
      expect(trainNumbers.contains('56625'), isTrue); // Subrahmanya Passenger MAQ -> SBHR
      expect(trainNumbers.contains('56626'), isTrue); // Subrahmanya Passenger SBHR -> MAQ
      expect(trainNumbers.contains('17378'), isTrue); // Vijayapura Express MAQ -> BJP
      expect(trainNumbers.contains('10107'), isTrue); // Madgaon Passenger MAO -> MAQ
      expect(trainNumbers.contains('16649'), isTrue); // Parasuram Express MAQ -> CAPE
    });
  });

  group('Station Isolation: Surathkal vs. Mangaluru Central Dispatching', () {
    test('Announcement dispatched at Surathkal (SL) is isolated from Mangaluru Central (MAQ) commuters', () {
      final provider = TranslationProvider();
      provider.setUserRole(AppUserRole.passenger);
      provider.setPassengerStation('MAQ', 'Mangaluru Central');

      // Dispatch announcement at Surathkal
      provider.broadcastCustomAnnouncement(
        trainNo: '16595',
        trainName: 'Panchaganga Express',
        platform: '1',
        destination: 'Karwar',
        originStationCode: 'SL',
        originStationName: 'Surathkal',
      );

      // Verify that the announcement is NOT active for Mangaluru Central passenger
      expect(provider.isBroadcastForPassengerStation, isFalse);
      expect(provider.broadcastStationCode, equals('SL'));
      expect(provider.passengerStationCode, equals('MAQ'));

      // Now switch passenger's station to Surathkal
      provider.setPassengerStation('SL', 'Surathkal');
      expect(provider.isBroadcastForPassengerStation, isTrue);
    });

    testWidgets('Passenger at Mangaluru Central sees Waiting Standby and Cross-Station Notice when Surathkal dispatches', (tester) async {
      final provider = TranslationProvider();
      provider.setUserRole(AppUserRole.passenger);
      provider.setPassengerStation('MAQ', 'Mangaluru Central');

      // Dispatch announcement for Surathkal
      provider.broadcastCustomAnnouncement(
        trainNo: '16595',
        trainName: 'Panchaganga Express',
        platform: '1',
        destination: 'Karwar',
        originStationCode: 'SL',
        originStationName: 'Surathkal',
        customText: 'Train 16595 Panchaganga Express arriving on platform 1 at Surathkal.',
      );

      await tester.pumpWidget(_createTestWidget(const PassengerHomeScreen(), provider));
      await tester.pump();

      // Mangaluru Central passenger must see Waiting Standby for Mangaluru Central
      expect(find.text('Waiting for Station Broadcast'), findsOneWidget);
      expect(find.textContaining('Mangaluru Central'), findsWidgets);

      // Must see Cross-Station Notice indicating dispatch at Surathkal
      expect(find.textContaining('DISPATCHED AT SURATHKAL'), findsOneWidget);
      expect(find.textContaining('Train 16595 Panchaganga Express was announced at Surathkal Station.'), findsOneWidget);
      expect(find.text('Switch View to Surathkal Station'), findsOneWidget);

      // Must NOT show Mangaluru Central platform 1 as occupied by Surathkal train
      expect(find.text('CURRENT STATION ANNOUNCEMENT'), findsNothing);

      // Now tap Switch View to Surathkal Station
      await tester.tap(find.text('Switch View to Surathkal Station'));
      await tester.pump();

      // Now passenger is viewing Surathkal -> announcement is fully active!
      expect(provider.passengerStationCode, equals('SL'));
      expect(find.text('Train 16595'), findsOneWidget);
      expect(find.textContaining('Panchaganga Express'), findsWidgets);
    });
  });

  group('Station Master Console: Train Master Records & Duty Station', () {
    testWidgets('StationMasterHomeScreen exposes Train Master Selector and Duty Station Switcher', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TranslationProvider();
      provider.setUserRole(AppUserRole.stationMaster);
      provider.setStationMasterStation('MAQ', 'Mangaluru Central');

      await tester.pumpWidget(_createTestWidget(const StationMasterHomeScreen(), provider));
      await tester.pump();

      // Verify Duty Station is Mangaluru Central with [Change] button
      expect(find.textContaining('Mangaluru Central • PA Control'), findsOneWidget);
      expect(find.text('[Change]'), findsOneWidget);

      // Navigate to Custom Text Tab (Index 3)
      await tester.ensureVisible(find.text('4. Custom Text'));
      await tester.tap(find.text('4. Custom Text'));
      await tester.pump();

      // Verify Train Master Records Integration Button is present
      expect(find.text('Select from Train Master Records (33 Trains)'), findsOneWidget);

      // Verify Verified Quick Train Chips are present
      expect(find.text('20631 Vande Bharat Express'), findsOneWidget);
      expect(find.text('16595 Panchaganga Express'), findsOneWidget);
      expect(find.text('12620 Matsyagandha Express'), findsOneWidget);
      expect(find.text('56625 Passenger'), findsOneWidget);

      // Tap 16595 Panchaganga Express quick chip
      await tester.tap(find.text('16595 Panchaganga Express'));
      await tester.pump();

      // Announcement text should now be populated with Panchaganga Express
      expect(find.textContaining('16595'), findsWidgets);
      expect(find.textContaining('Panchaganga Express'), findsWidgets);
    });
  });

  group('Rule 8: Safe Platform Display & Emergency Preservation', () {
    test('TranslationProvider safely handles unassigned platforms without inventing defaults', () {
      final provider = TranslationProvider();

      // Idle: no announcement, no fake platform
      expect(provider.currentPlatformDisplay, equals('Standby / TBA'));
      expect(provider.hasPlatformAssigned, isFalse);

      // Broadcast without platform specified
      provider.processText('Attention passengers. Vijayapura Express will arrive shortly.');
      expect(provider.currentPlatformDisplay, equals('Standby / TBA'));
      expect(provider.hasPlatformAssigned, isFalse);

      // Broadcast with explicit platform
      provider.broadcastVandeBharat20631();
      expect(provider.currentPlatformDisplay, equals('1'));
      expect(provider.hasPlatformAssigned, isTrue);
    });

    test('Emergency and safety alerts trigger isEmergencyOrSafetyAlert and prioritize universally', () {
      final provider = TranslationProvider();

      // Normal train announcement
      provider.broadcastVandeBharat20631();
      expect(provider.isEmergencyOrSafetyAlert, isFalse);

      // Emergency Security Alert
      provider.broadcastEmergencySecurityAlert();
      expect(provider.isEmergencyOrSafetyAlert, isTrue);
    });

    testWidgets('PassengerHomeScreen renders Emergency Alert Banner universally when safety alert active', (tester) async {
      final provider = TranslationProvider();
      provider.setUserRole(AppUserRole.passenger);
      provider.setPassengerDestination('Thiruvananthapuram');

      await tester.pumpWidget(_createTestWidget(const PassengerHomeScreen(), provider));
      await tester.pump();

      // Initial state: No emergency banner
      expect(find.text('CRITICAL SAFETY / SECURITY ALERT'), findsNothing);

      // Trigger emergency security alert
      provider.broadcastEmergencySecurityAlert();
      await tester.pump();

      // Universal Emergency Banner must now be visible to all passengers
      expect(find.text('CRITICAL SAFETY / SECURITY ALERT'), findsOneWidget);
      expect(find.text('ALL COMMUTERS PLEASE TAKE NOTE'), findsOneWidget);
      expect(find.textContaining('Railway Helpline: 139'), findsOneWidget);
      expect(find.text('Watch ISL'), findsOneWidget);
    });

    testWidgets('PassengerHomeScreen displays Boarding Station with Change button', (tester) async {
      final provider = TranslationProvider();
      provider.setUserRole(AppUserRole.passenger);
      provider.setPassengerStation('MAQ', 'Mangaluru Central');

      await tester.pumpWidget(_createTestWidget(const PassengerHomeScreen(), provider));
      await tester.pump();

      // Boarding station indicator
      expect(find.textContaining('Boarding Station:'), findsOneWidget);
      expect(find.textContaining('Mangaluru Central (MAQ)'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });
  });
}
