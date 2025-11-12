import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:brain_stack/models/goal_model.dart';
import 'package:brain_stack/models/goals_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialise sqflite pour l'environnement VM (tests)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('GoalsData persistence', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GoalsData.load();
    });

    test('add, update, delete goal', () async {
      final goal = Goal(
        id: 'test1',
        title: 'Test Goal',
        category: 'Other',
        target: 100.0,
        current: 0,
        deadline: '2025-12-12',
        createdAt: DateTime.now(),
        priority: 'low',
      );

      await GoalsData.addGoal(goal);
      expect(GoalsData.goals.any((g) => g.id == 'test1'), isTrue);

      final updated = goal.copyWith(title: 'Updated Test');
      await GoalsData.updateGoal(updated);
      expect(GoalsData.goals.firstWhere((g) => g.id == 'test1').title, 'Updated Test');

      await GoalsData.deleteGoal('test1');
      expect(GoalsData.goals.any((g) => g.id == 'test1'), isFalse);
    });
  });
}
