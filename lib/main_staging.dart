import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/main.dart' as runner;

import 'app.dart';

void main() async {
  // Configuração Específica de STAGING
  const configuredApp = AppConfig(
    flavor: Flavor.staging,
    appName: 'ChegaJá (STAGING)',
    apiBaseUrl: 'https://staging-api.chegaja.com',
    child: ChegaJaApp(),
  );

  await runner.mainCommon(configuredApp);
}
