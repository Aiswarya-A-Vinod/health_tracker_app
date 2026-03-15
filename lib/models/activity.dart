class Activity {
  final String name;
  final int duration;
  final double calories;
  final DateTime time;

  Activity({
    required this.name,
    required this.duration,
    required this.calories,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration': duration,
      'calories': calories,
      'time': time.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name'],
      duration: json['duration'],
      calories: json['calories'],
      time: DateTime.parse(json['time']),
    );
  }
}