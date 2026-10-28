import '../entities/addiction.dart';

abstract class TrackerRepository {
  Future<List<Addiction>> getAll();
  Future<void> save(Addiction addiction);
  Future<void> delete(String id);
}

