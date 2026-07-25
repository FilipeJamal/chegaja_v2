import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'core/config/app_config.dart';
import 'core/feature_flags/feature_flag.dart';
import 'core/feature_flags/feature_flag_service.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/locale_service.dart';
import 'core/services/role_mode_service.dart';
import 'core/services/theme_mode_service.dart';
import 'core/services/user_country_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_panel_screen.dart';
import 'features/cliente/cliente_home_screen.dart';
import 'features/auth/role_selector_screen.dart';
import 'features/common/public_profile_by_handle_screen.dart';
import 'features/prestador/prestador_home_screen.dart';

const String kDefaultRole =
    String.fromEnvironment('DEFAULT_ROLE', defaultValue: '');

Route<dynamic>? buildChegaJaRoute(RouteSettings settings) {
  final rawHandle = publicProfileHandleFromRouteName(settings.name);
  if (rawHandle == null) return null;

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => PublicProfileByHandleScreen(rawHandle: rawHandle),
  );
}

String? publicProfileHandleFromRouteName(String? routeName) {
  if (routeName == null || routeName.trim().isEmpty) return null;

  final uri = Uri.tryParse(routeName);
  if (uri == null || uri.pathSegments.length < 2) return null;

  if (uri.pathSegments.first.toLowerCase() != 'p') return null;

  final rawHandle = uri.pathSegments[1].trim();
  if (rawHandle.isEmpty) return null;

  return rawHandle;
}

class ChegaJaApp extends StatefulWidget {
  const ChegaJaApp({
    super.key,
    this.roleModeService,
    this.featureFlagService,
    this.roleSelectorBuilder,
    this.clienteHomeBuilder,
    this.prestadorHomeBuilder,
    this.adminHomeBuilder,
  });

  final RoleModeService? roleModeService;
  final FeatureFlagService? featureFlagService;
  final WidgetBuilder? roleSelectorBuilder;
  final WidgetBuilder? clienteHomeBuilder;
  final WidgetBuilder? prestadorHomeBuilder;
  final WidgetBuilder? adminHomeBuilder;

  @override
  State<ChegaJaApp> createState() => _ChegaJaAppState();
}

class _ChegaJaAppState extends State<ChegaJaApp> {
  late final Future<void> _roleLoadFuture;

  RoleModeService get _roleModeService =>
      widget.roleModeService ?? RoleModeService.instance;
  FeatureFlagService get _featureFlagService =>
      widget.featureFlagService ?? FeatureFlagService.instance;

  @override
  void initState() {
    super.initState();
    _roleLoadFuture = _roleModeService.load(
      urlRole: Uri.base.queryParameters['role'],
      defaultRole: kDefaultRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocaleService.instance,
        _roleModeService,
        ThemeModeService.instance,
        UserCountryService.instance,
        _featureFlagService,
      ]),
      builder: (context, _) {
        final useU1 = _featureFlagService.isEnabled(
          FeatureFlag.u1NavigationV2,
        );
        final publicHandle =
            publicProfileHandleFromRouteName(Uri.base.toString());
        final Widget home = publicHandle != null
            ? PublicProfileByHandleScreen(rawHandle: publicHandle)
            : _pilotPlatformBlocked
                ? const _PilotPlatformUnavailableScreen()
                : _roleModeService.isLoaded
                    ? _homeForRole(context, _roleModeService.currentRole)
                    : FutureBuilder<void>(
                        future: _roleLoadFuture,
                        builder: (context, snapshot) {
                          if (_roleModeService.isLoaded) {
                            return _homeForRole(
                              context,
                              _roleModeService.currentRole,
                            );
                          }
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        },
                      );

        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'ChegaJa',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNavigator.navigatorKey,
          scaffoldMessengerKey: AppNavigator.messengerKey,
          onGenerateRoute: buildChegaJaRoute,
          theme: useU1 ? AppTheme.u1LightTheme : AppTheme.legacyLightTheme,
          darkTheme: useU1 ? AppTheme.u1DarkTheme : AppTheme.legacyDarkTheme,
          themeMode: ThemeModeService.instance.themeMode,
          locale: LocaleService.instance.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppConfig.pilotPortugueseOnly
              ? [AppConfig.pilotLocale]
              : AppLocalizations.supportedLocales,
          home: home,
        );
      },
    );
  }

  bool get _pilotPlatformBlocked {
    if (!AppConfig.pilotMode || !kReleaseMode) return false;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return false;
    }
    return !AppConfig.windowsPublicEnabled;
  }

  Widget _homeForRole(BuildContext context, String? role) {
    return switch (role) {
      'cliente' =>
        widget.clienteHomeBuilder?.call(context) ?? const ClienteHomeScreen(),
      'prestador' => widget.prestadorHomeBuilder?.call(context) ??
          const PrestadorHomeScreen(),
      'admin' =>
        widget.adminHomeBuilder?.call(context) ?? const AdminPanelScreen(),
      _ =>
        widget.roleSelectorBuilder?.call(context) ?? const RoleSelectorScreen(),
    };
  }
}

class _PilotPlatformUnavailableScreen extends StatelessWidget {
  const _PilotPlatformUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    final city = AppConfig.pilotMarket.city;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.android, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Piloto disponível apenas em Android',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'As versões Windows, web e outras plataformas não fazem '
                  'parte do piloto controlado em $city.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
