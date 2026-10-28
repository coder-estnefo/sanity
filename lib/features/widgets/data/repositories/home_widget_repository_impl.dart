import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../../tracker/domain/entities/addiction.dart';
import '../../domain/repositories/home_widget_repository.dart';

/// Thin seam over the home_widget plugin so the repository is testable.
abstract class HomeWidgetGateway {
  Future<void> save(String key, String value);
  Future<void> refresh();
}

class PluginHomeWidgetGateway implements HomeWidgetGateway {
  @override
  Future<void> save(String key, String value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> refresh() => HomeWidget.updateWidget(
        androidName: 'CounterWidgetProvider',
        qualifiedAndroidName: 'com.example.sanity.CounterWidgetProvider',
      );
}

class HomeWidgetRepositoryImpl implements HomeWidgetRepository {
  HomeWidgetRepositoryImpl(this._gateway);
  final HomeWidgetGateway _gateway;

  static const trackersKey = 'trackers';
  static const pinnedTrackerKey = 'pinned_tracker_id';

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<void> sync(List<Addiction> trackers) async {
    try {
      final payload = jsonEncode([
        for (final t in trackers)
          {'id': t.id, 'name': t.name, 'quitDate': _date(t.quitDate)},
      ]);
      await _gateway.save(trackersKey, payload);
      await _gateway.refresh();
    } catch (_) {
      // Widgets are best-effort; never break the app.
    }
  }

  @override
  Future<void> pinTracker(String id) async {
    try {
      await _gateway.save(pinnedTrackerKey, id);
      await _gateway.refresh();
    } catch (_) {
      // Widgets are best-effort; never break the app.
    }
  }
}
