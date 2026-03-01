import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(HealthTrackerApp());
}

class HealthTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Health Tracker',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Color(0xFFF8F6FF),
      ),
      home: MainNavigationScreen(),
    );
  }
}

/* ---------------- MAIN NAVIGATION ---------------- */

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {

  int _selectedIndex = 2;

  final List<Widget> _screens = [
    Center(child: Text("Physical Activity Screen")),
    Center(child: Text("Reminders Screen")),
    FoodLoggingScreen(),
    Center(child: Text("Medical Records Screen")),
    Center(child: Text("AI Analysis Screen")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_run),
              label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: "Reminders"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: "Food"),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: "Records"),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: "Analysis"),
        ],
      ),
    );
  }
}

/* ---------------- FOOD LOGGING SCREEN ---------------- */
class Meal {
  final String type;
  final String imagePath;
  final DateTime time;

  Meal({
    required this.type,
    required this.imagePath,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'imagePath': imagePath,
      'time': time.toIso8601String(),
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      type: json['type'],
      imagePath: json['imagePath'],
      time: DateTime.parse(json['time']),
    );
  }
}

class FoodLoggingScreen extends StatefulWidget {
  @override
  _FoodLoggingScreenState createState() =>
      _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {

  List<Meal> meals = [];
  String? _selectedMeal;
  final ImagePicker _picker = ImagePicker();

  int get totalCalories => meals.length * 250;

  @override
  void initState() {
    super.initState();
    loadMeals();
  }

  Future<void> saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> mealList =
        meals.map((meal) => jsonEncode(meal.toJson())).toList();
    await prefs.setStringList('meals', mealList);
  }

  Future<void> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? mealList = prefs.getStringList('meals');

    if (mealList != null) {
      setState(() {
        meals = mealList
            .map((meal) => Meal.fromJson(jsonDecode(meal)))
            .toList();
      });
    }
  }

  Future<void> _openCamera() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera);

    if (photo != null && _selectedMeal != null) {
  setState(() {
    meals.add(
      Meal(
        type: _selectedMeal!,
        imagePath: photo.path,
        time: DateTime.now(),
      ),
    );
  });
  saveMeals(); // SAVE AFTER ADDING
}
}

  void _selectMeal(String meal) {
    setState(() {
      _selectedMeal = meal;
    });
    Navigator.pop(context);
    _openCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Food Tracker",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Track your daily meals 🍽",
                  style: TextStyle(color: Colors.grey),
                ),

                SizedBox(height: 30),

                /* -------- ADD NEW MEAL BUTTON -------- */

                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (context) {
                        return Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select Meal Type",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 20),
                              ListTile(
                                leading:
                                    Icon(Icons.free_breakfast),
                                title: Text("Breakfast"),
                                onTap: () =>
                                    _selectMeal("Breakfast"),
                              ),
                              ListTile(
                                leading:
                                    Icon(Icons.lunch_dining),
                                title: Text("Lunch"),
                                onTap: () =>
                                    _selectMeal("Lunch"),
                              ),
                              ListTile(
                                leading:
                                    Icon(Icons.dinner_dining),
                                title: Text("Dinner"),
                                onTap: () =>
                                    _selectMeal("Dinner"),
                              ),
                              ListTile(
                                leading:
                                    Icon(Icons.fastfood),
                                title: Text("Snack"),
                                onTap: () =>
                                    _selectMeal("Snack"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFCFF5E7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add New Meal",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.add_circle, size: 30),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                /* -------- IMAGE PREVIEW -------- */


                SizedBox(height: 30),
                meals.isEmpty
    ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No meals added yet",
            style: TextStyle(fontSize: 16),
          ),
        ),
      )
    : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final meal = meals[index];

         return Card(
  margin: EdgeInsets.symmetric(vertical: 8),
  child: ListTile(
    leading: Image.file(
      File(meal.imagePath),
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    ),
    title: Text(meal.type),
    subtitle: Text(
        DateFormat('hh:mm a').format(meal.time),
        style: TextStyle(fontSize: 14),
    ),

    
    trailing: IconButton(
      icon: Icon(Icons.delete, color: Colors.red),
      onPressed: () {
        setState(() {
          meals.removeAt(index);
        });
        saveMeals();
      },
    ),
  ),
);
        },
      ),

                /* -------- CALORIES CARD -------- */

                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8C8DC),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text("Today's Calories"),
                      SizedBox(height: 10),
                      Text(
                        "$totalCalories kcal",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}