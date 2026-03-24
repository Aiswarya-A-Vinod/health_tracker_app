import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme Colors ─────────────────────────────────────────────────────────────
const _pink1 = Color(0xFFF5B8C0);
const _pink2 = Color(0xFFE8849A);
const _pink3 = Color(0xFFC95E78);
const _pinkLight = Color(0xFFFCE0E3);
const _textAccent = Color(0xFF8B2D45);
const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF6B7280);
const _textMuted = Color(0xFF9CA3AF);

// ─── Main Screen ──────────────────────────────────────────────────────────────
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int eaten = 0;
  double burned = 0;
  bool _showMonthly = false;

  final List<FlSpot> _weeklySpots = const [
    FlSpot(1, 1200), FlSpot(2, 1500), FlSpot(3, 1000),
    FlSpot(4, 1700), FlSpot(5, 1400), FlSpot(6, 1600), FlSpot(7, 1300),
  ];

  final List<BarChartGroupData> _weeklyBarGroups = [
    _buildBarGroup(0, 1450, false),
    _buildBarGroup(1, 1820, true),
    _buildBarGroup(2, 1380, false),
    _buildBarGroup(3, 1700, false),
  ];

  final List<FlSpot> _monthlySpots = const [
    FlSpot(1,  1200), FlSpot(2,  1550), FlSpot(3,  980),  FlSpot(4,  1700),
    FlSpot(5,  1450), FlSpot(6,  1820), FlSpot(7,  1300), FlSpot(8,  1650),
    FlSpot(9,  1100), FlSpot(10, 1750), FlSpot(11, 1400), FlSpot(12, 1600),
    FlSpot(13, 1250), FlSpot(14, 1900), FlSpot(15, 1350), FlSpot(16, 1500),
    FlSpot(17, 1150), FlSpot(18, 1800), FlSpot(19, 1420), FlSpot(20, 1670),
    FlSpot(21, 1280), FlSpot(22, 1730), FlSpot(23, 1460),
  ];

  static BarChartGroupData _buildBarGroup(int x, double y, bool isMax) =>
      BarChartGroupData(x: x, barRods: [
        BarChartRodData(
          toY: y,
          width: isMax ? 14 : 12,
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isMax ? [_pink3, _pink2] : [_pinkLight, _pink1],
          ),
        ),
      ]);

  Future<void> loadCalories() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    setState(() {
      eaten = prefs.getInt('eaten_$today') ?? 0;
      burned = prefs.getDouble('burned_$today') ?? 0;
    });
  }

  @override
  void initState() {
    super.initState();
    loadCalories();
  }

  @override
  Widget build(BuildContext context) {
    final net = eaten - burned;
    final progress = (eaten / 2000.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        child: Column(
          children: [

            Stack(
              clipBehavior: Clip.none,
              children: [

                // ── Header ────────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 16,
                    20,
                    90,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [_pink1, _pink2, _pink3],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Text(
                                  'Health Analysis',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('📊', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                            // ← spacer to match Food Tracker's clock line height
                            // so the summary card doesn't overlap the title
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'JD',
                            style: TextStyle(
                              color: _pink3,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Calories Summary Card ─────────────────────────────────
                Positioned(
                  bottom: -130,
                  left: 16,
                  right: 16,
                  child: _buildSummaryCard(eaten, burned, net, progress),
                ),
              ],
            ),

            const SizedBox(height: 150),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [

                  const SizedBox(height: 8),

                  // ── Weekly Intake Line Chart ──────────────────────────────
                  _SectionCard(
                    title: 'Weekly Intake',
                    subtitle: 'Calories per day',
                    child: SizedBox(
                      height: 200,
                      child: LineChart(LineChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFF3F4F6),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                const labels = [
                                  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                                ];
                                final idx = value.toInt() - 1;
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox();
                                }
                                final isToday = idx == 2;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isToday ? _pink3 : _textMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _weeklySpots,
                            isCurved: true,
                            barWidth: 3,
                            gradient: const LinearGradient(
                              colors: [_pink1, _pink3],
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _pink2.withOpacity(0.25),
                                  _pink2.withOpacity(0.0),
                                ],
                              ),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) {
                                final isToday = spot.x == 3;
                                return FlDotCirclePainter(
                                  radius: isToday ? 5 : 3,
                                  color: isToday
                                      ? _pink3
                                      : _pink2.withOpacity(0.5),
                                  strokeWidth: isToday ? 2 : 0,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ],
                        minX: 1,
                        maxX: 7,
                        minY: 800,
                        maxY: 2000,
                      )),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Intake Overview ───────────────────────────────────────
                  _SectionCard(
                    title: 'Intake Overview',
                    subtitle: 'March 2026',
                    trailing: _ToggleChip(
                      showMonthly: _showMonthly,
                      onChanged: (val) => setState(() => _showMonthly = val),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: _showMonthly
                          ? _buildMonthlyLineChart()
                          : _buildWeeklyBarChart(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Food vs Activity ──────────────────────────────────────
                  _SectionCard(
                    title: 'Food vs Activity',
                    subtitle: net > 0
                        ? 'Calorie surplus of ${net.toStringAsFixed(0)} kcal today'
                        : 'Calorie deficit of ${net.abs().toStringAsFixed(0)} kcal today',
                    subtitleColor: _textAccent,
                    child: Column(
                      children: [
                        Row(children: [
                          _LegendDot(color: _pink2, label: 'Food Intake'),
                          const SizedBox(width: 16),
                          _LegendDot(
                            color: _pink3.withOpacity(0.5),
                            label: 'Activity Burn',
                          ),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: BarChart(BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: const Color(0xFFF3F4F6),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    const days = [
                                      'M', 'T', 'W', 'T', 'F', 'S', 'S'
                                    ];
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= days.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        days[idx],
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: _textMuted,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(7, (i) {
                              const food = [
                                1700.0, 1900.0, 1240.0, 1800.0,
                                1550.0, 2100.0, 900.0,
                              ];
                              const activity = [
                                420.0, 580.0, 380.0, 650.0,
                                470.0, 300.0, 200.0,
                              ];
                              return BarChartGroupData(
                                x: i,
                                barsSpace: 3,
                                barRods: [
                                  BarChartRodData(
                                    toY: food[i],
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                    color: _pink2,
                                  ),
                                  BarChartRodData(
                                    toY: activity[i],
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                    color: _pink3.withOpacity(0.45),
                                  ),
                                ],
                              );
                            }),
                            maxY: 2400,
                          )),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    return BarChart(BarChartData(
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFF3F4F6),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              const labels = ['W1', 'W2', 'W3', 'W4'];
              final idx = value.toInt();
              if (idx < 0 || idx >= labels.length) return const SizedBox();
              final isMax = idx == 1;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  labels[idx],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isMax ? FontWeight.bold : FontWeight.w500,
                    color: isMax ? _pink3 : _textMuted,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: _weeklyBarGroups,
      barTouchData: BarTouchData(enabled: true),
      maxY: 2200,
    ));
  }

  Widget _buildMonthlyLineChart() {
    return LineChart(LineChartData(
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFF3F4F6),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: 400,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 8, color: _textMuted),
            ),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (value, _) {
              final day = value.toInt();
              if (day % 5 != 1 && day != 23) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$day',
                  style: const TextStyle(fontSize: 9, color: _textMuted),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _monthlySpots,
          isCurved: true,
          barWidth: 2.5,
          gradient: const LinearGradient(colors: [_pink1, _pink3]),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _pink2.withOpacity(0.22),
                _pink2.withOpacity(0.0),
              ],
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) {
              final isPeak = spot.x == 14;
              return FlDotCirclePainter(
                radius: isPeak ? 5 : 0,
                color: isPeak ? _pink3 : Colors.transparent,
                strokeWidth: isPeak ? 2 : 0,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
      minX: 1,
      maxX: 23,
      minY: 800,
      maxY: 2100,
    ));
  }

  Widget _buildSummaryCard(
      int eaten, double burned, double net, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _pink1.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CalStat(label: 'CONSUMED', value: '$eaten', unit: 'kcal'),
            SizedBox(
              width: 88, height: 88,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: _pinkLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(_pink3),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: _pink2, size: 20,
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ]),
              ]),
            ),
            _CalStat(
              label: 'BURNED',
              value: burned.toStringAsFixed(0),
              unit: 'kcal',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Goal: 2000 kcal',
              style: TextStyle(
                fontSize: 11, color: _pink3, fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'NET: ${net.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                fontSize: 11,
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: _pinkLight,
            valueColor: const AlwaysStoppedAnimation<Color>(_pink3),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _MacroChip(label: 'Protein', value: '52g'),
          const SizedBox(width: 8),
          _MacroChip(label: 'Carbs', value: '142g'),
          const SizedBox(width: 8),
          _MacroChip(label: 'Fat', value: '38g'),
        ]),
      ]),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _CalStat extends StatelessWidget {
  final String label, value, unit;
  const _CalStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label,
        style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 1.2)),
    const SizedBox(height: 4),
    Text(value,
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textPrimary)),
    Text(unit,
        style: const TextStyle(fontSize: 11, color: _textMuted)),
  ]);
}

class _MacroChip extends StatelessWidget {
  final String label, value;
  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _pinkLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _textAccent)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
      ]),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color subtitleColor;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.subtitleColor = _textMuted,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                      fontStyle: subtitleColor == _textAccent
                          ? FontStyle.italic
                          : FontStyle.normal)),
            ],
          ]),
          if (trailing != null) trailing!,
        ],
      ),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _ToggleChip extends StatelessWidget {
  final bool showMonthly;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({required this.showMonthly, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _Chip(
        label: 'Weekly',
        active: !showMonthly,
        onTap: () => onChanged(false),
      ),
      _Chip(
        label: 'Monthly',
        active: showMonthly,
        onTap: () => onChanged(true),
      ),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: active
            ? [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
              )]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: active ? _pink3 : _textMuted,
        ),
      ),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _textSecondary)),
      ]);
}