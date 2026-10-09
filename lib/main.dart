import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'injection.dart' as di;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");

    await di.init();

    runApp(const MyApp());
  } catch (e) {
    debugPrint("INIT ERROR: $e");
    runApp(const MyApp());
  }
}