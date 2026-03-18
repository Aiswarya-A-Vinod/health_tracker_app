import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// ── Palette ───────────────────────────────────────────────
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

// ── Reminder Model ────────────────────────────────────────
class Reminder {
  final String id;
  final String title;
  final String type;
  final String time;
  final String date;
  final String repeat;
  final bool   isEnabled;
  final String notificationType;
  final String smartType;

  const Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.date,
    required this.repeat,
    this.isEnabled        = true,
    this.notificationType = 'Local',
    this.smartType        = '',
  });

  Reminder copyWith({
    String? title,
    String? type,
    String? time,
    String? date,
    String? repeat,
    bool?   isEnabled,
    String? notificationType,
    String? smartType,
  }) =>
      Reminder(
        id:               id,
        title:            title            ?? this.title,
        type:             type             ?? this.type,
        time:             time             ?? this.time,
        date:             date             ?? this.date,
        repeat:           repeat           ?? this.repeat,
        isEnabled:        isEnabled        ?? this.isEnabled,
        notificationType: notificationType ?? this.notificationType,
        smartType:        smartType        ?? this.smartType,
      );

  Map<String, dynamic> toJson() => {
        'id':               id,
        'title':            title,
        'type':             type,
        'time':             time,
        'date':             date,
        'repeat':           repeat,
        'isEnabled':        isEnabled,
        'notificationType': notificationType,
        'smartType':        smartType,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id:               j['id']               as String,
        title:            j['title']            as String,
        type:             j['type']             as String,
        time:             (j['time']            as String?) ?? '',
        date:             (j['date']            as String?) ?? '',
        repeat:           (j['repeat']          as String?) ?? 'Daily',
        isEnabled:        (j['isEnabled']       as bool?)   ?? true,
        notificationType: (j['notificationType']as String?) ?? 'Local',
        smartType:        (j['smartType']       as String?) ?? '',
      );
}

// ── Category metadata ─────────────────────────────────────
const List<Map<String, String>> _kCategories = [
  {'key': 'Medicine', 'emoji': '💊', 'label': 'Medicine', 'sub': 'Pills & doses'},
  {'key': 'Checkup',  'emoji': '🏥', 'label': 'Checkup',  'sub': 'Doctor visits'},
  {'key': 'Smart',    'emoji': '🤖', 'label': 'Smart',    'sub': 'AI suggestions'},
  {'key': 'Custom',   'emoji': '⏰', 'label': 'Custom',   'sub': 'Your own alerts'},
];

// ── Elegant Clock Picker ──────────────────────────────────

/// A modal dialog that lets the user pick a time by interacting
/// with an analog clock face — tapping numbers or dragging the hand.
class _ClockPickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  const _ClockPickerDialog({required this.initialTime});

  @override
  State<_ClockPickerDialog> createState() => _ClockPickerDialogState();
}

enum _ClockMode { hour, minute }

class _ClockPickerDialogState extends State<_ClockPickerDialog> {
  late int        _hour;   // 0-11
  late int        _minute; // 0-59
  late DayPeriod  _period;
  _ClockMode      _mode = _ClockMode.hour;

  @override
  void initState() {
    super.initState();
    _hour   = widget.initialTime.hourOfPeriod; // 0-11
    _minute = widget.initialTime.minute;
    _period = widget.initialTime.period;
  }

  // Convert a clock angle (0° = 12 o'clock, clockwise) to hour (0-11)
  int _angleToHour(double angleDeg) {
    final h = (angleDeg / 30).round() % 12;
    return h;
  }

  // Convert clock angle to minute (0-59)
  int _angleToMinute(double angleDeg) {
    final m = (angleDeg / 6).round() % 60;
    return m;
  }

  // Angle from the center of the clock given a local Offset
  double _offsetToAngle(Offset center, Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    double angle = atan2(dy, dx) * 180 / pi + 90;
    if (angle < 0) angle += 360;
    return angle;
  }

  void _handlePanUpdate(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle  = _offsetToAngle(center, localPos);
    setState(() {
      if (_mode == _ClockMode.hour) {
        _hour = _angleToHour(angle);
      } else {
        _minute = _angleToMinute(angle);
      }
    });
  }

