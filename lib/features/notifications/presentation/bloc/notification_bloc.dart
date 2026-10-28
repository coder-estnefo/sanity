import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../tracker/domain/usecases/tracker_usecases.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/notification_repository.dart';

sealed class NotificationEvent {
  const NotificationEvent();
}

/// Loads settings and (re)schedules reminders. Fired on app start/resume.
class InitNotifications extends NotificationEvent {
  const InitNotifications();
}

class UpdateSettings extends NotificationEvent {
  const UpdateSettings(this.settings);
  final ReminderSettings settings;
}

class NotificationState extends Equatable {
  const NotificationState({
    this.settings = const ReminderSettings(),
    this.permissionGranted = true,
  });
  final ReminderSettings settings;
  final bool permissionGranted;

  @override
  List<Object?> get props => [settings, permissionGranted];
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(
    this._repo, {
    this.getAddictions,
  }) : super(NotificationState(settings: _repo.getSettings())) {
    on<InitNotifications>((e, emit) async {
      final settings = _repo.getSettings();
      var granted = true;
      if (settings.enabled) granted = await _repo.requestPermission();
      await _apply(settings, granted);
      emit(NotificationState(settings: settings, permissionGranted: granted));
    });
    on<UpdateSettings>((e, emit) async {
      await _repo.saveSettings(e.settings);
      var granted = state.permissionGranted;
      if (e.settings.enabled) granted = await _repo.requestPermission();
      await _apply(e.settings, granted);
      emit(NotificationState(settings: e.settings, permissionGranted: granted));
    });
  }

  final NotificationRepository _repo;
  final GetAddictions? getAddictions;

  Future<void> _apply(ReminderSettings s, bool granted) async {
    if (s.enabled && granted) {
      await _repo.reschedule(s);
      if (getAddictions != null) {
        final addictions = await getAddictions!();
        await _repo.scheduleMilestones(addictions);
      }
    } else {
      await _repo.cancelAll();
    }
  }
}
