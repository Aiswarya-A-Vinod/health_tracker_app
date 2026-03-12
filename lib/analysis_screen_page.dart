import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

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