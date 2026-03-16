import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {

  int eaten = 0;
  double burned = 0;

  Future loadCalories() async {
    final prefs = await SharedPreferences.getInstance();

    String today = DateTime.now().toString().split(" ")[0];

    setState(() {
      eaten = prefs.getInt("eaten_$today") ?? 0;
      burned = prefs.getDouble("burned_$today") ?? 0;
    });
  }

  @override
  void initState() {
    super.initState();
    loadCalories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Analysis"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              Text(
                "Calories Consumed: $eaten kcal",
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 10),

              Text(
                "Calories Burned: ${burned.toStringAsFixed(0)} kcal",
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 10),

              Text(
                "Net Calories: ${(eaten - burned).toStringAsFixed(0)} kcal",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Weekly Calories",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(1, 1200),
                          FlSpot(2, 1500),
                          FlSpot(3, 1000),
                          FlSpot(4, 1700),
                          FlSpot(5, 1400),
                          FlSpot(6, 1600),
                          FlSpot(7, 1300),
                        ],
                        isCurved: true,
                        barWidth: 4,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Meal Distribution",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 30,
                        title: "Breakfast",
                        color: Colors.orange,
                      ),
                      PieChartSectionData(
                        value: 40,
                        title: "Lunch",
                        color: Colors.green,
                      ),
                      PieChartSectionData(
                        value: 20,
                        title: "Dinner",
                        color: Colors.blue,
                      ),
                      PieChartSectionData(
                        value: 10,
                        title: "Snacks",
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}