import '../../domain/entities/zikr.dart';

/// States emitted by [AzkarCubit] (home session list).
sealed class AzkarState {
  const AzkarState();
}

final class AzkarInitial extends AzkarState {
  const AzkarInitial();
}

final class AzkarLoading extends AzkarState {
  const AzkarLoading();
}

final class AzkarLoaded extends AzkarState {
  final List<AzkarSession> sessions;
  const AzkarLoaded(this.sessions);
}

final class AzkarError extends AzkarState {
  final String message;
  const AzkarError(this.message);
}

/// States emitted by [ZikrCubit] (per-session progress).
sealed class ZikrState {
  const ZikrState();
}

final class ZikrInitial extends ZikrState {
  const ZikrInitial();
}

final class ZikrLoading extends ZikrState {
  const ZikrLoading();
}

final class ZikrActive extends ZikrState {
  final AzkarSession session;
  final int currentIndex;
  final List<int> counts;
  const ZikrActive({
    required this.session,
    required this.currentIndex,
    required this.counts,
  });

  ZikrActive copyWith({int? currentIndex, List<int>? counts}) => ZikrActive(
        session: session,
        currentIndex: currentIndex ?? this.currentIndex,
        counts: counts ?? this.counts,
      );
}

final class ZikrCompleted extends ZikrState {
  final AzkarSession session;
  const ZikrCompleted(this.session);
}

final class ZikrError extends ZikrState {
  final String message;
  const ZikrError(this.message);
}
