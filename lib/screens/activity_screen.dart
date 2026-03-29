import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';

import '../data/met_data.dart';
import '../utils/met_calculator.dart';
import '../models/activity.dart';

// ─────────────────────────────────────────────────────────────
//  Colors
// ─────────────────────────────────────────────────────────────
class _C {
  static const background   = Color(0xFFFBF7F8);
  static const primary      = Color(0xFFE8849A);
  static const primaryLight = Color(0xFFFCE0E3);
  static const primaryDark  = Color(0xFFC95E78);
  static const accent       = Color(0xFFC4847A);
  static const cardBorder   = Color(0xFFF5E6E8);
  static const statBg       = Color(0xFFF3F0FF);
  static const statText     = Color(0xFF7C5CBF);
  static const statSub      = Color(0xFF9B8DC2);
  static const textDark     = Color(0xFF1F2937);
  static const textMedium   = Color(0xFF6B7280);
}

// ─────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────
IconData _iconFor(String name) {
  switch (name) {
    case 'Walking':  return Icons.directions_walk;
    case 'Running':  return Icons.directions_run;
    case 'Cycling':  return Icons.pedal_bike;
    case 'Swimming': return Icons.pool;
    case 'Yoga':     return Icons.self_improvement;
    default:         return Icons.fitness_center;
  }
}

List<Color> _colorsFor(String name) {
  switch (name) {
    case 'Yoga':     return [const Color(0xFFF3E8FF), const Color(0xFFA855F7)];
    case 'Running':  return [const Color(0xFFFEE2E2), const Color(0xFFEF4444)];
    case 'Walking':  return [const Color(0xFFD1FAE5), const Color(0xFF10B981)];
    case 'Swimming': return [const Color(0xFFDBEAFE), const Color(0xFF3B82F6)];
    case 'Cycling':  return [const Color(0xFFE0F2FE), const Color(0xFF0EA5E9)];
    default:         return [_C.primaryLight,          _C.primary];
  }
}

// ─────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────
class ActivityScreen extends StatefulWidget {
  final double userWeight;
  const ActivityScreen({super.key, required this.userWeight});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Activity>        activities = [];
  final Map<String, int> _durations = {};
  int  _navIndex = 0;
  bool _saving   = false;

  static const double _goalMinutes = 60;

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  // ── Derived ────────────────────────────────────────────────
  List<Activity> get todayActivities {
    final now = DateTime.now();
    return activities.where((a) =>
        a.time.year  == now.year &&
        a.time.month == now.month &&
        a.time.day   == now.day).toList();
  }

  double get totalDuration => todayActivities.fold(0, (s, a) => s + a.duration);
  double get totalCalories => todayActivities.fold(0.0, (s, a) => s + a.calories);
  int    get totalCount    => todayActivities.length;

  List<MapEntry<String, int>> get _activeDrafts =>
      _durations.entries.where((e) => e.value > 0).toList();

  // ── Actions ────────────────────────────────────────────────
  void _updateDuration(String name, int delta) =>
      setState(() => _durations[name] = ((_durations[name] ?? 0) + delta).clamp(0, 999));

  Future<void> _save() async {
    if (_activeDrafts.isEmpty) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    for (final entry in _activeDrafts) {
      final met = metValues[entry.key] ?? 4.0;
      final cal = calculateCalories(
          met: met, weight: widget.userWeight, duration: entry.value);
      activities.add(Activity(
          name: entry.key, duration: entry.value, calories: cal, time: now));
    }

    await _saveActivities();
    await _saveBurnedCalories(totalCalories);

    setState(() {
      _durations.clear();
      _saving = false;
    });
    _snack('Activities saved!');
  }

  Future<void> _delete(Activity activity) async {
    setState(() => activities.remove(activity));
    await _saveActivities();
    await _saveBurnedCalories(totalCalories);
  }

