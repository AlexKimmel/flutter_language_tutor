part of 'training_session_bloc.dart';

@immutable
sealed class TrainingSessionState {}

final class TrainingSessionInitial extends TrainingSessionState {}

final class TrainingSessionLoading extends TrainingSessionState {}

final class TrainingInProgress extends TrainingSessionState {
  final TrainingSession session;

  TrainingInProgress(this.session);
}

final class TrainingComplet extends TrainingSessionState {
  final DateTime? nextSessionAvailable;
  TrainingComplet({this.nextSessionAvailable});
}

final class TrainingSessionError extends TrainingSessionState {
  final String message;

  TrainingSessionError(this.message);
}
