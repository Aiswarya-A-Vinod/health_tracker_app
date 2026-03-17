import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/activity_screen.dart';
import 'screens/reminders_screen.dart';
import 'services/notification_service.dart';
import 'analysis_screen_page.dart';
import 'screens/medical_records_screen.dart';

// ── Palette ──────────────────────────────────────────────
const Color kScreenBg  = Color(0xFFF9FAFB);
const Color kMintBg    = Color(0xFFF5B8C0);
const Color kMintLight = Color(0xFFFCE0E3);
const Color kMintMid   = Color(0xFFE8849A);
const Color kMintDark  = Color(0xFFC95E78);
const Color kMintText  = Color(0xFF8B2D45);
const Color kPinkBg    = Color(0xFFEECBC7);
const Color kPinkLight = Color(0xFFF5E0DE);
const Color kPinkMid   = Color(0xFFC4847A);
const Color kPinkDark  = Color(0xFFA9685F);
const Color kPinkText  = Color(0xFF6B3B34);
const Color kDark      = Color(0xFF1F2937);
const Color kMid       = Color(0xFF6B7280);
const Color kMuted     = Color(0xFF9CA3AF);
const Color kWhite     = Color(0xFFFFFFFF);

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

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kWhite,
          border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kMintDark,
          unselectedItemColor: kMuted,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.directions_run),         label: "Activity"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: "Reminders"),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu),        label: "Food"),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined),        label: "Records"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart),              label: "Analysis"),
          ],
        ),
      ),
    );
  }
}

/* ──────────────── MEAL CONFIG ──────────────── */

class _MealCfg {
  final IconData icon;
  final Color    bg;
  final Color    border;
  final String   emoji;
  final int      calories;
  final int      protein;
  final int      carbs;
  final int      fat;

  const _MealCfg(
    this.icon, this.bg, this.border, this.emoji,
    this.calories, this.protein, this.carbs, this.fat,
  );
}

const Map<String, _MealCfg> kMealConfig = {
  'Breakfast': _MealCfg(Icons.free_breakfast, Color(0xFFFEF7E6), Color(0xFFF9D89A), '☕',  350, 18, 45, 10),
  'Lunch':     _MealCfg(Icons.lunch_dining,   kMintBg,           kMintMid,           '🥗', 600, 35, 65, 18),
  'Dinner':    _MealCfg(Icons.dinner_dining,  Color(0xFFF0ECF8), Color(0xFFD8C6F5), '🍽️', 700, 40, 72, 22),
  'Snacks':    _MealCfg(Icons.fastfood,       kPinkBg,           kPinkMid,           '🍪', 150,  4, 22,  6),
  'Others':    _MealCfg(Icons.rice_bowl,      kPinkLight,        kPinkMid,           '🍱', 300, 12, 38,  9),
};

/* ──────────────── MEAL MODEL ──────────────── */

class Meal {
  final String   type;
  final String   imagePath;
  final DateTime time;
  final int      calories;
  final int      protein;
  final int      carbs;
  final int      fat;

  Meal({
    required this.type,
    required this.imagePath,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
    'type':      type,
    'imagePath': imagePath,
    'time':      time.toIso8601String(),
    'calories':  calories,
    'protein':   protein,
    'carbs':     carbs,
    'fat':       fat,
  };

  factory Meal.fromJson(Map<String, dynamic> json) {
    final cfg = kMealConfig[json['type']] ?? kMealConfig['Others']!;
    return Meal(
      type:      json['type'],
      imagePath: json['imagePath'],
      time:      DateTime.parse(json['time']),
      calories:  json['calories'] ?? cfg.calories,
      protein:   json['protein']  ?? cfg.protein,
      carbs:     json['carbs']    ?? cfg.carbs,
      fat:       json['fat']      ?? cfg.fat,
    );
  }
}

/* ──────────────── CIRCULAR PROGRESS PAINTER ──────────────── */

class _RingPainter extends CustomPainter {
  final double progress;
  final Color  ringColor;
  final Color  trackColor;

  _RingPainter({required this.progress, required this.ringColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 6;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round);

    // Progress
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0, 1), false,
          Paint()
            ..color = ringColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/* ──────────────── FOOD LOGGING SCREEN ──────────────── */

class FoodLoggingScreen extends StatefulWidget {
  @override
  _FoodLoggingScreenState createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  List<Meal>   meals           = [];
  String?      _selectedMeal;
  int?         _expandedIndex;
  final        _picker = ImagePicker();
  late Timer   _clockTimer;
  String       _clockLabel = '';

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate  = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static const int kGoal = 2000;

  // ── Helpers ───────────────────────────────────────────
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Meal> mealsForDate(DateTime d) =>
      meals.where((m) => _dateKey(m.time) == _dateKey(d)).toList();

  int calForDate(DateTime d) =>
      mealsForDate(d).fold(0, (sum, m) => sum + m.calories);

  int get totalCalories =>
      mealsForDate(_selectedDate).fold(0, (sum, m) => sum + m.calories);