  Future<void> _saveBurnedCalories(double burned) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    await prefs.setDouble('burned_$today', burned);
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'activities',
        activities.map((a) => jsonEncode(a.toJson())).toList());
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('activities');
    if (list != null) {
      setState(() {
        activities = list
            .map((a) => Activity.fromJson(jsonDecode(a)))
            .toList();
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _C.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasDrafts = _activeDrafts.isNotEmpty;
    final progress  = (totalDuration / _goalMinutes).clamp(0.0, 1.0);
    final remaining = (_goalMinutes - totalDuration).clamp(0.0, _goalMinutes);
    final timeStr   = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: _C.background,
      body: Stack(
        children: [

          // ── Scrollable body ────────────────────────────────
          CustomScrollView(
            slivers: [

              // Header
              SliverToBoxAdapter(
                child: _buildHeader(timeStr),
              ),

              // Summary card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildSummaryCard(progress, remaining),
                ),
              ),

              // "Select Activities" label
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Select Activities',
                          style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.textDark)),
                      Text('TODAY',
                          style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: _C.textMedium)),
                    ],
                  ),
                ),
              ),

              // Activity grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing:  12,
                    childAspectRatio: 1.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final name = metValues.keys.toList()[i];
                      final dur  = _durations[name] ?? 0;
                      final cal  = calculateCalories(
                          met:      metValues[name]!,
                          weight:   widget.userWeight,
                          duration: dur);
                      return _ActivityCard(
                        name:     name,
                        duration: dur,
                        calories: cal,
                        onUpdate: (d) => _updateDuration(name, d),
                      );
                    },
                    childCount: metValues.length,
                  ),
                ),
              ),

              // "Today's Activities" label
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Activities",
                          style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.textDark)),
                      if (todayActivities.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${todayActivities.length} logged'
                            ' · ${totalCalories.toStringAsFixed(0)} kcal total',
                            style: const TextStyle(fontSize: 12,
                                color: _C.textMedium,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // History list
              todayActivities.isEmpty
                  ? SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverToBoxAdapter(
                          child: _buildEmptyState()),
                    )
                  : SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final act = todayActivities[i];
                            return _HistoryItem(
                              activity: act,
                              onDelete: () => _delete(act),
                            );
                          },
                          childCount: todayActivities.length,
                        ),
                      ),
                    ),
            ],
          ),

          // ── Save FAB ───────────────────────────────────────
          if (hasDrafts)
            Positioned(
              bottom: 16,
              right:  16,
              child:  _SaveFab(
                saving: _saving,
                count:  _activeDrafts.length,
                onTap:  _save,
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(String timeStr) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFE8849A),
          Color(0xFFF3A6B3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TODAY',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Physical Activity 🏃',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70)),
                  ]),
                ],
              ),
            ),

            // profile icon
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('JD',
                  style: TextStyle(
                      color: _C.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ── Summary Card ────────────────────────────────────────────
  Widget _buildSummaryCard(double progress, double remaining) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:         Colors.white,
        borderRadius:  BorderRadius.circular(24),
        border:        Border.all(color: _C.cardBorder),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset:     const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // DONE · ring · LEFT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatLabel(
                  label: 'DONE',
                  value: totalDuration.toStringAsFixed(0),
                  unit:  'min'),
              _RingProgress(progress: progress),
              _StatLabel(
                  label: 'LEFT',
                  value: remaining.toStringAsFixed(0),
                  unit:  'min',
                  right: true),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:          progress,
              minHeight:      6,
              backgroundColor: _C.primaryLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_C.primary),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Goal: 60 min',
                style: TextStyle(
                    fontSize:   10,
                    color:      _C.textMedium,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 14),

          // Stat pills
          Row(children: [
            _StatPill(value: '$totalCount',                          label: 'Activities'),
            const SizedBox(width: 8),
            _StatPill(value: '${totalDuration.toStringAsFixed(0)}m', label: 'Duration'),
            const SizedBox(width: 8),
            _StatPill(value: totalCalories.toStringAsFixed(0),       label: 'Calories'),
          ]),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
          color:         Colors.white,
          borderRadius:  BorderRadius.circular(20),
          border:        Border.all(color: _C.cardBorder)),
      child: const Column(children: [
        CircleAvatar(
          radius:          28,
          backgroundColor: _C.primaryLight,
          child: Icon(Icons.directions_run, color: _C.primary, size: 28),
        ),
        SizedBox(height: 12),
        Text('No activities yet',
            style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      _C.textDark)),
        SizedBox(height: 4),
        Text('Select activities above and tap save!',
            style: TextStyle(fontSize: 12, color: _C.textMedium)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Activity Grid Card
// ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final String  name;
  final int     duration;
  final double  calories;
  final void Function(int) onUpdate;

  const _ActivityCard({
    required this.name,
    required this.duration,
    required this.calories,
    required this.onUpdate,
  });

  bool get _active => duration > 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:         Colors.white,
        borderRadius:  BorderRadius.circular(20),
        border: Border.all(
            color: _active ? _C.primary : _C.cardBorder,
            width: _active ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
              color: _active
                  ? _C.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _active ? 14 : 6,
              offset:     const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + name row
          Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                  color: _active ? _C.primary : _C.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_iconFor(name),
                  color: _active ? Colors.white : _C.primaryDark,
                  size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      _C.textDark)),
            ),
          ]),

          const Spacer(),

          // Stepper + calorie row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // +/- stepper
              Container(
                decoration: BoxDecoration(
                    color:         const Color(0xFFFBF7F8),
                    borderRadius:  BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFF0E4E6))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _StepBtn(
                    icon:  Icons.remove,
                    onTap: duration > 0 ? () => onUpdate(-5) : null,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('$duration',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      _C.textDark)),
                  ),
                  _StepBtn(icon: Icons.add, onTap: () => onUpdate(5)),
                ]),
              ),

              // Calories
              Row(children: [
                Icon(Icons.local_fire_department,
                    size:  14,
                    color: _active
                        ? _C.accent
                        : _C.textMedium.withOpacity(0.4)),
                const SizedBox(width: 2),
                Text(calories.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color: _active
                            ? _C.accent
                            : _C.textMedium.withOpacity(0.4))),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stepper Button
// ─────────────────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(icon,
          size:  15,
          color: onTap != null ? _C.primary : _C.cardBorder),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  History Item
