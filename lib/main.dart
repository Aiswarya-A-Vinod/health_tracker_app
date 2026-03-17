import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/activity_screen.dart';
import 'screens/reminders_screen.dart';
import 'services/notification_service.dart';
import 'analysis_screen_page.dart';
import 'screens/medical_records_screen.dart';

// ── Palette ──────────────────────────────────────────────
const Color kScreenBg  = Color(0xFFFCE8EC);  // bright light pink screen bg
const Color kMintBg    = Color(0xFFF5B8C0);  // bright light pink card bg (DOMINANT)
const Color kMintLight = Color(0xFFFCE0E3);  // bright very light pink
const Color kMintMid   = Color(0xFFE8849A);  // vivid mid pink accent
const Color kMintDark  = Color(0xFFC95E78);  // vivid deep pink for buttons/FAB
const Color kMintText  = Color(0xFF8B2D45);  // deep pink text
const Color kPinkBg    = Color(0xFFEECBC7);  // terracotta card bg  (accent)
const Color kPinkLight = Color(0xFFF5E0DE);  // very light terracotta
const Color kPinkMid   = Color(0xFFC4847A);  // terracotta accent
const Color kPinkDark  = Color(0xFFA9685F);  // base terracotta
const Color kPinkText  = Color(0xFF6B3B34);  // terracotta text
const Color kCalBg     = Color(0xFFFCE0E3);  // calendar bg — bright light pink


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
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
        scaffoldBackgroundColor: kScreenBg,
        fontFamily: 'Inter',
      ),
      home: MainNavigationScreen(),
    );
  }
}

/* ──────────────── MAIN NAVIGATION ──────────────── */

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;

  final List<Widget> _screens = [
    ActivityScreen(userWeight: 60.0),
    RemindersScreen(),
    FoodLoggingScreen(),
    MedicalRecordsScreen(),
    AnalysisScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [kMintLight, kPinkLight]),
          border: Border(top: BorderSide(color: kMintMid, width: 1.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kMintText,
          unselectedItemColor: Color(0xFFB0A0B0),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.directions_run),      label: "Activity"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: "Reminders"),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu),     label: "Food"),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined),     label: "Records"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart),           label: "Analysis"),
          ],
        ),
      ),
    );
  }
}

/* ──────────────── MEAL MODEL (unchanged) ──────────────── */

class Meal {
  final String type;
  final String imagePath;
  final DateTime time;

  Meal({required this.type, required this.imagePath, required this.time});

  Map<String, dynamic> toJson() => {
        'type': type,
        'imagePath': imagePath,
        'time': time.toIso8601String(),
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        type: json['type'],
        imagePath: json['imagePath'],
        time: DateTime.parse(json['time']),
      );
}

/* ──────────────── FOOD LOGGING SCREEN ──────────────── */

class FoodLoggingScreen extends StatefulWidget {
  @override
  _FoodLoggingScreenState createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  List<Meal> meals        = [];
  String? _selectedMeal;
  final ImagePicker _picker = ImagePicker();

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate  = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static const int kGoal       = 2000;
  static const int kCalPerMeal = 250;

  // ── Meal type config ──────────────────────────────────
  static const Map<String, _MealCfg> mealConfig = {
    'Breakfast': _MealCfg(Icons.free_breakfast, Color(0xFFFEF7E6), Color(0xFFF9D89A), '☕'),
    'Lunch':     _MealCfg(Icons.lunch_dining,   kMintBg,           kMintMid,           '🥗'),
    'Dinner':    _MealCfg(Icons.dinner_dining,  Color(0xFFF0ECF8), Color(0xFFD8C6F5), '🍽️'),
    'Snack':     _MealCfg(Icons.fastfood,       kPinkBg,           kPinkMid,           '🍪'),
  };

  // ── Helpers ───────────────────────────────────────────
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Meal> mealsForDate(DateTime d) =>
      meals.where((m) => _dateKey(m.time) == _dateKey(d)).toList();

  int calForDate(DateTime d) => mealsForDate(d).length * kCalPerMeal;

