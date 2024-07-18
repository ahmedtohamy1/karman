import 'package:flutter/foundation.dart';
import 'package:karman_app/models/habits/habit.dart';
import 'package:karman_app/models/habits/habit_log.dart';
import 'package:karman_app/services/habit/habit_service.dart';
import 'package:karman_app/services/notification_service.dart';

class HabitController extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  final Map<int, List<HabitLog>> _habitLogs = {};

  List<Habit> get habits => _habits;
  Map<int, List<HabitLog>> get habitLogs => _habitLogs;

  Future<void> loadHabits() async {
    await checkAndResetStreaks();
    _habits = await _habitService.getHabits();
    for (var habit in _habits) {
      await loadHabitLogs(habit.habitId!);
      habit.isCompletedToday =
          await _habitService.isHabitCompletedToday(habit.habitId!);
    }
    notifyListeners();
  }

  Future<void> loadHabitLogs(int habitId) async {
    _habitLogs[habitId] = await _habitService.getHabitLogs(habitId);
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    final id = await _habitService.createHabit(habit);
    final newHabit = habit.copyWith(habitId: id);
    _habits.add(newHabit);
    _scheduleReminder(newHabit);
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitService.updateHabit(habit);
    final index = _habits.indexWhere((h) => h.habitId == habit.habitId);
    if (index != -1) {
      _habits[index] = habit;
      _scheduleReminder(habit);
      notifyListeners();
    }
  }

  Future<void> deleteHabit(int id) async {
    await _habitService.deleteHabit(id);
    _habits.removeWhere((habit) => habit.habitId == id);
    _habitLogs.remove(id);
    NotificationService.cancelNotification(id);
    notifyListeners();
  }

  Future<void> completeHabitForToday(Habit habit, String? log) async {
    await _habitService.completeHabitForToday(habit, log);
    final updatedHabit = await _habitService.getHabit(habit.habitId!);
    if (updatedHabit != null) {
      final index = _habits.indexWhere((h) => h.habitId == habit.habitId);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
    }
    await loadHabitLogs(habit.habitId!);
    notifyListeners();
  }

  Future<void> checkAndResetStreaks() async {
    await _habitService.resetStreaksIfNeeded();
  }

  Future<void> scheduleReminders() async {
    for (var habit in _habits) {
      _scheduleReminder(habit);
    }
  }

  Future<void> _scheduleReminder(Habit habit) async {
    if (habit.reminderTime != null && habit.habitId != null) {
      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        habit.reminderTime!.inHours,
        habit.reminderTime!.inMinutes % 60,
      );

      // If the scheduled time for today has already passed, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }

      await NotificationService.scheduleNotification(
        id: habit.habitId!,
        title: 'Habit Reminder',
        body: habit.habitName,
        scheduledDate: scheduledTime,
        payload: 'habit_${habit.habitId}',
      );
    }
  }
}
