import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hamtimer/features/feed/data/repository/firebase_feed_repository.dart';
import 'package:hamtimer/features/feed/domain/repositories/feed_repository.dart';
import 'package:hamtimer/features/feed/domain/usecases/publish_post_usecase.dart';
import 'package:hamtimer/features/feed/domain/usecases/set_like_usecase.dart';
import 'package:hamtimer/features/feed/domain/usecases/watch_feed_usecase.dart';
import 'package:hamtimer/features/feed/presentation/providers/feed_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'shared/providers/connectivity_provider.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/connectivity_service.dart';

/// Punto de entrada y "raíz de composición": el único lugar donde se eligen
/// las implementaciones concretas (repositorios), se envuelven en casos de uso
/// y se pasan a los providers. Cada encargado agrega SOLO su bloque (marcado
/// con `// ── Nombre: ... ──`) para que git fusione sin conflictos.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es');
  
  final feedRepository = FirebaseFeedRepository();

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
        // ** Ready to launch, depends on AuthProvider. When implemented uncomment the provider below.
        // ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
        //   create: (_) => FeedProvider(
        //     watchFeed: WatchFeedUseCase(feedRepository),
        //     publishPost: PublishPostUseCase(feedRepository),
        //     setLike: SetLikeUseCase(feedRepository)
        //     ),
        //   update: (_, auth, feed) => feed!..setUser(auth.user)),

        // ── Alex M.: PomodoroProvider con sus casos de uso ──

        // ── Nehemías: EstimateTaskDurationUseCase (Gemini) ──
      ],
      child: const HamtimerApp(),
    ),
  );
}
