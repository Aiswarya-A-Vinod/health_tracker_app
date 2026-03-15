import 'package:flutter/material.dart';
import '../data/met_data.dart';
import '../utils/met_calculator.dart';
import '../models/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityScreen extends StatefulWidget {
  final double userWeight;

  const ActivityScreen({super.key, required this.userWeight});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String selectedActivity = "Walking";
  final TextEditingController durationController = TextEditingController();
  double? caloriesBurned;

  List<Activity> activities = [];
  Future saveBurnedCalories(double burned) async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    await prefs.setDouble("burned_$today", burned);
  }

  void calculate() {
    final duration = int.tryParse(durationController.text);
    if (duration == null) return;

    final met = metValues[selectedActivity]!;

    final result = calculateCalories(
      met: met,
      weight: widget.userWeight,
      duration: duration,
    );

    setState(() {
      caloriesBurned = result;

      activities.add(
        Activity(
          name: selectedActivity,
          duration: duration,
          calories: result,
          time: DateTime.now(),
        ),
      );
    });

    saveBurnedCalories(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activity Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            DropdownButton<String>(
              value: selectedActivity,
              isExpanded: true,
              items: metValues.keys
                  .map((activity) => DropdownMenuItem(
                        value: activity,
                        child: Text(activity),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedActivity = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Duration (minutes)"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: calculate,
              child: const Text("Calculate"),
            ),

            const SizedBox(height: 20),

            if (caloriesBurned != null)
              Text(
                "Calories Burned: ${caloriesBurned!.toStringAsFixed(2)} kcal",
                style: const TextStyle(fontSize: 18),
              ),

            const SizedBox(height: 20),

            const Text(
              "Today's Activities",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];

                  return Card(
                    child: ListTile(
                      title: Text(activity.name),
                      subtitle: Text("${activity.duration} minutes"),
                      trailing: Text(
                        "${activity.calories.toStringAsFixed(0)} kcal",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}