double calculateCalories({
  required double met,
  required double weight,
  required int duration,
}) {
  return (met * weight * duration) / 60;
}