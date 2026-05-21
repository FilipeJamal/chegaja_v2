import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'core/navigation/app_navigator.dart';
import 'core/services/locale_service.dart';
import 'core/services/role_mode_service.dart';
import 'core/services/theme_mode_service.dart';
import 'core/services/user_country_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_panel_screen.dart';
import 'features/cliente/cliente_home_screen.dart';
import 'features/auth/role_selector_screen.dart';
import 'features/prestador/prestador_home_screen.dart';

const String kDefaultRole =
    String.fromEnvironment('DEFAULT_ROLE', defaultValue: '');

class ChegaJaApp extends StatefulWidget {
  const ChegaJaApp({
    super.key,
    this.roleModeService,
    this.roleSelectorBuilder,
    this.clienteHomeBuilder,
    this.prestadorHomeBuilder,
    this.adminHomeBuilder,
  });

  final RoleModeService? roleModeService;
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
      ]),
      builder: (context, _) {
        final Widget home = _roleModeService.isLoaded
            ? _homeForRole(context, _roleModeService.currentRole)
            : FutureBuilder<void>(
                future: _roleLoadFuture,
                builder: (context, snapshot) {
                  if (_roleModeService.isLoaded) {
                    return _homeForRole(context, _roleModeService.currentRole);
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
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeModeService.instance.themeMode,
          locale: LocaleService.instance.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        );
      },
    );
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
