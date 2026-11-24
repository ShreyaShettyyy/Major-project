import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../passenger/screens/passenger_home_screen.dart';
import '../../station_master/screens/station_master_home_screen.dart';
import '../../translate/providers/translation_provider.dart';

class SignBridgeHome extends StatelessWidget {
  const SignBridgeHome({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    if (provider.isStationMaster) {
      return const StationMasterHomeScreen();
    }
    return const PassengerHomeScreen();
  }
}
