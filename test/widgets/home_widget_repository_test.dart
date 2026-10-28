import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/features/tracker/domain/entities/addiction.dart';
import 'package:sanity/features/widgets/data/repositories/home_widget_repository_impl.dart';

class FakeGateway implements HomeWidgetGateway {
  final saved = <String, String>{};
  int refreshes = 0;
  bool fail = false;

  @override
  Future<void> save(String key, String value) async {
    if (fail) throw Exception('plugin missing');
    saved[key] = value;
  }

  @override
  Future<void> refresh() async => refreshes++;
}

void main() {
  test('publishes trackers as JSON with yyyy-MM-dd dates and refreshes', () async {
    final gw = FakeGateway();
    await HomeWidgetRepositoryImpl(gw).sync([
      Addiction(id: '1', name: 'Smoking', quitDate: DateTime(2026, 3, 5, 14)),
    ]);
    final decoded = jsonDecode(gw.saved['trackers']!) as List;
    expect(decoded.single, {'id': '1', 'name': 'Smoking', 'quitDate': '2026-03-05'});
    expect(gw.refreshes, 1);
  });

  test('empty list publishes an empty array', () async {
    final gw = FakeGateway();
    await HomeWidgetRepositoryImpl(gw).sync([]);
    expect(gw.saved['trackers'], '[]');
  });

  test('plugin errors are swallowed', () async {
    final gw = FakeGateway()..fail = true;
    await HomeWidgetRepositoryImpl(gw).sync([]);
    expect(gw.refreshes, 0);
  });
}

