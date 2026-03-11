import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/main.dart' as runner;

import 'app.dart';

void main() async {
  // Configuração Específica de DEV
  const configuredApp = AppConfig(
    flavor: Flavor.dev,
    appName: 'ChegaJá (DEV)',
    apiBaseUrl: 'https://dev-api.chegaja.com', // Exemplo
    child: ChegaJaApp(),
  );

  await runner.mainCommon(configuredApp);
}
