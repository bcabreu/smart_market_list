import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GoalsNotifier extends StateNotifier<double> {
  GoalsNotifier() : super(0); // Dummy state, we use Hive directly mainly

  Box<double> get _box => Hive.box<double>('expense_goals');

  double getGoal(String key) {
    return _box.get(key, defaultValue: 1000.0) ?? 1000.0;
  }

  Future<void> setGoal(String key, double value) async {
    await _box.put(key, value);
    // Force a rebuild if needed, but for now we might rely on fetching
    // Ideally we might want a stream or map state, 
    // but the modal reads continuously or we can trigger updates.
    state = value; 
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, double>((ref) {
  return GoalsNotifier();
});
