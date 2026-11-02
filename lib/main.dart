import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hamtimer/shared/logging/app_logger.dart';
import 'package:hamtimer/shared/services/push_notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'shared/providers/connectivity_provider.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/connectivity_service.dart';

//Recibe los mensajes de FCM con la app cerrada o en segundo plano.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('fcm', 'Mensaje en segundo plano ${message.messageId}');
}

/// Punto de entrada y "raíz de composición": el único lugar donde se eligen
/// las implementaciones concretas (repositorios), se envuelven en casos de uso
/// y se pasan a los providers. Cada encargado agrega SOLO su bloque (marcado
/// con `// ── Nombre: ... ──`) para que git fusione sin conflictos.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('es');

  runApp(
    MultiProvider(
      providers: [
        // Servicios sin estado: se leen con context.read.
        Provider<AnalyticsService>(create: (_) => FirebaseAnalyticsService()),

        // Estado global.
        ChangeNotifierProvider(create: (_) => ConnectivityProvider(ConnectivityPlusService())),

        // ── Jade: AuthProvider (casos de uso de auth) ──

        // ── Gisi: TaskProvider con sus casos de uso (ChangeNotifierProxyProvider con AuthProvider) ──

        // ── Alex: WalletProvider con sus casos de uso (ChangeNotifierProxyProvider con AuthProvider) ──

        // ── Armando: FeedProvider con sus casos de uso y PushNotificationService ──
        Provider<PushNotificationService>(
          create: (_) => PushNotificationService(),
          dispose: (_, service) => service.dispose(),
        ),

        // ── Alex M.: PomodoroProvider con sus casos de uso ──

        // ── Nehemías: EstimateTaskDurationUseCase (Gemini) ──
      ],
      child: const HamtimerApp(),
    ),
  );
}
