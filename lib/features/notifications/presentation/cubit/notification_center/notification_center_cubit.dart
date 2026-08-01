import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/notification.dart';
import '../../../domain/entities/notification_page.dart';
import '../../../domain/repositories/notification_repository.dart';

enum NotificationCenterStatus { initial, loading, loaded, failure }

class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    this.status = NotificationCenterStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.message,
  });

  final NotificationCenterStatus status;
  final List<AppNotification> items;
  final NotificationCursor? nextCursor;
  final bool loadingMore;
  final String? message;

  NotificationCenterState copyWith({
    NotificationCenterStatus? status,
    List<AppNotification>? items,
    NotificationCursor? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    String? message,
    bool clearMessage = false,
  }) => NotificationCenterState(
    status: status ?? this.status,
    items: items ?? this.items,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, message];
}

class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({required this.repository})
    : super(const NotificationCenterState());

  final NotificationRepository repository;
  StreamSubscription<NotificationPage>? _subscription;

  Future<void> watch() async {
    await _subscription?.cancel();
    emit(
      const NotificationCenterState(status: NotificationCenterStatus.loading),
    );
    _subscription = repository.watchNewest().listen(
      (page) => emit(
        NotificationCenterState(
          status: NotificationCenterStatus.loaded,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
      ),
      onError: (Object error) => emit(
        NotificationCenterState(
          status: NotificationCenterStatus.failure,
          message: _message(error),
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true, clearMessage: true));
    try {
      final page = await repository.loadOlder(cursor);
      final byId = {for (final item in state.items) item.id: item};
      for (final item in page.items) {
        byId[item.id] = item;
      }
      emit(
        state.copyWith(
          items: byId.values.toList(growable: false),
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loadingMore: false, message: _message(error)));
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await repository.markRead(notificationId);
    } catch (error) {
      emit(state.copyWith(message: _message(error)));
    }
  }

  Future<NotificationOpenResult> open(String notificationId) =>
      repository.open(notificationId);

  void clear() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    repository.clearProtectedState();
    emit(const NotificationCenterState());
  }

  String _message(Object error) => error is NotificationFailure
      ? error.message
      : 'Notifications are temporarily unavailable.';

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
