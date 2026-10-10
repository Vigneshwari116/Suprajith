import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:svenska/core/constants/app_mode.dart';
import 'package:svenska/core/database/local_vehicle_database.dart';
import 'app.dart';
import 'core/utils/app_restart.dart';
import 'injection.dart' as di;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    if (kUseLocalDataStore) {
      LocalVehicleDatabase.init();
    }

    await dotenv.load(fileName: ".env");

    await di.init();

    runApp(const AppRestart(child: MyApp()));
  } catch (e) {
    debugPrint("INIT ERROR: $e");
    runApp(const AppRestart(child: MyApp()));
  }
}