// ─────────────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final Activity     activity;
  final VoidCallback onDelete;
  const _HistoryItem({required this.activity, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(activity.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(
            '${activity.name}_${activity.time.millisecondsSinceEpoch}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
              color:         Colors.red.shade400,
              borderRadius:  BorderRadius.circular(20)),
          child: const Icon(Icons.delete, color: Colors.white, size: 22),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:         Colors.white,
            borderRadius:  BorderRadius.circular(20),
            border:        Border.all(color: _C.cardBorder),
            boxShadow: [
              BoxShadow(
                  color:      Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset:     const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            // Colored circle
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                  color: colors[0], shape: BoxShape.circle),
              child: Icon(_iconFor(activity.name),
                  color: colors[1], size: 22),
            ),
            const SizedBox(width: 12),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name,
                      style: const TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      _C.textDark)),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('hh:mm a').format(activity.time)}'
                    ' · ${activity.calories.toStringAsFixed(0)} kcal'
                    ' · ${activity.duration} min',
                    style: const TextStyle(
                        fontSize:   11,
                        color:      _C.textMedium,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Check + delete
            Row(children: [
              Container(
                width:  32,
                height: 32,
                decoration: const BoxDecoration(
                    color: _C.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.check,
                    size: 16, color: _C.primary),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  width:  32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: _C.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: _C.primary),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Activity',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove "${activity.name}" from history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Save FAB
// ─────────────────────────────────────────────────────────────
class _SaveFab extends StatelessWidget {
  final bool         saving;
  final int          count;
  final VoidCallback onTap;
  const _SaveFab(
      {required this.saving,
      required this.count,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        width:  56,
        height: 56,
        decoration: BoxDecoration(
          color:  _C.primary,
          shape:  BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color:      _C.primary.withOpacity(0.4),
                blurRadius: 16,
                offset:     const Offset(0, 6))
          ],
        ),
        child: saving
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Stack(alignment: Alignment.center, children: [
                const Icon(Icons.check,
                    color: Colors.white, size: 26),
                Positioned(
                  top:   8,
                  right: 8,
                  child: Container(
                    width:  16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$count',
                        style: const TextStyle(
                            fontSize:   9,
                            fontWeight: FontWeight.w800,
                            color:      _C.primary)),
                  ),
                ),
              ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  Circular Ring Progress
// ─────────────────────────────────────────────────────────────
class _RingProgress extends StatelessWidget {
  final double progress;
  const _RingProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  110,
      height: 110,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(progress * 100).round()}%',
                style: const TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w800,
                    color:      _C.textDark,
                    height:     1)),
            const Text('of goal',
                style: TextStyle(
                    fontSize:   10,
                    color:      _C.textMedium,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint  = Paint()
      ..strokeWidth = 10
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    paint.color = _C.primaryLight;
    canvas.drawCircle(center, radius, paint);

    paint.color = _C.primary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  Small stat widgets
// ─────────────────────────────────────────────────────────────
class _StatLabel extends StatelessWidget {
  final String label, value, unit;
  final bool   right;
  const _StatLabel({
    required this.label,
    required this.value,
    required this.unit,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize:      9,
              fontWeight:    FontWeight.w800,
              letterSpacing: 1.5,
              color:         _C.textMedium)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(
              fontSize:   30,
              fontWeight: FontWeight.w800,
              color:      _C.textDark,
              height:     1)),
      Text(unit,
          style: const TextStyle(
              fontSize:   11,
              color:      _C.textMedium,
              fontWeight: FontWeight.w500)),
    ],
  );
}

class _StatPill extends StatelessWidget {
  final String value, label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color:         _C.statBg,
          borderRadius:  BorderRadius.circular(16)),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w800,
                color:      _C.statText)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize:      9,
                fontWeight:    FontWeight.w600,
                color:         _C.statSub,
                letterSpacing: 0.5)),
      ]),
    ),
  );
}