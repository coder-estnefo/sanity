import '../../../tracker/domain/entities/addiction.dart';

abstract class HomeWidgetRepository {
  /// Publishes the tracker list to the native widgets and refreshes them.
  /// Must never throw: widget problems must not break the app.
  Future<void> sync(List<Addiction> trackers);

  /// Pins a specific tracker id to be displayed by default on the home-screen widget.
  Future<void> pinTracker(String id);
}
