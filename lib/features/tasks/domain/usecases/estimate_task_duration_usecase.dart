import '../entities/duration_estimate.dart';
import '../entities/task.dart';
import '../entities/task_category.dart';
import '../repositories/duration_estimator.dart';

/// Estima cuántos Pomodoros tomará una tarea 
class EstimateTaskDurationUseCase {
  const EstimateTaskDurationUseCase(this._repository);

  final DurationEstimator _repository;

  Future<DurationEstimate> call({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  }) => _repository.estimate(title: title.trim(), category: category, history: history);
}
