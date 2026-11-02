import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
// TODO Alex: activar junto con el bloque de WalletProvider cuando exista AuthProvider.
// import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/camera/data/repository/firestore_wallet_repository.dart';
import 'features/camera/domain/usecases/buy_filter_usecase.dart';
import 'features/camera/domain/usecases/claim_campaign_usecase.dart';
import 'features/camera/domain/usecases/earn_points_usecase.dart';
import 'features/camera/domain/usecases/ensure_wallet_usecase.dart';
import 'features/camera/domain/usecases/watch_wallet_usecase.dart';
import 'features/camera/presentation/providers/wallet_provider.dart';
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

  // final walletRepository = FirestoreWalletRepository();

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
        //TODO: Se activa cuando exista el AuthProvider de Jade.
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(
            watchWallet: WatchWalletUseCase(walletRepository),
            ensureWallet: EnsureWalletUseCase(walletRepository),
            earnPoints: EarnPointsUseCase(walletRepository),
            buyFilter: BuyFilterUseCase(walletRepository),
            claimCampaign: ClaimCampaignUseCase(walletRepository),
          ),
          update: (_, auth, wallet) => wallet!..setUser(auth.user?.uid),
        ),

        // ── Armando: FeedProvider con sus casos de uso y PushNotificationService ──

        // ── Alex M.: PomodoroProvider con sus casos de uso ──

        // ── Nehemías: EstimateTaskDurationUseCase (Gemini) ──
      ],
      child: const HamtimerApp(),
    ),
  );
}
