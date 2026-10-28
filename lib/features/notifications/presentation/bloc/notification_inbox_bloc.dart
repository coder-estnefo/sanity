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

class DeleteInboxNotification extends NotificationInboxEvent {
  const DeleteInboxNotification(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ClearAllNotifications extends NotificationInboxEvent {
  const ClearAllNotifications();
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

  List<NotificationEntry> get visibleEntries => switch (filter) {
        NotificationFilter.all => allEntries,
        NotificationFilter.soft =>
          allEntries.where((e) => e.kind == NotificationKind.soft).toList(),
        NotificationFilter.hard =>
          allEntries.where((e) => e.kind == NotificationKind.hard).toList(),
      };

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
    required this.deleteEntry,
    required this.clearHistory,
  }) : super(const NotificationInboxState()) {
    on<LoadNotificationInbox>((event, emit) async {
      final entries = await getHistory();
      emit(state.copyWith(allEntries: entries, loading: false));
    });

    on<ChangeNotificationFilter>((event, emit) {
      emit(state.copyWith(filter: event.filter));
    });

    on<DeleteInboxNotification>((event, emit) async {
      await deleteEntry(event.id);
      final entries = await getHistory();
      emit(state.copyWith(allEntries: entries));
    });

    on<ClearAllNotifications>((event, emit) async {
      await clearHistory();
      emit(state.copyWith(allEntries: []));
    });
  }

  final GetNotificationHistory getHistory;
  final DeleteNotificationEntry deleteEntry;
  final ClearNotificationHistory clearHistory;
}
