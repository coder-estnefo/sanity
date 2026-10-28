import 'package:equatable/equatable.dart';
import '../../../../core/utils/date_utils.dart';

class Addiction extends Equatable {
  const Addiction({
    required this.id,
    required this.name,
    required this.quitDate,
    this.relapses = 0,
  });

  final String id;
  final String name;
  final DateTime quitDate;
  final int relapses;

  /// Derived, never stored.
  int daysFreeAt(DateTime now) => daysFree(quitDate, now);

  Addiction copyWith({String? name, DateTime? quitDate, int? relapses}) =>
      Addiction(
        id: id,
        name: name ?? this.name,
        quitDate: quitDate ?? this.quitDate,
        relapses: relapses ?? this.relapses,
      );

  @override
  List<Object?> get props => [id, name, quitDate, relapses];
}

