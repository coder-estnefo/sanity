import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/features/notifications/domain/usecases/milestone_planner.dart';
import 'package:sanity/features/tracker/domain/entities/addiction.dart';

void main() {
  final now = DateTime(2026, 6, 10, 12, 0);

  group('MilestonePlanner', () {
    test('plans only future milestones for an addiction', () {
      // Addiction quit 6 days ago (2026-06-04).
      // Milestone 1 day (June 5) is in the past.
      // Milestone 7 days (June 11) is in the future.
      // Milestones 14, 30, 60, 90, 180, 365 are in the future.
      final a = Addiction(
        id: '1',
        name: 'Smoking',
        quitDate: DateTime(2026, 6, 4),
      );

      final milestones = MilestonePlanner.planMilestones(
        addictions: [a],
        now: now,
      );

      // Milestone 1 (June 5 9am) is in the past, so should be excluded.
      // Milestones 7, 14, 30, 60, 90, 180, 365 should be present.
      expect(milestones.length, 7);
      expect(milestones.first.time, DateTime(2026, 6, 11, 9, 0));
      expect(milestones.first.message, contains('7 days free from Smoking'));
    });

    test('all milestones planned when addiction quit today', () {
      final a = Addiction(
        id: '2',
        name: 'Alcohol',
        quitDate: DateTime(2026, 6, 10),
      );

      final milestones = MilestonePlanner.planMilestones(
        addictions: [a],
        now: now,
      );

      expect(milestones.length, 8); // 1, 7, 14, 30, 60, 90, 180, 365
      expect(milestones.first.time, DateTime(2026, 6, 11, 9, 0));
      expect(milestones.first.message, contains('1 days free from Alcohol'));
    });

    test('no milestones planned for empty addictions', () {
      final milestones = MilestonePlanner.planMilestones(
        addictions: [],
        now: now,
      );
      expect(milestones, isEmpty);
    });
  });
}