  String get _displayHour {
    final h = _hour == 0 ? 12 : _hour;
    return h.toString().padLeft(2, '0');
  }

  String get _displayMinute => _minute.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color:        kWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.15),
              blurRadius: 32,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Time display ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hour button
                GestureDetector(
                  onTap: () => setState(() => _mode = _ClockMode.hour),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _mode == _ClockMode.hour
                          ? kMintLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _displayHour,
                      style: TextStyle(
                        fontSize:   44,
                        fontWeight: FontWeight.w800,
                        color: _mode == _ClockMode.hour
                            ? kMintDark
                            : kDark,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                // Colon
                const Text(
                  ':',
                  style: TextStyle(
                    fontSize:   40,
                    fontWeight: FontWeight.w300,
                    color:      kMid,
                    height:     1.1,
                  ),
                ),
                // Minute button
                GestureDetector(
                  onTap: () => setState(() => _mode = _ClockMode.minute),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _mode == _ClockMode.minute
                          ? kMintLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _displayMinute,
                      style: TextStyle(
                        fontSize:   44,
                        fontWeight: FontWeight.w800,
                        color: _mode == _ClockMode.minute
                            ? kMintDark
                            : kDark,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // AM / PM column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ampmBtn('AM'),
                    const SizedBox(height: 6),
                    _ampmBtn('PM'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Hour / Minute mode tabs ──────────────────
            Container(
              padding:    const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color:        kScreenBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeTab('Hour',   _ClockMode.hour),
                  _modeTab('Minute', _ClockMode.minute),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Analog clock face ────────────────────────
            SizedBox(
              width:  260,
              height: 260,
              child: GestureDetector(
                onPanStart: (d) => _handlePanUpdate(
                    d.localPosition,
                    const Size(260, 260)),
                onPanUpdate: (d) => _handlePanUpdate(
                    d.localPosition,
                    const Size(260, 260)),
                onTapDown: (d) => _handlePanUpdate(
                    d.localPosition,
                    const Size(260, 260)),
                child: CustomPaint(
                  painter: _ClockFacePainter(
                    hour:   _hour,
                    minute: _minute,
                    mode:   _mode,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _mode == _ClockMode.hour
                  ? 'Tap or drag to set hour'
                  : 'Tap or drag to set minute',
              style: const TextStyle(fontSize: 11, color: kMuted),
            ),
            const SizedBox(height: 20),

            // ── Action buttons ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color:        kScreenBg,
                        borderRadius: BorderRadius.circular(14),
                        border:       Border.all(
                            color: kMintLight, width: 1.5),
                      ),
                      child: const Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w700,
                                color:      kMid)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      final hour24 = _period == DayPeriod.am
                          ? _hour
                          : (_hour == 0 ? 12 : _hour + 12);
                      Navigator.pop(
                        context,
                        TimeOfDay(hour: hour24, minute: _minute),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [kMintDark, kMintMid]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color:      kMintDark.withOpacity(0.40),
                              blurRadius: 14,
                              offset:     const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                        child: Text('Confirm',
                            style: TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.bold,
                                color:      kWhite)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ampmBtn(String label) {
    final selected = (label == 'AM')
        ? _period == DayPeriod.am
        : _period == DayPeriod.pm;
    return GestureDetector(
      onTap: () => setState(() =>
          _period = label == 'AM' ? DayPeriod.am : DayPeriod.pm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [kMintDark, kMintMid])
              : null,
          color:        selected ? null : kScreenBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w700,
            color:      selected ? kWhite : kMuted,
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String label, _ClockMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [kMintDark, kMintMid])
              : null,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w700,
            color:      active ? kWhite : kMuted,
          ),
        ),
      ),
    );
  }
}

// ── Clock face painter ────────────────────────────────────
class _ClockFacePainter extends CustomPainter {
  final int        hour;   // 0-11
  final int        minute; // 0-59
  final _ClockMode mode;

  _ClockFacePainter({
    required this.hour,
    required this.minute,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final radius = size.width  / 2 - 4;

    // ── Face background ──────────────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 0.9,
        colors: [kMintLight, kPinkLight],
      ).createShader(Rect.fromCircle(
          center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    // Outer border
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = kMintMid.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Tick marks ───────────────────────────────────────
    for (int i = 0; i < 60; i++) {
      final isHourTick = i % 5 == 0;
      final angleDeg   = i * 6.0;
      final angleRad   = (angleDeg - 90) * pi / 180;
      final inner      = isHourTick ? radius - 14 : radius - 9;
      final outer      = radius - 4;
      canvas.drawLine(
        Offset(cx + inner * cos(angleRad), cy + inner * sin(angleRad)),
        Offset(cx + outer * cos(angleRad), cy + outer * sin(angleRad)),
        Paint()
          ..color       = isHourTick
              ? kMintMid.withOpacity(0.7)
              : kMintLight
          ..strokeWidth = isHourTick ? 2 : 1
          ..strokeCap   = StrokeCap.round,
      );
    }

    // ── Numbers ──────────────────────────────────────────
    final numbers  = mode == _ClockMode.hour
        ? List.generate(12, (i) => i == 0 ? 12 : i)
        : List.generate(12, (i) => i * 5);
    final numRadius = radius - 30;

    for (int i = 0; i < 12; i++) {
      final num      = numbers[i];
      final angleDeg = i * 30.0;
      final angleRad = (angleDeg - 90) * pi / 180;
      final ox       = cx + numRadius * cos(angleRad);
      final oy       = cy + numRadius * sin(angleRad);

      final bool selected = mode == _ClockMode.hour
          ? (hour == (num % 12))
          : (minute == num);

      // Highlight circle for selected number
      if (selected) {
        canvas.drawCircle(
          Offset(ox, oy),
          17,
          Paint()
            ..color = kMintDark
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(ox, oy),
          17,
          Paint()..color = kMintDark,
        );
      }

      // Number text
      final tp = TextPainter(
        text: TextSpan(
          text: mode == _ClockMode.hour
              ? num.toString()
              : num.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize:   13,
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? kWhite : kDark,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(ox - tp.width / 2, oy - tp.height / 2),
      );
    }

    // ── Clock hand ───────────────────────────────────────
    final handAngleDeg = mode == _ClockMode.hour
        ? hour * 30.0
        : minute * 6.0;
    final handAngleRad = (handAngleDeg - 90) * pi / 180;
    final handLength   = numRadius - 2;
    final handTip      = Offset(
      cx + handLength * cos(handAngleRad),
      cy + handLength * sin(handAngleRad),
    );
    final knobPos = Offset(
      cx + (handLength + 10) * cos(handAngleRad),
      cy + (handLength + 10) * sin(handAngleRad),
    );

    // Hand line
    canvas.drawLine(
      Offset(cx, cy),
      handTip,
      Paint()
        ..color       = kMintDark.withOpacity(0.85)
        ..strokeWidth = 3
        ..strokeCap   = StrokeCap.round,
    );

    // Knob glow
    canvas.drawCircle(
      knobPos,
      12,
      Paint()
        ..color      = kMintDark.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Knob fill
    canvas.drawCircle(knobPos, 12, Paint()..color = kMintDark);
    // Knob inner dot
    canvas.drawCircle(knobPos, 4.5, Paint()..color = kWhite);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 5.5, Paint()..color = kMintDark);
    canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = kWhite);
  }

  @override
  bool shouldRepaint(_ClockFacePainter old) =>
      old.hour != hour || old.minute != minute || old.mode != mode;
}

// ── Screen ────────────────────────────────────────────────
class RemindersScreen extends StatefulWidget {
  final String? userInitials;
  const RemindersScreen({super.key, this.userInitials});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  // Reminders start empty — user creates them
  List<Reminder> _reminders = [];

  // Water intake tracking — true only if user tapped "Done" today
  bool   _waterLoggedToday = false;
  String _waterLogDate     = ''; // stored as 'yyyy-MM-dd'

  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _loadReminders();
    _loadWaterLog();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('reminders_v2');
    if (list != null) {
      setState(() {
        _reminders = list
            .map((s) =>
                Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'reminders_v2',
        _reminders.map((r) => jsonEncode(r.toJson())).toList());
  }

  // ── Water log persistence ─────────────────────────────────
  Future<void> _loadWaterLog() async {
    final prefs   = await SharedPreferences.getInstance();
    final stored  = prefs.getString('water_log_date') ?? '';
    final today   = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      // Only counts if it was logged today
      _waterLoggedToday = stored == today;
      _waterLogDate     = stored;
    });
  }

  Future<void> _logWaterToday() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('water_log_date', today);
    setState(() {
      _waterLoggedToday = true;
      _waterLogDate     = today;
    });
    _showSnack('Water intake logged ✓');
  }

  // ── CRUD ──────────────────────────────────────────────────
  void _addReminder(Reminder r) {
    setState(() => _reminders.add(r));
    _saveReminders();
    _showSnack('Reminder added ✓');
  }

  void _updateReminder(Reminder r) {
    setState(() {
      final i = _reminders.indexWhere((x) => x.id == r.id);
      if (i >= 0) _reminders[i] = r;
    });
    _saveReminders();
    _showSnack('Reminder updated ✓');
  }

  void _deleteReminder(String id) {
    setState(() => _reminders.removeWhere((r) => r.id == id));
    _saveReminders();
    _showSnack('Reminder deleted');
  }

  void _toggleReminder(String id, bool val) {
    setState(() {
      final i = _reminders.indexWhere((r) => r.id == id);
      if (i >= 0) _reminders[i] = _reminders[i].copyWith(isEnabled: val);
    });
    _saveReminders();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenBg,
      floatingActionButton: _buildFAB(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCategoryCards()),
          // Show water card only when user hasn't logged water today
          if (!_waterLoggedToday)
            SliverToBoxAdapter(child: _buildWaterIntakeCard()),
          SliverToBoxAdapter(child: _buildReminderList()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    final activeCount = _reminders.where((r) => r.isEnabled).length;
    final typeCount   = _kCategories
        .where((c) => _reminders.any((r) => r.type == c['key']))
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [kMintDark, kMintBg, kPinkBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:  MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HEALTH TRACKER',
                    style: TextStyle(
                      fontSize:      10,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 2.5,
                      color:         Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Row(children: [
                    Text(
                      'Reminders',
                      style: TextStyle(
                          fontSize:   24,
                          fontWeight: FontWeight.bold,
                          color:      kWhite),
                    ),
                    SizedBox(width: 8),
                    Text('🔔', style: TextStyle(fontSize: 22)),
                  ]),
                  const SizedBox(height: 2),
                  const Text(
                    'Manage your health alerts',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              Container(
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  color:  kMintLight,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.userInitials ?? 'U',
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.bold,
                        color:      kMintText),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerChip('${_reminders.length} Total'),
              const SizedBox(width: 8),
              _headerChip('$activeCount Active'),
              const SizedBox(width: 8),
              _headerChip('$typeCount Types'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color:        Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      kWhite)),
      );

  // ── Category Cards ────────────────────────────────────────
  Widget _buildCategoryCards() {
    const gradients = <List<Color>>[
      [kMintDark, kMintMid],
      [kMintMid,  kMintBg],
      [kPinkMid,  kMintMid],
      [kPinkDark, kPinkMid],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Categories',
                style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.bold,
                    color:      kDark)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 114,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:         const EdgeInsets.symmetric(horizontal: 16),
              itemCount:       _kCategories.length,
              itemBuilder: (_, i) {
                final cat   = _kCategories[i];
                final count = _reminders
                    .where((r) => r.type == cat['key'])
                    .length;
                return GestureDetector(
                  onTap: () =>
                      _showAddReminderSheet(initialType: cat['key']),
                  child: Container(
                    width:   114,
                    margin:  const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradients[i],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color:      gradients[i][0].withOpacity(0.30),
                          blurRadius: 14,
                          offset:     const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat['emoji']!,
                            style: const TextStyle(fontSize: 26)),
                        const Spacer(),
                        Text(cat['label']!,
                            style: const TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.bold,
                                color:      kWhite)),
                        Text(
                          count > 0 ? '$count set' : cat['sub']!,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white70),
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
    );
  }

  // ── Water Intake Card ─────────────────────────────────────
  // Only shown when _waterLoggedToday == false (user hasn't drunk
  // water yet today). "✓ Done" logs intake; "Set alert" opens the
  // reminder sheet to create a Smart/Water reminder.
  Widget _buildWaterIntakeCard() => Container(
        margin:  const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kMintLight, kPinkBg]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: kMintMid.withOpacity(0.28), width: 1),
        ),
        child: Row(
          children: [
            // Water drop icon
            Container(
              width:  46,
              height: 46,
              decoration: BoxDecoration(
                color:  kWhite,
                shape:  BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color:      kMintMid.withOpacity(0.20),
                      blurRadius: 8)
                ],
              ),
              child: const Center(
                  child: Text('💧', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            // Message
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You missed water intake today 💧',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      kMintText)),
                  SizedBox(height: 2),
                  Text('Stay hydrated for better health',
                      style: TextStyle(fontSize: 10, color: kMuted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Action buttons column
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // "Done" — marks water as consumed, hides card
                GestureDetector(
                  onTap: _logWaterToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color:        kWhite,
                      borderRadius: BorderRadius.circular(9),
                      border:       Border.all(
                          color: kMintMid, width: 1.5),
                    ),
                    child: const Text('✓ Done',
                        style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w700,
                            color:      kMintText)),
                  ),
                ),
                const SizedBox(height: 6),
                // "Set alert" — opens reminder sheet
                GestureDetector(
                  onTap: () =>
                      _showAddReminderSheet(initialType: 'Smart'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [kMintDark, kMintMid]),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                            color:      kMintDark.withOpacity(0.35),
                            blurRadius: 8,
                            offset:     const Offset(0, 3))
                      ],
                    ),
                    child: const Text('Set alert',
                        style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.bold,
                            color:      kWhite)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ── Reminder List ─────────────────────────────────────────
  Widget _buildReminderList() {
    final active   = _reminders.where((r) => r.isEnabled).toList();
    final disabled = _reminders.where((r) => !r.isEnabled).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Reminders',
                  style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.bold,
                      color:      kDark)),
              Text('${_reminders.length} total',
                  style:
                      const TextStyle(fontSize: 11, color: kMuted)),
            ],
          ),
          const SizedBox(height: 12),
          if (_reminders.isEmpty)
            _buildEmptyState()
          else ...[
            if (active.isNotEmpty) ...[
              _sectionLabel('🟢  Active'),
              const SizedBox(height: 8),
              ...active.map(_buildReminderCard),
            ],
            if (disabled.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionLabel('⚫  Disabled'),
              const SizedBox(height: 8),
              ...disabled.map(_buildReminderCard),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          color:         kMid,
          letterSpacing: 0.3));

  Widget _buildEmptyState() => Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44),
        decoration: BoxDecoration(
          color:        kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset:     const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              width:  64,
              height: 64,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: kMintLight),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 30, color: kMintText),
            ),
            const SizedBox(height: 12),
            const Text('No reminders added yet',
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      kMintText)),
            const SizedBox(height: 4),
            const Text('Tap + to set your first health reminder',
                style: TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
      );

  Widget _buildReminderCard(Reminder r) {
    final info     = _typeInfo(r.type);
    final accent   = info['accent'] as Color;
    final accentBg = info['bg']     as Color;

    return Dismissible(
      key:       Key(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        margin:    const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline,
            color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => _deleteReminder(r.id),
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: r.isEnabled ? accentBg : const Color(0xFFF3F4F6),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset:     const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                  color:        accentBg,
                  borderRadius: BorderRadius.circular(13)),
              child: Center(
                  child: Text(info['emoji'] as String,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(r.title,
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.bold,
                              color: r.isEnabled ? kDark : kMuted),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    _typeBadge(r.type, accent, accentBg),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: kMuted),
                    const SizedBox(width: 3),
                    Text(r.time,
                        style: const TextStyle(
                            fontSize: 11, color: kMuted)),
                    if (r.date.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_outlined,
                          size: 10, color: kMuted),
                      const SizedBox(width: 3),
                      Text(r.date,
                          style: const TextStyle(
                              fontSize: 10, color: kMuted)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    _repeatBadge(r.repeat),
                    if (r.smartType.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _smartBadge(r.smartType),
                    ],
                  ]),
                ],
              ),
            ),
            // Toggle + action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value:              r.isEnabled,
                    onChanged:          (v) => _toggleReminder(r.id, v),
                    activeColor:        kMintDark,
                    activeTrackColor:   kMintLight,
                    inactiveThumbColor: kMuted,
                    inactiveTrackColor: const Color(0xFFE5E7EB),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Row(children: [
                  _iconBtn(
                    icon:  Icons.edit_outlined,
                    bg:    kMintLight,
                    fg:    kMintText,
                    onTap: () =>
                        _showAddReminderSheet(editReminder: r),
                  ),
                  const SizedBox(width: 4),
                  _iconBtn(
                    icon:  Icons.delete_outline,
                    bg:    const Color(0xFFFEE2E2),
                    fg:    const Color(0xFFEF4444),
                    onTap: () => _deleteReminder(r.id),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData    icon,
    required Color       bg,
    required Color       fg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width:      28,
          height:     28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child:      Icon(icon, size: 13, color: fg),
        ),
      );

  Widget _typeBadge(String type, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(type,
            style: TextStyle(
                fontSize:   9,
                fontWeight: FontWeight.w700,
                color:      fg)),
      );

  Widget _repeatBadge(String repeat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color:        kScreenBg,
            borderRadius: BorderRadius.circular(6)),
        child: Text(repeat,
            style: const TextStyle(
                fontSize:   9,
                color:      kMuted,
                fontWeight: FontWeight.w600)),
      );

  Widget _smartBadge(String type) {
    const emojis = {'Water': '💧', 'Sugar': '🍬', 'Activity': '🏃'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color:        kMintLight,
          borderRadius: BorderRadius.circular(6)),
      child: Text('${emojis[type] ?? '🤖'} $type',
          style: const TextStyle(
              fontSize:   9,
              color:      kMintText,
              fontWeight: FontWeight.w600)),
    );
  }

  // ── FAB ───────────────────────────────────────────────────
  Widget _buildFAB() => GestureDetector(
        onTap: () => _showAddReminderSheet(),
        child: Container(
          width:  54,
          height: 54,
          decoration: BoxDecoration(
            shape:    BoxShape.circle,
            gradient: const LinearGradient(
                colors: [kMintDark, kMintMid]),
            boxShadow: [
              BoxShadow(
                  color:      kMintDark.withOpacity(0.50),
                  blurRadius: 18,
                  offset:     const Offset(0, 6))
            ],
          ),
          child: const Icon(Icons.add, color: kWhite, size: 26),
        ),
      );

  // ── Add / Edit Bottom Sheet ───────────────────────────────
  void _showAddReminderSheet({
    String?   initialType,
    Reminder? editReminder,
  }) {
    final isEdit     = editReminder != null;
    String type      = editReminder?.type             ?? initialType ?? 'Medicine';
    String titleVal  = editReminder?.title            ?? '';
    String time      = editReminder?.time             ?? '';
    String date      = editReminder?.date             ?? '';
    String repeat    = editReminder?.repeat           ?? 'Daily';
    String notifType = editReminder?.notificationType ?? 'Local';
    String smartType = editReminder?.smartType        ?? 'Water';

    final titleCtrl = TextEditingController(text: titleVal);

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
            decoration: const BoxDecoration(
              color:        kWhite,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:       MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width:  40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sheet title row
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Reminder' : 'New Reminder 🔔',
                        style: const TextStyle(
                            fontSize:   17,
                            fontWeight: FontWeight.bold,
                            color:      kDark),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width:  30,
                          height: 30,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kMintLight),
                          child: const Icon(Icons.close,
                              size: 14, color: kMintText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Category selector ─────────────────
                  _sheetLabel('Category'),
                  const SizedBox(height: 10),
                  Row(
                    children: _kCategories.map((cat) {
                      final selected = type == cat['key'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheet(() => type = cat['key']!),
                          child: Container(
                            margin:  const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? kMintLight
                                  : kScreenBg,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected
                                      ? kMintMid
                                      : Colors.transparent,
                                  width: 1.5),
                            ),
                            child: Column(children: [
                              Text(cat['emoji']!,
                                  style: const TextStyle(
                                      fontSize: 18)),
                              const SizedBox(height: 3),
                              Text(cat['key']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize:   9,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? kMintText
                                          : kMuted)),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ────────────────────────────
                  _sheetLabel('Reminder Title'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    onChanged:  (v) => titleVal = v,
                    style: const TextStyle(
                        fontSize: 13, color: kDark),
                    decoration: _inputDeco(
                        'e.g. Morning Vitamins, Blood Test…'),
                  ),
                  const SizedBox(height: 14),

                  // ── Date row ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _sheetLabel('Date (optional)'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked =
                                    await showDatePicker(
                                  context:     context,
                                  initialDate: DateTime.now(),
                                  firstDate:   DateTime.now(),
                                  lastDate:    DateTime.now().add(
                                      const Duration(days: 365)),
                                  builder: (c, child) => Theme(
                                    data: ThemeData.light().copyWith(
                                        colorScheme:
                                            const ColorScheme.light(
                                          primary:   kMintDark,
                                          onPrimary: kWhite,
                                        )),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setSheet(() => date =
                                      DateFormat('d MMM yyyy')
                                          .format(picked));
                                }
                              },
                              child: _pickerTile(
                                icon:  Icons.calendar_today_outlined,
                                value: date.isEmpty
                                    ? 'Select date'
                                    : date,
                                empty: date.isEmpty,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Elegant Clock Picker ──────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _sheetLabel('Time'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                // Parse existing time for initial value
                                TimeOfDay initial =
                                    TimeOfDay.now();
                                if (time.isNotEmpty) {
                                  try {
                                    final parsed = DateFormat(
                                            'h:mm a')
                                        .parse(time);
                                    initial = TimeOfDay(
                                        hour:   parsed.hour,
                                        minute: parsed.minute);
                                  } catch (_) {}
                                }

                                // Show our custom clock dialog
                                final picked =
                                    await showDialog<TimeOfDay>(
                                  context: context,
                                  builder: (_) =>
                                      _ClockPickerDialog(
                                          initialTime: initial),
                                );

                                if (picked != null) {
                                  final h = picked.hourOfPeriod == 0
                                      ? 12
                                      : picked.hourOfPeriod;
                                  final m = picked.minute
                                      .toString()
                                      .padLeft(2, '0');
                                  final p =
                                      picked.period == DayPeriod.am
                                          ? 'AM'
                                          : 'PM';
                                  setSheet(() => time = '$h:$m $p');
                                }
                              },
                              child: _pickerTile(
                                icon:  Icons.access_time_rounded,
                                value: time.isEmpty
                                    ? 'Select time'
                                    : time,
                                empty: time.isEmpty,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Smart sub-type ────────────────────
                  if (type == 'Smart') ...[
                    _sheetLabel('Smart Suggestions'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final s in [
                          {'key': 'Water',    'emoji': '💧'},
                          {'key': 'Sugar',    'emoji': '🍬'},
                          {'key': 'Activity', 'emoji': '🏃'},
                        ])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheet(
                                  () => smartType = s['key']!),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    right: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 11),
                                decoration: BoxDecoration(
                                  color: smartType == s['key']
                                      ? kMintLight
                                      : kScreenBg,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: smartType == s['key']
                                          ? kMintMid
                                          : Colors.transparent,
                                      width: 1.5),
                                ),
                                child: Column(children: [
                                  Text(s['emoji']!,
                                      style: const TextStyle(
                                          fontSize: 20)),
                                  const SizedBox(height: 3),
                                  Text(s['key']!,
                                      style: TextStyle(
                                          fontSize:   10,
                                          fontWeight: FontWeight.w700,
                                          color: smartType ==
                                                  s['key']
                                              ? kMintText
                                              : kMuted)),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Repeat ───────────────────────────
                  _sheetLabel('Repeat'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Daily', 'Weekly', 'Weekdays', 'Once']
                        .map((opt) {
                      final sel = repeat == opt;
                      return GestureDetector(
                        onTap: () =>
                            setSheet(() => repeat = opt),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: sel
                                ? const LinearGradient(
                                    colors: [kMintDark, kMintMid])
                                : null,
                            color: sel ? null : kScreenBg,
                            borderRadius:
                                BorderRadius.circular(20),
                            border: sel
                                ? null
                                : Border.all(
                                    color: kMintLight, width: 1.5),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                              color: sel ? kWhite : kMid,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // ── Notification type ─────────────────
                  _sheetLabel('Notification Type'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final n in [
                        {
                          'key':   'Local',
                          'icon':  Icons.notifications_outlined,
                          'label': 'Local',
                        },
                        {
                          'key':   'Push',
                          'icon':  Icons.send_outlined,
                          'label': 'Push (Firebase)',
                        },
                      ])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheet(
                                () => notifType =
                                    n['key'] as String),
                            child: Container(
                              margin: const EdgeInsets.only(
                                  right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: notifType == n['key']
                                    ? kMintLight
                                    : kScreenBg,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        notifType == n['key']
                                            ? kMintMid
                                            : Colors.transparent,
                                    width: 1.5),
                              ),
                              child: Column(children: [
                                Icon(n['icon'] as IconData,
                                    size: 18,
                                    color: notifType == n['key']
                                        ? kMintText
                                        : kMuted),
                                const SizedBox(height: 4),
                                Text(n['label'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize:   10,
                                        fontWeight: FontWeight.w700,
                                        color: notifType ==
                                                n['key']
                                            ? kMintText
                                            : kMuted)),
                              ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // ── Cancel + Submit ───────────────────
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: kScreenBg,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: kMintLight, width: 1.5),
                            ),
                            child: const Center(
                              child: Text('Cancel',
                                  style: TextStyle(
                                      fontSize:   14,
                                      fontWeight: FontWeight.w700,
                                      color:      kMid)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            final t = titleCtrl.text.trim();
                            if (t.isEmpty) {
                              _showSnack(
                                  'Please enter a reminder title');
                              return;
                            }
                            if (time.isEmpty) {
                              _showSnack('Please select a time');
                              return;
                            }

                            final reminder = Reminder(
                              id: isEdit
                                  ? editReminder!.id
                                  : DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                              title:            t,
                              type:             type,
                              time:             time,
                              date:             date,
                              repeat:           repeat,
                              isEnabled:        isEdit
                                  ? editReminder!.isEnabled
                                  : true,
                              notificationType: notifType,
                              smartType: type == 'Smart'
                                  ? smartType
                                  : '',
                            );

                            // Schedule notification
                            try {
                              final parsed =
                                  DateFormat('h:mm a').parse(time);
                              final now  = DateTime.now();
                              final sched = DateTime(
                                now.year, now.month, now.day,
                                parsed.hour, parsed.minute,
                              );
                              NotificationService.scheduleNotification(
                                t,
                                'Time for your health activity',
                                sched,
                              );
                            } catch (_) {}

                            if (isEdit) {
                              _updateReminder(reminder);
                            } else {
                              _addReminder(reminder);
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [kMintDark, kMintMid]),
                              borderRadius:
                                  BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: kMintDark
                                        .withOpacity(0.40),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Center(
                              child: Text(
                                isEdit
                                    ? 'Update Reminder'
                                    : 'Add Reminder',
                                style: const TextStyle(
                                    fontSize:   14,
                                    fontWeight: FontWeight.bold,
                                    color:      kWhite),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sheet helpers ─────────────────────────────────────────
  Widget _sheetLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w600,
          color:      kMid));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(fontSize: 13, color: kMuted),
        filled:    true,
        fillColor: kScreenBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: kMintLight, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: kMintLight, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: kMintMid, width: 1.5)),
      );

  Widget _pickerTile({
    required IconData icon,
    required String   value,
    required bool     empty,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:        kScreenBg,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: kMintLight, width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: kMintText),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    color:    empty ? kMuted : kDark)),
          ),
        ]),
      );

  // ── Colour lookup ─────────────────────────────────────────
  Map<String, dynamic> _typeInfo(String type) {
    switch (type) {
      case 'Medicine':
        return {'emoji': '💊', 'accent': kMintText, 'bg': kMintLight};
      case 'Checkup':
        return {'emoji': '🏥', 'accent': kPinkDark, 'bg': kPinkLight};
      case 'Smart':
        return {'emoji': '🤖', 'accent': kMintDark, 'bg': kMintLight};
      case 'Custom':
        return {'emoji': '⏰', 'accent': kPinkText, 'bg': kPinkBg};
      default:
        return {'emoji': '🔔', 'accent': kMintText, 'bg': kMintLight};
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(msg),
        backgroundColor: kMintDark,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
