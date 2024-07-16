import 'package:flutter/cupertino.dart';
import 'package:karman_app/components/habit/habit_tile.dart';
import 'package:karman_app/controllers/habit/habit_controller.dart';
import 'package:karman_app/models/habits/habit.dart';
import 'package:karman_app/pages/habit/habit_details_sheet.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  _HabitsPageState createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitController =
          Provider.of<HabitController>(context, listen: false);
      habitController.checkAndResetStreaks();
      habitController.loadHabits();
    });
  }

  void _showAddHabitSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => HabitDetailsSheet(
        habit: Habit(habitName: ''),
        isNewHabit: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitController>(
      builder: (context, habitController, child) {
        final incompleteHabits = habitController.habits
            .where((habit) => !habit.isCompletedToday)
            .length;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: CupertinoColors.black,
            middle: Text('$incompleteHabits habits left'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAddHabitSheet,
              child: Icon(
                CupertinoIcons.add_circled_solid,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
          ),
          child: SafeArea(
            child: habitController.habits.isEmpty
                ? Center(
                    child: Text(
                      'No habits yet. Add one to get started!',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: habitController.habits.length,
                    itemBuilder: (context, index) {
                      final habit = habitController.habits[index];
                      return HabitTile(
                        habit: habit,
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