  int get totalProtein =>
      mealsForDate(_selectedDate).fold(0, (sum, m) => sum + m.protein);

  int get totalCarbs =>
      mealsForDate(_selectedDate).fold(0, (sum, m) => sum + m.carbs);

  int get totalFat =>
      mealsForDate(_selectedDate).fold(0, (sum, m) => sum + m.fat);

  String _formatClock() => DateFormat('hh:mm a').format(DateTime.now());

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _clockLabel = _formatClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockLabel = _formatClock());
    });
    loadMeals();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  // ── Storage ───────────────────────────────────────────
  Future<void> saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('meals', meals.map((m) => jsonEncode(m.toJson())).toList());
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
      setState(() => meals = list.map((s) => Meal.fromJson(jsonDecode(s))).toList());
    }
  }

  // ── Image picking ─────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null && _selectedMeal != null) {
      final cfg = kMealConfig[_selectedMeal!] ?? kMealConfig['Others']!;
      setState(() {
        meals.add(Meal(
          type:      _selectedMeal!,
          imagePath: photo.path,
          time:      DateTime.now(),
          calories:  cfg.calories,
          protein:   cfg.protein,
          carbs:     cfg.carbs,
          fat:       cfg.fat,
        ));
        _expandedIndex = null;
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
        mealType:  _selectedMeal ?? '',
        onCamera:  () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        onBack:    () { Navigator.pop(context); _showAddSheet(); },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────
  void _deleteMeal(Meal meal) {
    setState(() {
      meals.remove(meal);
      _expandedIndex = null;
    });
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
              _buildMealsSection(selMeals, isToday, eaten),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader(int eaten, int left, double pct, bool isToday) {
    final isOver  = left < 0;
    final pctNum  = (pct * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kMintDark, kMintBg, kPinkBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'TODAY' : DateFormat('d MMM yyyy').format(_selectedDate).toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  const Text('Food Tracker 🍽', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kWhite)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(_clockLabel, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kMintLight,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Center(
                  child: Text('JD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kMintText)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Calorie card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Ring + stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // EATEN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EATEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: kMid)),
                        const SizedBox(height: 4),
                        Text('$eaten', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kMintText)),
                        Text('kcal', style: TextStyle(fontSize: 9, color: kMuted)),
                      ],
                    ),

                    // Circular ring
                    SizedBox(
                      width: 70, height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(70, 70),
                            painter: _RingPainter(
                              progress:   pct,
                              ringColor:  isOver ? kPinkDark : kMintDark,
                              trackColor: const Color(0xFFF3F4F6),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 16, color: kMintDark),
                              Text('$pctNum%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kMintText)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // LEFT / OVER
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(isOver ? 'OVER' : 'LEFT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: kMid)),
                        const SizedBox(height: 4),
                        Text('${left.abs()}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isOver ? Colors.red : kMintText)),
                        Text('kcal', style: TextStyle(fontSize: 9, color: kMuted)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(isOver ? kPinkDark : kMintDark),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0', style: TextStyle(fontSize: 9, color: kMuted)),
                    Text('Goal: $kGoal kcal', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: kMid)),
                  ],
                ),

                const SizedBox(height: 12),

                // Macro pills
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF9FAFB)))),
                  child: Row(
                    children: [
                      _macroPill('Protein', totalProtein, 'g', const Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      _macroPill('Carbs', totalCarbs, 'g', kMintDark),
                      const SizedBox(width: 8),
                      _macroPill('Fat', totalFat, 'g', kPinkMid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroPill(String label, int val, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kScreenBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$val$unit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 8, color: kMuted)),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 2))],
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kDark),
                ),
                _calNavBtn(Icons.chevron_right, () => setState(() =>
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1))),
              ],
            ),
            const SizedBox(height: 12),
            // Weekday headers
            Row(
              children: ['Su','Mo','Tu','We','Th','Fr','Sa']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMid)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Day grid
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
                final hasLog  = calForDate(dayDate) > 0;

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
                              ? const LinearGradient(colors: [kMintDark, kMintMid])
                              : null,
                          boxShadow: isSel
                              ? [BoxShadow(color: kMintDark.withOpacity(0.4), blurRadius: 8)]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSel ? kWhite : kDark,
                            ),
                          ),
                        ),
                      ),
                      // Dot indicator for days with logged meals
                      if (hasLog && !isSel)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4, height: 4,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: kMintDark),
                        )
                      else
                        const SizedBox(height: 6),
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
  Widget _buildMealsSection(List<Meal> selMeals, bool isToday, int eaten) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? "Today's Meals" : 'Meals — ${DateFormat('d MMM').format(_selectedDate)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${selMeals.length} logged · $eaten kcal total',
                    style: const TextStyle(fontSize: 10, color: kMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state
          if (selMeals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kMintLight),
                    child: const Icon(Icons.camera_alt_outlined, size: 28, color: kMintText),
                  ),
                  const SizedBox(height: 12),
                  const Text('No meals logged yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMintText)),
                  const SizedBox(height: 4),
                  const Text('Tap + to log your first meal', style: TextStyle(fontSize: 11, color: kMuted)),
                ],
              ),
            )
          else
            // Meal cards
            Column(
              children: List.generate(selMeals.length, (idx) {
                final meal     = selMeals[idx];
                final cfg      = kMealConfig[meal.type] ?? kMealConfig['Others']!;
                final expanded = _expandedIndex == idx;
                return _MealCard(
                  meal:      meal,
                  cfg:       cfg,
                  expanded:  expanded,
                  onTap:     () => setState(() => _expandedIndex = expanded ? null : idx),
                  onDelete:  () => _deleteMeal(meal),
                );
              }),
            ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────
  Widget _fab() {
    return GestureDetector(
      onTap: _showAddSheet,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kMintDark, kMintMid],
          ),
          boxShadow: [BoxShadow(color: kMintDark.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.add, color: kWhite, size: 26),
      ),
    );
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: kMintLight),
        child: Icon(icon, size: 16, color: kMintText),
      ),
    );
  }
}

