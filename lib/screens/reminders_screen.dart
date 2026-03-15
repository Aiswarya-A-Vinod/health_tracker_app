import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {

  List<Map<String, String>> reminders = [];
  Future<void> saveReminders() async {
  final prefs = await SharedPreferences.getInstance();

  List<String> reminderList =
      reminders.map((r) => jsonEncode(r)).toList();

  await prefs.setStringList("reminders", reminderList);
}
Future<void> loadReminders() async {
  final prefs = await SharedPreferences.getInstance();

  List<String>? reminderList = prefs.getStringList("reminders");

  if (reminderList != null) {
    setState(() {
      reminders =
          reminderList.map((r) => Map<String, String>.from(jsonDecode(r))).toList();
    });
  }
}

  void addReminder(String title, String time) {
    setState(() {
      reminders.add({
        "title": title,
        "time": time,
      });
    });
    saveReminders();
  }

  void showAddReminderDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Add Reminder"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Reminder Title",
                ),
              ),

              TextField(
                controller: timeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Select Time",
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {

                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {

                    final formattedTime =
                        "${pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod}:${pickedTime.minute.toString().padLeft(2, '0')} ${pickedTime.period == DayPeriod.am ? "AM" : "PM"}";

                    timeController.text = formattedTime;
                  }
                },
              ),

            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
  onPressed: () {

    DateTime now = DateTime.now();

    DateTime scheduledTime = DateFormat("hh:mm a")
        .parse(timeController.text);

    scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    NotificationService.scheduleNotification(
      titleController.text,
      "Time for your health activity",
      scheduledTime,
    );

    addReminder(
      titleController.text,
      timeController.text,
    );

    Navigator.pop(context);
  },
  child: const Text("Add"),
),

          ],
        );

      },
    );
  }
@override
void initState() {
  super.initState();
  loadReminders();
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Reminders"),
      ),

      body: reminders.isEmpty
          ? const Center(
              child: Text(
                "No reminders yet\nTap + to add one",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {

                final reminder = reminders[index];

                return Card(
                  child: ListTile(
                    title: Text(reminder["title"]!),
                    subtitle: Text(reminder["time"]!),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          reminders.removeAt(index);
                          saveReminders();
                        });
                      },
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddReminderDialog,
        child: const Icon(Icons.add),
      ),

    );
  }
}