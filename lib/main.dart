import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'core/api_client.dart';
import 'core/app_preferences.dart';
import 'core/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    AgroSmartApp(
      api: ApiClient(baseUrl: AppConfig.apiBaseUrl),
      sessionStorage: SecureSessionStorage(),
      preferences: AppPreferences(prefs),
    ),
  );
}
