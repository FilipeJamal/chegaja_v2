import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'core/navigation/app_navigator.dart';
import 'core/services/locale_service.dart';
import 'core/services/theme_mode_service.dart';
import 'core/services/user_country_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_panel_screen.dart';
import 'features/cliente/cliente_home_screen.dart';
import 'features/auth/role_selector_screen.dart';
import 'features/prestador/prestador_home_screen.dart';

const String kDefaultRole =
    String.fromEnvironment('DEFAULT_ROLE', defaultValue: '');

class ChegaJaApp extends StatelessWidget {
  const ChegaJaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocaleService.instance,
        ThemeModeService.instance,
        UserCountryService.instance,
      ]),
      builder: (context, _) {
        final roleFromUrl =
            Uri.base.queryParameters['role']?.trim().toLowerCase() ?? '';
        final resolvedRole = roleFromUrl.isNotEmpty
            ? roleFromUrl
            : kDefaultRole.trim().toLowerCase();
        final Widget home = switch (resolvedRole) {
          'cliente' => const ClienteHomeScreen(),
          'prestador' => const PrestadorHomeScreen(),
          'admin' => const AdminPanelScreen(),
          _ => const RoleSelectorScreen(),
        };

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
}
