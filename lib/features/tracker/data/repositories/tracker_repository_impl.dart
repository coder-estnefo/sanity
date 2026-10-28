import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/addiction.dart';
import '../../domain/repositories/tracker_repository.dart';
import '../models/addiction_model.dart';

class TrackerRepositoryImpl implements TrackerRepository {
  TrackerRepositoryImpl(this._store);
  final KeyValueStore _store;
  static const _key = 'addictions';

  @override
  Future<List<Addiction>> getAll() async {
    final raw = _store.read(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => AddictionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _write(List<Addiction> list) => _store.write(
      _key, jsonEncode(list.map(AddictionModel.toJson).toList()));

  @override
  Future<void> save(Addiction addiction) async {
    final list = await getAll();
    final i = list.indexWhere((e) => e.id == addiction.id);
    if (i >= 0) {
      list[i] = addiction;
    } else {
      list.add(addiction);
    }
    await _write(list);
  }

  @override
  Future<void> delete(String id) async {
    final list = await getAll()..removeWhere((e) => e.id == id);
    await _write(list);
  }
}

