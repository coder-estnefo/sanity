import '../../../../core/utils/date_utils.dart';
import '../entities/addiction.dart';
import '../repositories/tracker_repository.dart';

class GetAddictions {
  GetAddictions(this._repo);
  final TrackerRepository _repo;
  Future<List<Addiction>> call() => _repo.getAll();
}

class SaveAddiction {
  SaveAddiction(this._repo);
  final TrackerRepository _repo;

  /// Adds or updates. Rejects empty names and future quit dates.
  Future<void> call(Addiction a, {DateTime? now}) {
    if (a.name.trim().isEmpty) {
      throw ArgumentError('Name must not be empty');
    }
    if (dateOnly(a.quitDate).isAfter(dateOnly(now ?? DateTime.now()))) {
      throw ArgumentError('Quit date cannot be in the future');
    }
    return _repo.save(a.copyWith(name: a.name.trim()));
  }
}

class DeleteAddiction {
  DeleteAddiction(this._repo);
  final TrackerRepository _repo;
  Future<void> call(String id) => _repo.delete(id);
}

/// Resets the counter to today and records the relapse.
class ResetAddiction {
  ResetAddiction(this._repo);
  final TrackerRepository _repo;
  Future<void> call(Addiction a, {DateTime? now}) => _repo.save(a.copyWith(
        quitDate: dateOnly(now ?? DateTime.now()),
        relapses: a.relapses + 1,
      ));
}

