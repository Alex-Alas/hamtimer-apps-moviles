import '../../../pomodoro/domain/entities/pomodoro_settings.dart';
import '../../domain/entities/task_category.dart';

// Reglas de validación del formulario
// null si todo está bien o el mensaje de error a mostrar
abstract final class TaskValidators {
  static const int titleMinLength = 3;
  static const int titleMaxLength = 80;
  static const int minPomodoros = 1;
  static const int maxPomodoros = 12;

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el objetivo de la tarea';
    if (text.length < titleMinLength) return 'Debe tener al menos $titleMinLength caracteres';
    if (text.length > titleMaxLength) return 'Máximo $titleMaxLength caracteres';
    return null;
  }

  static String? category(TaskCategory? value) => value == null ? 'Elige una categoría' : null;

  static String? pomodoros(int value) {
    if (value < minPomodoros) return 'Necesitas al menos $minPomodoros Pomodoro';
    if (value > maxPomodoros) return 'Máximo $maxPomodoros Pomodoros por tarea';
    return null;
  }

  /// Validación del horario
  /// El vencimiento debe ser posterior al inicio
  /// Entre ambos debe caber el tiempo de enfoque, que son los 25 min del pomoodoro
  static String? schedule({
    required DateTime startAt,
    required DateTime dueAt,
    required int estimatedPomodoros,
  }) {
    if (!dueAt.isAfter(startAt)) return 'El vencimiento debe ser posterior al inicio';

    final available = dueAt.difference(startAt);
    final required = PomodoroDurations.focusTimeFor(estimatedPomodoros);
    if (available < required) {
      return 'No alcanza el tiempo: $estimatedPomodoros Pomodoro(s) '
          'necesitan ${required.inMinutes} min y solo hay ${available.inMinutes} min';
    }
    return null;
  }
}
