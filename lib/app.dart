import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'core/api_client.dart';
import 'core/app_preferences.dart';
import 'core/session_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/climate_provider.dart';
import 'providers/history_provider.dart';
import 'providers/recommendation_provider.dart';
import 'routes/app_router.dart';
import 'services/agro_service.dart';
import 'services/auth_service.dart';

/// Raíz de la aplicación: crea servicios, providers y el router.
class AgroSmartApp extends StatefulWidget {
  const AgroSmartApp({super.key, required this.api, required this.sessionStorage, required this.preferences});

  final ApiClient api;
  final SessionStorage sessionStorage;
  final AppPreferences preferences;

  @override
  State<AgroSmartApp> createState() => _AgroSmartAppState();
}

class _AgroSmartAppState extends State<AgroSmartApp> {
  late final AuthProvider _auth;
  late final RecommendationProvider _recommendation;
  late final HistoryProvider _history;
  late final ClimateProvider _climate;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final agro = AgroService(widget.api);
    _auth = AuthProvider(AuthService(widget.api, widget.sessionStorage));
    _recommendation = RecommendationProvider(agro);
    _history = HistoryProvider(agro);
    _climate = ClimateProvider(agro);

    // Un 401 en cualquier solicitud autenticada cierra la sesión y lleva al login.
    widget.api.onUnauthorized = _auth.handleUnauthorized;
    _auth.addSignOutListener(() {
      _recommendation.reset();
      _history.reset();
    });
    _router = AppRouter.create(_auth);
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _recommendation.dispose();
    _history.dispose();
    _climate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _recommendation),
        ChangeNotifierProvider.value(value: _history),
        ChangeNotifierProvider.value(value: _climate),
        ChangeNotifierProvider.value(value: widget.preferences),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: _router,
        locale: const Locale('es', 'PE'),
        supportedLocales: const [Locale('es', 'PE'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
