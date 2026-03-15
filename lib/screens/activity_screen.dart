import 'package:flutter/material.dart';
import '../data/met_data.dart';
import '../utils/met_calculator.dart';
import '../models/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

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

  // FILTER TODAY'S ACTIVITIES
  List<Activity> get todayActivities {
    final now = DateTime.now();

    return activities.where((activity) {
      return activity.time.year == now.year &&
          activity.time.month == now.month &&
          activity.time.day == now.day;
    }).toList();
  }

  // TOTAL CALORIES (TODAY ONLY)
  double get totalCalories {
    double total = 0;
    for (var activity in todayActivities) {
      total += activity.calories;
    }
    return total;
  }

  // ICON FUNCTION
  IconData getActivityIcon(String activityName) {
    switch (activityName) {
      case "Walking":
        return Icons.directions_walk;
      case "Running":
        return Icons.directions_run;
      case "Cycling":
        return Icons.pedal_bike;
      case "Swimming":
        return Icons.pool;
      case "Yoga":
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  // SAVE ACTIVITIES
  Future<void> saveActivities() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> activityList =
        activities.map((a) => jsonEncode(a.toJson())).toList();

    await prefs.setStringList("activities", activityList);
  }

  // LOAD ACTIVITIES
  Future<void> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? activityList = prefs.getStringList("activities");

    if (activityList != null) {
      setState(() {
        activities = activityList
            .map((a) => Activity.fromJson(jsonDecode(a)))
            .toList();
      });
    }
  }

  // CALCULATE CALORIES
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

    saveActivities();
  }

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activity Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Calories Burned Today",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${totalCalories.toStringAsFixed(0)} kcal",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                itemCount: todayActivities.length,
                itemBuilder: (context, index) {
                  final activity = todayActivities[index];

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        getActivityIcon(activity.name),
                        color: Colors.deepPurple,
                      ),
                      title: Text(activity.name),
                      subtitle: Text(
                        "${activity.duration} minutes • ${DateFormat('hh:mm a').format(activity.time)}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              "${activity.calories.toStringAsFixed(0)} kcal"),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                activities.remove(activity);
                              });
                              saveActivities();
                            },
                          ),
                        ],
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