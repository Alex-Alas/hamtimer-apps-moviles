import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hamtimer/features/camera/presentation/providers/wallet_provider.dart';
import 'package:hamtimer/shared/logging/app_logger.dart';
import 'package:hamtimer/shared/services/push_notification_service.dart';
import 'package:hamtimer/shared/widgets/feedback.dart';
import 'package:provider/provider.dart';

import '../features/camera/presentation/screens/camera_screen.dart';
import '../shared/services/analytics_service.dart';
import '../shared/widgets/bottom_nav_bar.dart';

/// Contenedor de la app: barra inferior y las cinco pestañas en un
/// [IndexedStack] (no se destruyen al cambiar de pestaña).
///
/// Cada encargado reemplaza SOLO el placeholder de su pestaña por su pantalla
/// (y agrega su import). Cada cambio de pestaña registra la vista en Analytics.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.dashboard;

  StreamSubscription<PushMessage>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AnalyticsService>().logScreen(_tab.screenName));

    final push = context.read<PushNotificationService>();
    _pushSubscription = push.messages.listen(_onPushMessage);
    // Se pide el permiso de notificaciones ya con sesión, no en el login.
    push.init().catchError((Object error) {
      AppLogger.warning('fcm', 'No se pudo iniciar FCM: $error');
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  void _selectTab(HomeTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    context.read<AnalyticsService>().logScreen(tab.screenName);
  }

  /// Notificación de FCM en primer plano o tocada desde la bandeja. Si trae
  /// `campaignId`, regala puntos (una sola vez por campaña).
  Future<void> _onPushMessage(PushMessage message) async {
    final wallet = context.read<WalletProvider>();
    final analytics = context.read<AnalyticsService>();
    final campaignId = message.campaignId;
    if (campaignId != null) {
      try {
        final points = await wallet.claimCampaign(campaignId);
        await analytics.logEvent('campaign_claimed', {'campaign': campaignId, 'points': points});
        if (!mounted) return;
        AppFeedback.show(
          context,
          points > 0 ? '🎁 ¡Recibiste $points puntos para filtros!' : 'Ya cobraste esta campaña',
        );
      } on Exception catch (error) {
        AppLogger.error('fcm', 'No se pudo cobrar la campaña', error);
      }
      return;
    }
    if (!mounted) return;
    final text = [message.title, message.body].whereType<String>().join(': ');
    if (text.isNotEmpty) AppFeedback.show(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab.index,
          children: [
            // ── Gisi: DashboardScreen ──
            const _Placeholder('Pantalla de Gisi (Tareas)'),
            // ── Alex M.: PomodoroScreen ──
            const _Placeholder('Pantalla de Alex M. (Pomodoro)'),
            // ── Nehemías: NewTaskScreen ──
            const _Placeholder('Pantalla de Nehemías (Nueva tarea)'),
            // ── Alex: CameraScreen ──
            CameraScreen(
              isActive: _tab == HomeTab.camera,
              onPublished: () => _selectTab(HomeTab.feed),
            ),
            // ── Armando: FeedScreen ──
            const _Placeholder('Pantalla de Armando (Feed)'),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(selected: _tab, onSelected: _selectTab),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}