/* ──────────────── MEAL CARD (expandable) ──────────────── */

class _MealCard extends StatelessWidget {
  final Meal         meal;
  final _MealCfg     cfg;
  final bool         expanded;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.cfg,
    required this.expanded,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = meal.imagePath.isNotEmpty && File(meal.imagePath).existsSync();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: expanded ? kMintMid : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: expanded
                ? kMintDark.withOpacity(0.15)
                : Colors.black.withOpacity(0.07),
            blurRadius: expanded ? 16 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row (tappable)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Emoji/photo avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: hasPhoto
                        ? Image.file(File(meal.imagePath), width: 48, height: 48, fit: BoxFit.cover)
                        : Container(
                            width: 48, height: 48,
                            color: cfg.bg,
                            child: Center(child: Text(cfg.emoji, style: const TextStyle(fontSize: 22))),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kDark)),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('hh:mm a').format(meal.time)} · ${meal.calories} kcal',
                          style: const TextStyle(fontSize: 10, color: kMuted),
                        ),
                      ],
                    ),
                  ),

                  // Badge + delete
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: kMintLight, borderRadius: BorderRadius.circular(20)),
                        child: const Text('✓', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kMintText)),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFEE2E2)),
                          child: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded macro detail
          if (expanded)
            Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: kMintLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _expandMacro('Protein', meal.protein, 'g', const Color(0xFF6366F1)),
                  _expandMacro('Carbs', meal.carbs, 'g', kMintDark),
                  _expandMacro('Fat', meal.fat, 'g', kPinkMid),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _expandMacro(String label, int val, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white60,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$val$unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 8, color: kMid)),
          ],
        ),
      ),
    );
  }
}

/* ──────────────── BOTTOM SHEET: SELECT MEAL TYPE ──────────────── */

class _MealTypeSheet extends StatelessWidget {
  final void Function(String) onSelect;
  const _MealTypeSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          _sheetHeader('Select Meal Type', context),
          const SizedBox(height: 20),
          // 5-column grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: kMealConfig.entries.map((e) {
              final cfg = e.value;
              return GestureDetector(
                onTap: () => onSelect(e.key),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cfg.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(cfg.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(
                        e.key,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: kDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cfg.calories} kcal',
                        style: const TextStyle(fontSize: 8, color: kMuted),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ──────────────── BOTTOM SHEET: CHOOSE SOURCE ──────────────── */

class _SourceSheet extends StatelessWidget {
  final String       mealType;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onBack;

  const _SourceSheet({
    required this.mealType,
    required this.onCamera,
    required this.onGallery,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = kMealConfig[mealType] ?? kMealConfig['Others']!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header with back button
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kMintLight),
                  child: const Icon(Icons.chevron_left, size: 18, color: kMintText),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${cfg.emoji} $mealType · ${cfg.calories} kcal',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kDark),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kMintLight),
                  child: const Icon(Icons.close, size: 14, color: kMintText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Camera option
          _sourceOption(
            icon: Icons.camera_alt_rounded, iconGradient: [kMintDark, kMintMid],
            cardBg: kMintLight, title: 'Camera', subtitle: 'Take a photo',
            onTap: onCamera,
          ),
          const SizedBox(height: 10),

          // Upload option
          _sourceOption(
            icon: Icons.photo_library_outlined, iconGradient: [kPinkDark, kPinkMid],
            cardBg: kPinkLight, title: 'Upload File', subtitle: 'Choose from gallery',
            onTap: onGallery,
          ),
        ],
      ),
    );
  }

  Widget _sourceOption({
    required IconData    icon,
    required List<Color> iconGradient,
    required Color       cardBg,
    required String      title,
    required String      subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: iconGradient),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(color: iconGradient.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, color: kWhite, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted)),
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
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kDark)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: kMintLight),
          child: const Icon(Icons.close, size: 14, color: kMintText),
        ),
      ),
    ],
  );
}

