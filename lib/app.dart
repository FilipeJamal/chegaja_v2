import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/role_selector_screen.dart';

class ChegaJaApp extends StatelessWidget {
  const ChegaJaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChegaJá',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleSelectorScreen(),
    );
  }
}
