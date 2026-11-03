import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hamtimer/shared/logging/app_logger.dart';
import 'package:hamtimer/shared/services/push_notification_service.dart';
import 'package:hamtimer/features/feed/data/repository/firebase_feed_repository.dart';
import 'package:hamtimer/features/feed/domain/repositories/feed_repository.dart';
import 'package:hamtimer/features/feed/domain/usecases/publish_post_usecase.dart';
import 'package:hamtimer/features/feed/domain/usecases/set_like_usecase.dart';
import 'package:hamtimer/features/feed/domain/usecases/watch_feed_usecase.dart';
import 'package:hamtimer/features/feed/presentation/providers/feed_provider.dart';
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
import 'features/tasks/data/datasource/mockapi_task_remote_data_source.dart';
import 'features/tasks/data/datasource/sqflite_task_local_data_source.dart';
import 'features/tasks/data/repository/cached_task_repository.dart';
import 'features/tasks/domain/usecases/create_task_usecase.dart';
import 'features/tasks/domain/usecases/delete_task_usecase.dart';
import 'features/tasks/domain/usecases/get_task_history_usecase.dart';
import 'features/tasks/domain/usecases/get_task_page_usecase.dart';
import 'features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'features/tasks/domain/usecases/update_task_usecase.dart';
import 'features/tasks/presentation/providers/task_provider.dart';
import 'firebase_options.dart';
import 'shared/providers/connectivity_provider.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/connectivity_service.dart';
import 'features/auth/data/repository/firebase_auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'shared/network/dio_client.dart';

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
  
  final feedRepository = FirebaseFeedRepository();

  final authRepository = FirebaseAuthRepository();
  final walletRepository = FirestoreWalletRepository();
  final taskRepository = CachedTaskRepository(
    remote: MockApiTaskRemoteDataSource(createDioClient()),
    local: SqfliteTaskLocalDataSource(),
  );

  runApp(
    MultiProvider(
      providers: [
        // Servicios sin estado: se leen con context.read.
        Provider<AnalyticsService>(create: (_) => FirebaseAnalyticsService()),

        // Estado global.
        ChangeNotifierProvider(create: (_) => ConnectivityProvider(ConnectivityPlusService())),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            watchAuthState: WatchAuthStateUseCase(authRepository),
            signIn: SignInUseCase(authRepository),
            signUp: SignUpUseCase(authRepository),
            signOut: SignOutUseCase(authRepository),
          ),
        ),

        // ── Gisi: TaskProvider con sus casos de uso (ChangeNotifierProxyProvider con AuthProvider) ──
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(
            getTasks: GetTasksUseCase(taskRepository),
            getTaskPage: GetTaskPageUseCase(taskRepository),
            getTaskHistory: GetTaskHistoryUseCase(taskRepository),
            createTask: CreateTaskUseCase(taskRepository),
            updateTask: UpdateTaskUseCase(taskRepository),
            deleteTask: DeleteTaskUseCase(taskRepository),
          ),
          update: (_, auth, tasks) => tasks!..setUser(auth.user?.uid),
        ),
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
        Provider<PushNotificationService>(
          create: (_) => PushNotificationService(),
          dispose: (_, service) => service.dispose(),
        ),
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
