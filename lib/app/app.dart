import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../shared/theme/app_theme.dart';
import 'home_shell.dart';

/// Widget raíz: tema, idioma y pantalla inicial.
///
/// Por ahora abre [HomeShell] directo. Jade lo cambia por un `AuthGate` que
/// muestre login o la app según la sesión.
class HamtimerApp extends StatelessWidget {
  const HamtimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamtimer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}