  int get totalCalories => mealsForDate(_selectedDate).length * kCalPerMeal;

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    loadMeals();
  }

  // ── Storage (unchanged from original) ─────────────────
  Future<void> saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'meals', meals.map((m) => jsonEncode(m.toJson())).toList());
  }

  Future<void> saveDailyCalories() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    await prefs.setInt('eaten_$today', totalCalories);
  }

  Future<void> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('meals');
    if (list != null) {
      setState(() {
        meals = list.map((s) => Meal.fromJson(jsonDecode(s))).toList();
      });
    }
  }

  // ── Image picking ─────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null && _selectedMeal != null) {
      setState(() {
        meals.add(Meal(type: _selectedMeal!, imagePath: photo.path, time: DateTime.now()));
      });
      saveMeals();
      saveDailyCalories();
    }
  }

  // ── Bottom sheets ─────────────────────────────────────
  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MealTypeSheet(
        onSelect: (type) {
          setState(() => _selectedMeal = type);
          Navigator.pop(context);
          _showSourceSheet();
        },
      ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SourceSheet(
        mealType: _selectedMeal ?? '',
        onCamera:  () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        onBack:    () { Navigator.pop(context); _showAddSheet(); },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────
  void _deleteMeal(Meal meal) {
    setState(() => meals.remove(meal));
    saveMeals();
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final selMeals = mealsForDate(_selectedDate);
    final eaten    = totalCalories;
    final left     = kGoal - eaten;
    final pct      = (eaten / kGoal).clamp(0.0, 1.0);
    final isToday  = _dateKey(_selectedDate) == _dateKey(DateTime.now());

    return Scaffold(
      backgroundColor: kScreenBg,
      floatingActionButton: _fab(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(eaten, left, pct, isToday),
              _buildCalendar(),
              _buildMealsSection(selMeals, isToday),
              _buildSummary(selMeals, eaten, left),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with calorie card ──────────────────────────
  Widget _buildHeader(int eaten, int left, double pct, bool isToday) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kMintBg, kPinkLight, kPinkBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? 'TODAY' : DateFormat('d MMM yyyy').format(_selectedDate).toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: kMintText),
          ),
          const SizedBox(height: 2),
          const Text('Food Tracker 🍽', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 2),
          const Text('Track your daily meals', style: TextStyle(fontSize: 13, color: Color(0xFFA78CA0))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kMintLight, kPinkLight]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kMintMid, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statColumn('EATEN', '$eaten kcal', kMintText, CrossAxisAlignment.start),
                    Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [kMintDark, Color(0xFF6EE7B7)]),
                      ),
                      child: const Icon(Icons.local_fire_department, color: Colors.white, size: 22),
                    ),
                    _statColumn('LEFT', '${left.abs()} kcal', left >= 0 ? kMintText : Colors.red, CrossAxisAlignment.end),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct, minHeight: 10,
                    backgroundColor: kMintMid,
                    valueColor: AlwaysStoppedAnimation<Color>(pct > 0.95 ? kPinkDark : kMintDark),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Goal: $kGoal kcal', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color valueColor, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  // ── Calendar ──────────────────────────────────────────
  Widget _buildCalendar() {
    final firstDay    = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCalBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPinkMid, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            // Month navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _calNavBtn(Icons.chevron_left, () => setState(() =>
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1))),
                Text(
                  DateFormat('MMMM yyyy').format(_calendarMonth),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
                ),
                _calNavBtn(Icons.chevron_right, () => setState(() =>
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1))),
              ],
            ),
            const SizedBox(height: 10),
            // Day-of-week row
            Row(
              children: ['Su','Mo','Tu','We','Th','Fr','Sa']
                  .map((d) => Expanded(
                        child: Center(child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kPinkText))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1,
              ),
              itemCount: startOffset + daysInMonth,
              itemBuilder: (_, i) {
                if (i < startOffset) return const SizedBox.shrink();
                final day     = i - startOffset + 1;
                final dayDate = DateTime(_calendarMonth.year, _calendarMonth.month, day);
                final isSel   = _dateKey(dayDate) == _dateKey(_selectedDate);
                final cal     = calForDate(dayDate);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = dayDate),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSel
                              ? const LinearGradient(colors: [kPinkDark, Color(0xFFFB7AC0)])
                              : null,
                          boxShadow: isSel
                              ? [BoxShadow(color: kPinkDark.withOpacity(0.3), blurRadius: 6)]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      if (cal > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white.withOpacity(0.35) : kMintMid,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$cal',
                            style: TextStyle(
                              fontSize: 7, fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : kMintText,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Meals section ─────────────────────────────────────
  Widget _buildMealsSection(List<Meal> selMeals, bool isToday) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? "Today's Meals" : 'Meals — ${DateFormat('d MMM').format(_selectedDate)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
              Row(
                children: mealConfig.keys.map((type) {
                  final cnt = selMeals.where((m) => m.type == type).length;
                  if (cnt == 0) return const SizedBox.shrink();
                  final cfg = mealConfig[type]!;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cfg.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cfg.border),
                    ),
                    child: Text('${cfg.emoji} $cnt', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          selMeals.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: kMintLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kMintMid, width: 1.5),
                  ),
                  child: const Column(
                    children: [
                      Text('🥗', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 8),
                      Text('No meals logged yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kMintText)),
                      SizedBox(height: 4),
                      Text('Tap + to add your first meal', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                )
              : Column(
                  children: selMeals.asMap().entries.map((e) {
                    final idx  = e.key;
                    final meal = e.value;
                    return _MealCard(
                      meal: meal,
                      cfg: mealConfig[meal.type] ?? mealConfig['Snack']!,
                      cardBg:     idx.isEven ? kMintLight : kPinkLight,
                      cardBorder: idx.isEven ? kMintMid   : kPinkMid,
                      onDelete: () => _deleteMeal(meal),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────
  Widget _buildSummary(List<Meal> selMeals, int eaten, int left) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kPinkBg, kPinkLight, kMintLight]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPinkMid, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Calories", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPinkText)),
            const SizedBox(height: 4),
            Text('$eaten kcal', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryTile('Meals', '${selMeals.length}', kPinkBg, kPinkMid, kPinkText, isLeft: true),
                _summaryTile('Goal', '$kGoal', kMintBg, kMintMid, kMintText),
                _summaryTile(
                  left >= 0 ? 'Left' : 'Over',
                  '${left.abs()}',
                  left >= 0 ? kMintBg : kPinkBg,
                  left >= 0 ? kMintMid : kPinkMid,
                  left >= 0 ? kMintText : const Color(0xFFE11D48),
                  isRight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────
  Widget _fab() {
    return GestureDetector(
      onTap: _showAddSheet,
      child: Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [kMintDark, Color(0xFF6EE7B7)]),
          boxShadow: [BoxShadow(color: Color(0x4016A34A), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────
  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: kPinkBg),
        child: Icon(icon, size: 14, color: kPinkText),
      ),
    );
  }

  Widget _summaryTile(String label, String val, Color bg, Color border, Color textColor,
      {bool isLeft = false, bool isRight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.horizontal(
            left:  isLeft  ? const Radius.circular(12) : Radius.zero,
            right: isRight ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }
}

/* ──────────────── MEAL CONFIG ──────────────── */

class _MealCfg {
  final IconData icon;
  final Color bg;
  final Color border;
  final String emoji;
  const _MealCfg(this.icon, this.bg, this.border, this.emoji);
}

/* ──────────────── MEAL CARD ──────────────── */

class _MealCard extends StatelessWidget {
  final Meal meal;
  final _MealCfg cfg;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal, required this.cfg,
    required this.cardBg, required this.cardBorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = meal.imagePath.isNotEmpty && File(meal.imagePath).existsSync();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Meal photo or emoji
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasPhoto
                ? Image.file(File(meal.imagePath), width: 48, height: 48, fit: BoxFit.cover)
                : Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: cfg.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cfg.border, width: 1.5),
                    ),
                    child: Center(child: Text(cfg.emoji, style: const TextStyle(fontSize: 22))),
                  ),
          ),
          const SizedBox(width: 12),
          // Meal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cfg.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cfg.border),
                      ),
                      child: Text(meal.type, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                    ),
                    const SizedBox(width: 6),
                    Text(DateFormat('hh:mm a').format(meal.time), style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    if (hasPhoto) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                        child: const Text('📷 Photo', style: TextStyle(fontSize: 9, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Calories + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('🔥 250 kcal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kMintText)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFE4E6)),
                  child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFF87171)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ──────────────── BOTTOM SHEET: SELECT MEAL TYPE ──────────────── */

class _MealTypeSheet extends StatelessWidget {
  final void Function(String) onSelect;
  const _MealTypeSheet({required this.onSelect});

  static const Map<String, _MealCfg> _cfg = {
    'Breakfast': _MealCfg(Icons.free_breakfast, Color(0xFFFEF7E6), Color(0xFFF9D89A), '☕'),
    'Lunch':     _MealCfg(Icons.lunch_dining,   kMintBg,           kMintMid,           '🥗'),
    'Dinner':    _MealCfg(Icons.dinner_dining,  Color(0xFFF0ECF8), Color(0xFFD8C6F5), '🍽️'),
    'Snack':     _MealCfg(Icons.fastfood,       kPinkBg,           kPinkMid,           '🍪'),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [kPinkLight, kMintLight],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHeader('Select Meal Type', context),
          const SizedBox(height: 16),
          ..._cfg.entries.map((e) {
            final cfg = e.value;
            return GestureDetector(
              onTap: () => onSelect(e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cfg.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cfg.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.7)),
                      child: Icon(cfg.icon, size: 18, color: const Color(0xFF555555)),
                    ),
                    const SizedBox(width: 12),
                    Text(e.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/* ──────────────── BOTTOM SHEET: CHOOSE SOURCE ──────────────── */

class _SourceSheet extends StatelessWidget {
  final String mealType;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onBack;

  const _SourceSheet({
    required this.mealType, required this.onCamera,
    required this.onGallery, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [kPinkLight, kMintLight],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHeader('Add $mealType', context),
          const SizedBox(height: 16),
          // Camera
          _sourceOption(
            icon: Icons.camera_alt, iconBg: kMintDark, cardBg: kMintBg, cardBorder: kMintMid,
            title: 'Take Photo', subtitle: 'Open camera and capture your meal',
            onTap: onCamera,
          ),
          const SizedBox(height: 10),
          // Gallery
          _sourceOption(
            icon: Icons.photo_library_outlined, iconBg: kPinkDark, cardBg: kPinkBg, cardBorder: kPinkMid,
            title: 'Upload from Gallery', subtitle: 'Choose a photo from your files',
            onTap: onGallery,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onBack,
            child: const Row(
              children: [
                Icon(Icons.chevron_left, size: 16, color: kPinkText),
                Text('Back', style: TextStyle(fontSize: 13, color: kPinkText, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon, required Color iconBg,
    required Color cardBg, required Color cardBorder,
    required String title, required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ──────────────── SHARED SHEET HEADER ──────────────── */

Widget _sheetHeader(String title, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: kPinkBg),
          child: const Icon(Icons.close, size: 14, color: kPinkText),
        ),
      ),
    ],
  );
}
