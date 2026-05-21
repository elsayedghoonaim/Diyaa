import '../../../progress/data/models/progress_model.dart';

/// States emitted by [ProgressCubit].
sealed class ProgressState {
  const ProgressState();
}

final class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

final class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

final class ProgressLoaded extends ProgressState {
  final ProgressModel progress;
  const ProgressLoaded(this.progress);
}

final class ProgressError extends ProgressState {
  final String message;
  const ProgressError(this.message);
}
