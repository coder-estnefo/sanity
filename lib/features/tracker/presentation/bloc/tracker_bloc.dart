import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/addiction.dart';
import '../../domain/usecases/tracker_usecases.dart';

sealed class TrackerEvent extends Equatable {
  const TrackerEvent();
  @override
  List<Object?> get props => [];
}

class LoadTrackers extends TrackerEvent {
  const LoadTrackers();
}

class SaveTracker extends TrackerEvent {
  const SaveTracker(this.addiction);
  final Addiction addiction;
  @override
  List<Object?> get props => [addiction];
}

class DeleteTracker extends TrackerEvent {
  const DeleteTracker(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ResetTracker extends TrackerEvent {
  const ResetTracker(this.addiction);
  final Addiction addiction;
  @override
  List<Object?> get props => [addiction];
}

/// Fired at midnight / on resume so day counts refresh.
class DayTicked extends TrackerEvent {
  const DayTicked();
}

class TrackerState extends Equatable {
  const TrackerState({
    this.items = const [],
    this.now,
    this.loading = true,
    this.error,
  });

  final List<Addiction> items;
  final DateTime? now;
  final bool loading;
  final String? error;

  TrackerState copyWith({
    List<Addiction>? items,
    DateTime? now,
    bool? loading,
    String? error,
  }) =>
      TrackerState(
        items: items ?? this.items,
        now: now ?? this.now,
        loading: loading ?? this.loading,
        error: error,
      );

  @override
  List<Object?> get props => [items, now, loading, error];
}

class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  TrackerBloc({
    required GetAddictions getAddictions,
    required SaveAddiction saveAddiction,
    required DeleteAddiction deleteAddiction,
    required ResetAddiction resetAddiction,
    DateTime Function()? clock,
  })  : _get = getAddictions,
        _save = saveAddiction,
        _delete = deleteAddiction,
        _reset = resetAddiction,
        _clock = clock ?? DateTime.now,
        super(const TrackerState()) {
    on<LoadTrackers>((e, emit) => _reload(emit));
    on<SaveTracker>((e, emit) => _run(emit, () => _save(e.addiction)));
    on<DeleteTracker>((e, emit) => _run(emit, () => _delete(e.id)));
    on<ResetTracker>((e, emit) => _run(emit, () => _reset(e.addiction)));
    on<DayTicked>((e, emit) => emit(state.copyWith(now: _clock())));
    _scheduleMidnightTick();
  }

  final GetAddictions _get;
  final SaveAddiction _save;
  final DeleteAddiction _delete;
  final ResetAddiction _reset;
  final DateTime Function() _clock;
  Timer? _timer;

  Future<void> _reload(Emitter<TrackerState> emit) async {
    final items = await _get();
    emit(state.copyWith(items: items, now: _clock(), loading: false));
  }

  Future<void> _run(Emitter<TrackerState> emit, Future<void> Function() op) async {
    try {
      await op();
      await _reload(emit);
    } on ArgumentError catch (e) {
      emit(state.copyWith(error: e.message.toString()));
    }
  }

  void _scheduleMidnightTick() {
    final now = _clock();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _timer = Timer(next.difference(now), () {
      if (isClosed) return;
      add(const DayTicked());
      _scheduleMidnightTick();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

