import 'package:flutter/widgets.dart';

import '../../../../../shared/errors/app_exception.dart';
import '../../../../../shared/utils/date_utils.dart';
import '../../../../pomodoro/domain/entities/pomodoro_settings.dart';
import '../../../domain/entities/duration_estimate.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_category.dart';
import '../../../domain/entities/task_priority.dart';
import '../../../domain/usecases/estimate_task_duration_usecase.dart';
import '../../validators/task_validators.dart';

/// Estado local del formulario Nueva tarea
/// global: lo crea la pantalla y lo destruye al cerrarse
class TaskFormController extends ChangeNotifier {
  TaskFormController({
    required this.onSubmit,
    required this.estimateTaskDuration,
    required this.loadHistory,
    DateTime? now,
  }) {
    // Valores iniciales pensados para crear una tarea en pocos toques
    final base = now ?? DateTime.now();
    _startAt = base.withTime(base.hour, 0).add(const Duration(hours: 1));
    _dueAt = _startAt.add(const Duration(hours: 1));
  }

  final Future<Task> Function(TaskDraft draft) onSubmit;
  final EstimateTaskDurationUseCase estimateTaskDuration;

  /// Tareas completadas del usuario, con el historial que usa Gemin
  final Future<List<Task>> Function() loadHistory;

  final TextEditingController titleController = TextEditingController();

  TaskCategory? _category;
  TaskPriority _priority = TaskPriority.defaultValue;
  int _pomodoros = 2;
  late DateTime _startAt;
  late DateTime _dueAt;
  bool _submitAttempted = false;
  bool _isSubmitting = false;
  String? _submitError;
  bool _isEstimating = false;
  DurationEstimate? _estimate;
  String? _estimateError;

  TaskCategory? get category => _category;
  TaskPriority get priority => _priority;
  int get pomodoros => _pomodoros;
  DateTime get startAt => _startAt;
  DateTime get dueAt => _dueAt;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  bool get isEstimating => _isEstimating;
  DurationEstimate? get estimate => _estimate;
  String? get estimateError => _estimateError;

  /// true si el usuario ya escribió o eligió algo que se perdería al salir
  bool get hasChanges => titleController.text.trim().isNotEmpty || _category != null;

  /// Tras el primer intento de envío, los errores se muestran 
  bool get submitAttempted => _submitAttempted;

  /// Minutos de enfoque que suma la estimación, para el texto del stepper
  int get focusMinutes => PomodoroDurations.focusTimeFor(_pomodoros).inMinutes;

  bool get canDecrement => _pomodoros > TaskValidators.minPomodoros;
  bool get canIncrement => _pomodoros < TaskValidators.maxPomodoros;

  // Errores por campo 

  String? get categoryError => _submitAttempted ? TaskValidators.category(_category) : null;

  String? get pomodorosError => TaskValidators.pomodoros(_pomodoros);

  /// La validación cruzada del horario se muestra siempre
  String? get scheduleError =>
      TaskValidators.schedule(startAt: _startAt, dueAt: _dueAt, estimatedPomodoros: _pomodoros);

  String? validateTitle(String? value) => TaskValidators.title(value);

   //Cambios de valores 

  void selectCategory(TaskCategory value) => _update(() => _category = value);

  void selectPriority(TaskPriority value) => _update(() => _priority = value);

  void incrementPomodoros() {
    if (!canIncrement) return;
    _update(() => _pomodoros++);
  }

  void decrementPomodoros() {
    if (!canDecrement) return;
    _update(() => _pomodoros--);
  }

  void setStartAt(DateTime value) => _update(() => _startAt = value);

  void setDueAt(DateTime value) => _update(() => _dueAt = value);

  // Estimación con IA 

  /// Pide a [estimateTaskDuration] cuántos Pomodoros tomará la tarea y los aplica
  Future<DurationEstimate?> estimateDuration() async {
    final title = titleController.text.trim();
    if (TaskValidators.title(title) != null || _category == null) {
      _update(() => _estimateError = 'Escribe el objetivo y elige una categoría para estimar');
      return null;
    }

    _update(() {
      _isEstimating = true;
      _estimateError = null;
    });
    try {
      List<Task> history;
      try {
        history = await loadHistory();
      } on AppException {
        history = const []; 
      }
      final result = await estimateTaskDuration(
        title: title,
        category: _category!,
        history: history,
      );
      _estimate = result;
      _pomodoros = result.pomodoros;
      final needed = _startAt.add(PomodoroDurations.focusTimeFor(_pomodoros));
      if (_dueAt.isBefore(needed)) _dueAt = needed;
      return result;
    } finally {
      _update(() => _isEstimating = false);
    }
  }

  //  Envío (POST)
  /// Valida todo el formulario y, si es válido, envía la tarea
  Future<Task?> submit({required bool isTitleValid}) async {
    _update(() {
      _submitAttempted = true;
      _submitError = null;
    });

    final isValid =
        isTitleValid && categoryError == null && pomodorosError == null && scheduleError == null;
    if (!isValid || _isSubmitting) return null;

    _update(() => _isSubmitting = true);
    try {
      return await onSubmit(
        TaskDraft(
          title: titleController.text.trim(),
          category: _category!,
          priority: _priority,
          estimatedPomodoros: _pomodoros,
          startAt: _startAt,
          dueAt: _dueAt,
        ),
      );
    } on AppException catch (error) {
      _update(() => _submitError = error.message);
      return null;
    } finally {
      _update(() => _isSubmitting = false);
    }
  }

  bool _disposed = false;

  void _update(VoidCallback change) {
    change();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    titleController.dispose();
    super.dispose();
  }
}
