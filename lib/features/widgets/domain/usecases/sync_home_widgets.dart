import '../../../tracker/domain/entities/addiction.dart';
import '../repositories/home_widget_repository.dart';

class SyncHomeWidgets {
  SyncHomeWidgets(this._repo);
  final HomeWidgetRepository _repo;

  Future<void> call(List<Addiction> trackers) => _repo.sync(trackers);
}

