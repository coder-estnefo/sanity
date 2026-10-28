import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_entry.dart';
import '../../domain/usecases/notification_history_usecases.dart';

enum NotificationFilter { all, soft, hard }

sealed class NotificationInboxEvent extends Equatable {
  const NotificationInboxEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationInbox extends NotificationInboxEvent {
  const LoadNotificationInbox();
}

class ChangeNotificationFilter extends NotificationInboxEvent {
  const ChangeNotificationFilter(this.filter);
  final NotificationFilter filter;
  @override
  List<Object?> get props => [filter];
}

class SendTestNotificationEvent extends NotificationInboxEvent {
  const SendTestNotificationEvent({
    this.kind = NotificationKind.soft,
    this.message,
  });
  final NotificationKind kind;
  final String? message;

  @override
  List<Object?> get props => [kind, message];
}

class NotificationInboxState extends Equatable {
  const NotificationInboxState({
    this.allEntries = const [],
    this.filter = NotificationFilter.all,
    this.loading = true,
  });

  final List<NotificationEntry> allEntries;
  final NotificationFilter filter;
  final bool loading;

  List<NotificationEntry> get visibleEntries {
    final filtered = switch (filter) {
      NotificationFilter.all => allEntries,
      NotificationFilter.soft =>
        allEntries.where((e) => e.kind == NotificationKind.soft).toList(),
      NotificationFilter.hard =>
        allEntries.where((e) => e.kind == NotificationKind.hard).toList(),
    };
    return [...filtered]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int countFor(NotificationFilter f) => switch (f) {
        NotificationFilter.all => allEntries.length,
        NotificationFilter.soft =>
          allEntries.where((e) => e.kind == NotificationKind.soft).length,
        NotificationFilter.hard =>
          allEntries.where((e) => e.kind == NotificationKind.hard).length,
      };

  NotificationInboxState copyWith({
    List<NotificationEntry>? allEntries,
    NotificationFilter? filter,
    bool? loading,
  }) =>
      NotificationInboxState(
        allEntries: allEntries ?? this.allEntries,
        filter: filter ?? this.filter,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [allEntries, filter, loading];
}

class NotificationInboxBloc
    extends Bloc<NotificationInboxEvent, NotificationInboxState> {
  NotificationInboxBloc({
    required this.getHistory,
    this.triggerTest,
  }) : super(const NotificationInboxState()) {
    on<LoadNotificationInbox>((event, emit) async {
      final entries = await getHistory();
      final sorted = [...entries]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(state.copyWith(allEntries: sorted, loading: false));
    });

    on<ChangeNotificationFilter>((event, emit) {
      emit(state.copyWith(filter: event.filter));
    });

    on<SendTestNotificationEvent>((event, emit) async {
      if (triggerTest != null) {
        await triggerTest!(kind: event.kind, message: event.message);
      }
      final entries = await getHistory();
      final sorted = [...entries]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(state.copyWith(allEntries: sorted, loading: false));
    });
  }

  final GetNotificationHistory getHistory;
  final TriggerTestNotificationUseCase? triggerTest;
}
