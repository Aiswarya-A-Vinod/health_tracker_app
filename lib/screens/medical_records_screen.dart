import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Palette (same as main.dart) ──────────────────────────
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

// ── Models ────────────────────────────────────────────────

class HealthCondition {
  final String id;
  final String name;
  final String status;
  final String summary;
  final String startDate;
  final String duration;
  final List<String> prescriptions;
  final String notes;
  final bool isPast;
  final String period;

  HealthCondition({
    required this.id,
    required this.name,
    required this.status,
    required this.summary,
    required this.startDate,
    required this.duration,
    required this.prescriptions,
    required this.notes,
    this.isPast = false,
    this.period = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'summary': summary,
    'startDate': startDate,
    'duration': duration,
    'prescriptions': prescriptions,
    'notes': notes,
    'isPast': isPast,
    'period': period,
  };

  factory HealthCondition.fromJson(Map<String, dynamic> j) => HealthCondition(
    id: j['id'],
    name: j['name'],
    status: j['status'],
    summary: j['summary'] ?? '',
    startDate: j['startDate'] ?? '',
    duration: j['duration'] ?? '',
    prescriptions: List<String>.from(j['prescriptions'] ?? []),
    notes: j['notes'] ?? '',
    isPast: j['isPast'] ?? false,
    period: j['period'] ?? '',
  );
}

class Medicine {
  final String id;
  final String name;
  final String purpose;
  final bool isCurrent;
  final String dosage;
  final String period;

  Medicine({
    required this.id,
    required this.name,
    required this.purpose,
    required this.isCurrent,
    required this.dosage,
    required this.period,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'purpose': purpose,
    'isCurrent': isCurrent,
    'dosage': dosage,
    'period': period,
  };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
    id: j['id'],
    name: j['name'],
    purpose: j['purpose'] ?? '',
    isCurrent: j['isCurrent'] ?? true,
    dosage: j['dosage'] ?? '',
    period: j['period'] ?? '',
  );
}

class MedReport {
  final String id;
  final String title;
  final DateTime date;
  final String source;
  final String filePath;
  final String notes;

  MedReport({
    required this.id,
    required this.title,
    required this.date,
    required this.source,
    required this.filePath,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'source': source,
    'filePath': filePath,
    'notes': notes,
  };

  factory MedReport.fromJson(Map<String, dynamic> j) => MedReport(
    id: j['id'],
    title: j['title'],
    date: DateTime.parse(j['date']),
    source: j['source'],
    filePath: j['filePath'] ?? '',
    notes: j['notes'] ?? '',
  );
}

// ── Screen ────────────────────────────────────────────────

class MedicalRecordsScreen extends StatefulWidget {
  final String? userInitials;

  const MedicalRecordsScreen({super.key, this.userInitials});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<HealthCondition> _conditions = [];
  List<Medicine> _medicines = [];
  List<MedReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Persistence ──────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final cList = prefs.getStringList('mr_conditions');
    final mList = prefs.getStringList('mr_medicines');
    final rList = prefs.getStringList('mr_reports');

    setState(() {
      _conditions = cList != null
          ? cList.map((s) => HealthCondition.fromJson(jsonDecode(s))).toList()
          : [];
      _medicines = mList != null
          ? mList.map((s) => Medicine.fromJson(jsonDecode(s))).toList()
          : [];
      _reports = rList != null
          ? rList.map((s) => MedReport.fromJson(jsonDecode(s))).toList()
          : [];
    });
  }

  Future<void> _saveConditions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'mr_conditions', _conditions.map((c) => jsonEncode(c.toJson())).toList());
  }

  Future<void> _saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'mr_medicines', _medicines.map((m) => jsonEncode(m.toJson())).toList());
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'mr_reports', _reports.map((r) => jsonEncode(r.toJson())).toList());
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final current = _conditions.where((c) => !c.isPast).toList();
    final past    = _conditions.where((c) => c.isPast).toList();

    return Scaffold(
      backgroundColor: kScreenBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(current, past)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: kMintDark,
                unselectedLabelColor: kMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorColor: kMintDark,
                indicatorWeight: 2.5,
                dividerColor: const Color(0xFFF3F4F6),
                tabs: const [
                  Tab(icon: Icon(Icons.medical_services_outlined, size: 18), text: 'Current'),
                  Tab(icon: Icon(Icons.history, size: 18), text: 'Past'),
                  Tab(icon: Icon(Icons.medication_outlined, size: 18), text: 'Medicines'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _CurrentTab(
              conditions: current,
              onAdd: () => _showAddConditionSheet(isPast: false),
              onDelete: (c) {
                setState(() => _conditions.remove(c));
                _saveConditions();
              },
            ),
            _PastTab(
              conditions: past,
              onAdd: () => _showAddConditionSheet(isPast: true),
              onDelete: (c) {
                setState(() => _conditions.remove(c));
                _saveConditions();
              },
            ),
            _MedicinesTab(
              medicines: _medicines,
              onAdd: _showAddMedicineSheet,
              onDelete: (m) {
                setState(() => _medicines.remove(m));
                _saveMedicines();
              },
            ),
          ],
        ),
      ),
      bottomSheet: _ReportsSection(
        reports: _reports,
        onCamera: () => _addReport('Camera'),
        onUpload: () => _addReport('Upload'),
        onDelete: (r) {
          setState(() => _reports.remove(r));
          _saveReports();
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(List<HealthCondition> current, List<HealthCondition> past) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HEALTH RECORDS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        letterSpacing: 3, color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'My Medical Records 🏥',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kWhite),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ]),
                ],
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kMintLight,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: Center(
                  child: Text(widget.userInitials ?? 'U',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kMintText)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            _summaryChip('${current.length} Conditions'),
            const SizedBox(width: 8),
            _summaryChip('${_medicines.where((m) => m.isCurrent).length} Medicines'),
            const SizedBox(width: 8),
            _summaryChip('${_reports.length} Reports'),
          ]),
        ],
      ),
    );
  }

  Widget _summaryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kWhite)),
    );
  }

  // ── Add Condition Sheet ───────────────────────────────────

  void _showAddConditionSheet({required bool isPast}) {
    final nameCtrl   = TextEditingController();
    final startCtrl  = TextEditingController();
    final rxCtrl     = TextEditingController();
    final notesCtrl  = TextEditingController();
    final periodCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                _sheetHeader(isPast ? 'Add Past Condition' : 'Add Condition'),
                const SizedBox(height: 20),
                _formField('Condition Name', 'e.g. Diabetes, Thyroid', nameCtrl),
                if (!isPast) ...[
                  const SizedBox(height: 12),
                  _formField('Start Date', 'e.g. Jan 2023', startCtrl),
                ] else ...[
                  const SizedBox(height: 12),
                  _formField('Time Period', 'e.g. Jan 2024 – Feb 2024', periodCtrl),
                ],
                const SizedBox(height: 12),
                _formField('Duration', 'e.g. 3 weeks', startCtrl),
                const SizedBox(height: 12),
                _formField('Prescriptions', 'e.g. Metformin 500mg, Dolo 650mg', rxCtrl),
                const SizedBox(height: 12),
                _formField('Notes', 'Any additional notes', notesCtrl, maxLines: 3),
                const SizedBox(height: 20),
                _primaryBtn(
                  label: 'Save Condition',
                  onTap: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final c = HealthCondition(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      status: isPast ? 'Recovered' : 'Ongoing',
                      summary: '',
                      startDate: startCtrl.text.trim(),
                      duration: startCtrl.text.trim(),
                      prescriptions: rxCtrl.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList(),
                      notes: notesCtrl.text.trim(),
                      isPast: isPast,
                      period: periodCtrl.text.trim(),
                    );
                    setState(() => _conditions.add(c));
                    _saveConditions();
                    Navigator.pop(context);
                    _showSnack(isPast ? 'Past condition added' : 'Condition added');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Add Medicine Sheet ────────────────────────────────────

  void _showAddMedicineSheet() {
    final nameCtrl    = TextEditingController();
    final purposeCtrl = TextEditingController();
    final dosageCtrl  = TextEditingController();
    final periodCtrl  = TextEditingController();
    bool isCurrent = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  _sheetHeader('Add Medicine'),
                  const SizedBox(height: 20),
                  _formField('Medicine Name', 'e.g. Metformin 500mg', nameCtrl),
                  const SizedBox(height: 12),
                  _formField('Purpose', 'e.g. Blood sugar control', purposeCtrl),
                  const SizedBox(height: 12),
                  _formField('Dosage', 'e.g. 1 tablet twice daily', dosageCtrl),
                  const SizedBox(height: 12),
                  _formField('Time Period', 'e.g. Jan 2023 – Present', periodCtrl),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Status',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMid)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => isCurrent = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isCurrent ? kMintLight : kScreenBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? kMintMid : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text('🟢  Current',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: isCurrent ? kMintText : kMuted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => isCurrent = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: !isCurrent ? const Color(0xFFF3F4F6) : kScreenBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !isCurrent ? kMuted : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text('⚫  Past',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: !isCurrent ? kMid : kMuted)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _primaryBtn(
                    label: 'Save Medicine',
                    onTap: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final m = Medicine(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        purpose: purposeCtrl.text.trim(),
                        isCurrent: isCurrent,
                        dosage: dosageCtrl.text.trim(),
                        period: periodCtrl.text.trim(),
                      );
                      setState(() => _medicines.add(m));
                      _saveMedicines();
                      Navigator.pop(context);
                      _showSnack('Medicine added');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Add Report ────────────────────────────────────────────

  void _addReport(String source) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final titleCtrl = TextEditingController();
        final notesCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                _sheetHeader('Add Report'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: source == 'Camera' ? kMintLight : kPinkLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(
                      source == 'Camera' ? Icons.camera_alt_rounded : Icons.upload_file_outlined,
                      color: source == 'Camera' ? kMintText : kPinkText,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      source == 'Camera' ? 'Camera Capture' : 'File Upload',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: source == 'Camera' ? kMintText : kPinkText,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _formField('Report Title', 'e.g. HbA1c Blood Test', titleCtrl),
                const SizedBox(height: 12),
                _formField('Notes (optional)', 'Any notes about this report', notesCtrl),
                const SizedBox(height: 20),
                _primaryBtn(
                  label: 'Save Report',
                  onTap: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final r = MedReport(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      date: DateTime.now(),
                      source: source,
                      filePath: '',
                      notes: notesCtrl.text.trim(),
                    );
                    setState(() => _reports.add(r));
                    _saveReports();
                    Navigator.pop(context);
                    _showSnack('Report saved');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Source sheet (camera vs upload) ──────────────────────

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            _sheetHeader('Add Report'),
            const SizedBox(height: 20),
            _sourceOption(
              icon: Icons.camera_alt_rounded,
              gradientColors: [kMintDark, kMintMid],
              cardColor: kMintLight,
              title: 'Scan via Camera',
              subtitle: 'Take a photo of your report',
              onTap: () {
                Navigator.pop(context);
                _addReport('Camera');
              },
            ),
            const SizedBox(height: 10),
            _sourceOption(
              icon: Icons.upload_file_outlined,
              gradientColors: [kMintMid, kMintBg],
              cardColor: kPinkBg,
              title: 'Upload File',
              subtitle: 'Choose from your files',
              onTap: () {
                Navigator.pop(context);
                _addReport('Upload');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: kMintDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _sheetHandle() => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
  );

  Widget _sheetHeader(String title) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kDark)),
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

  Widget _formField(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMid)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: kDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: kMuted),
            filled: true,
            fillColor: kScreenBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kMintLight, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kMintLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kMintMid, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ],
    );
  }

  Widget _primaryBtn({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kMintDark, kMintMid]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kMintDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kWhite)),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required List<Color> gradientColors,
    required Color cardColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(color: gradientColors.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, color: kWhite, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
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

// ── Tab Bar Persistent Header Delegate ────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kWhite,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ── Current Conditions Tab ────────────────────────────────

class _CurrentTab extends StatelessWidget {
  final List<HealthCondition> conditions;
  final VoidCallback onAdd;
  final ValueChanged<HealthCondition> onDelete;

  const _CurrentTab({required this.conditions, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
      children: [
        _TabHeader(
          title: 'Active Conditions',
          subtitle: '${conditions.length} ongoing · Tap card to expand',
          onAdd: onAdd,
          color: kMintDark,
          bgColor: kMintLight,
        ),
        const SizedBox(height: 14),
        if (conditions.isEmpty)
          _EmptyState(
            icon: Icons.medical_services_outlined,
            title: 'No current conditions added yet',
            subtitle: 'Tap + Add to log a health condition',
          )
        else
          ...conditions.map((c) => _ConditionCard(condition: c, onDelete: () => onDelete(c))),
      ],
    );
  }
}

// ── Past Conditions Tab ───────────────────────────────────

class _PastTab extends StatelessWidget {
  final List<HealthCondition> conditions;
  final VoidCallback onAdd;
  final ValueChanged<HealthCondition> onDelete;

  const _PastTab({required this.conditions, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
      children: [
        _TabHeader(
          title: 'Medical History',
          subtitle: '${conditions.length} past conditions · Tap to expand',
          onAdd: onAdd,
          color: kPinkDark,
          bgColor: kPinkLight,
        ),
        const SizedBox(height: 14),
        if (conditions.isEmpty)
          _EmptyState(
            icon: Icons.history,
            title: 'No past conditions recorded',
            subtitle: 'Tap + Add to add your medical history',
          )
        else
          ...conditions.map((c) => _ConditionCard(condition: c, onDelete: () => onDelete(c), isPast: true)),
      ],
    );
  }
}

// ── Medicines Tab ─────────────────────────────────────────

class _MedicinesTab extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAdd;
  final ValueChanged<Medicine> onDelete;

  const _MedicinesTab({required this.medicines, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final current = medicines.where((m) => m.isCurrent).toList();
    final past    = medicines.where((m) => !m.isCurrent).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
      children: [
        _TabHeader(
          title: 'My Medicines',
          subtitle: '${current.length} current · ${past.length} past',
          onAdd: onAdd,
          color: kMintDark,
          bgColor: kMintLight,
        ),
        const SizedBox(height: 14),
        if (medicines.isEmpty)
          _EmptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines added yet',
            subtitle: 'Tap + Add to log your medicines',
          )
        else ...[
          if (current.isNotEmpty) ...[
            _SectionLabel(label: '🟢  Currently Taking', color: kMid),
            const SizedBox(height: 8),
            ...current.map((m) => _MedicineCard(medicine: m, onDelete: () => onDelete(m))),
          ],
          if (past.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel(label: '⚫  Past Medicines', color: kMuted),
            const SizedBox(height: 8),
            ...past.map((m) => _MedicineCard(medicine: m, onDelete: () => onDelete(m))),
          ],
        ],
      ],
    );
  }
}

// ── Reports Bottom Section ────────────────────────────────

class _ReportsSection extends StatelessWidget {
  final List<MedReport> reports;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final ValueChanged<MedReport> onDelete;

  const _ReportsSection({
    required this.reports,
    required this.onCamera,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reports',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
                    Text('${reports.length} documents',
                        style: const TextStyle(fontSize: 11, color: kMuted)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showUploadBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: kMintLight, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.attach_file, size: 14, color: kMintText),
                        SizedBox(width: 4),
                        Text('Upload',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMintText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Text('No reports uploaded yet',
                        style: const TextStyle(fontSize: 13, color: kMuted)),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reports.length + 2,
                    itemBuilder: (_, i) {
                      if (i == 0) return _addReportChip(Icons.camera_alt_rounded, 'Scan', kMintLight, kMintText, () => _showUploadBottomSheet(context));
                      if (i == reports.length + 1) return const SizedBox(width: 8);
                      final r = reports[i - 1];
                      return _reportChip(r, () => onDelete(r));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Report',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kDark)),
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
            GestureDetector(
              onTap: () { Navigator.pop(context); onCamera(); },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kMintLight, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kMintDark, kMintMid]),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: kMintDark.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: kWhite, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Scan via Camera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
                    SizedBox(height: 2),
                    Text('Take a photo of your report', style: TextStyle(fontSize: 11, color: kMuted)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () { Navigator.pop(context); onUpload(); },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kPinkBg, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kMintMid, kMintBg]),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: kMintMid.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.upload_file_outlined, color: kWhite, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Upload File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
                    SizedBox(height: 2),
                    Text('Choose from your files', style: TextStyle(fontSize: 11, color: kMuted)),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addReportChip(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10, bottom: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kMintMid.withOpacity(0.3), width: 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }

  Widget _reportChip(MedReport report, VoidCallback onDelete) {
    final isImage = report.source == 'Camera';
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10, bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isImage ? kMintLight : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                  size: 16,
                  color: isImage ? kMintText : const Color(0xFFDC2626),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(report.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDark)),
          const SizedBox(height: 4),
          Text(DateFormat('dd MMM yyyy').format(report.date),
              style: const TextStyle(fontSize: 9, color: kMuted)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isImage ? kMintLight : kPinkLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isImage ? '📷 Camera' : '📤 Upload',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600,
                  color: isImage ? kMintText : kPinkText),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Condition Card (expandable) ───────────────────────────

class _ConditionCard extends StatefulWidget {
  final HealthCondition condition;
  final VoidCallback onDelete;
  final bool isPast;

  const _ConditionCard({
    required this.condition,
    required this.onDelete,
    this.isPast = false,
  });

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard> {
  bool _expanded = false;

  static const _icons = {
    'Diabetes Type 2':  '🩸',
    'Hypothyroidism':   '🦋',
    'Hypertension':     '❤️',
    'Dengue Fever':     '🦟',
    'Viral Fever':      '🌡️',
    'Appendicitis':     '🏥',
  };

  @override
  Widget build(BuildContext context) {
    final c        = widget.condition;
    final isPast   = widget.isPast || c.isPast;
    final accent   = isPast ? kPinkDark : kMintDark;
    final accentBg = isPast ? kPinkLight : kMintLight;
    final emoji    = _icons[c.name] ?? (isPast ? '🤒' : '💊');

    Color badgeBg;
    Color badgeFg;
    if (c.status == 'Ongoing') {
      badgeBg = kMintLight; badgeFg = kMintText;
    } else if (c.status == 'Active') {
      badgeBg = const Color(0xFFFEF3C7); badgeFg = const Color(0xFF92400E);
    } else if (c.status == 'Recovered') {
      badgeBg = const Color(0xFFD1FAE5); badgeFg = const Color(0xFF065F46);
    } else {
      badgeBg = const Color(0xFFE5E7EB); badgeFg = kMid;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _expanded ? (isPast ? kPinkMid : kMintMid) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? accent.withOpacity(0.15)
                : Colors.black.withOpacity(isPast ? 0.05 : 0.07),
            blurRadius: _expanded ? 16 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: isPast ? 44 : 48,
                    height: isPast ? 44 : 48,
                    decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(emoji, style: TextStyle(fontSize: isPast ? 20 : 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
                        const SizedBox(height: 2),
                        Text(
                          isPast ? c.period : c.summary,
                          style: const TextStyle(fontSize: 11, color: kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(c.status,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeFg)),
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down, color: _expanded ? accent : kMuted, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: accentBg, thickness: 1),
                  const SizedBox(height: 10),

                  // Date / duration chips
                  Row(children: [
                    Expanded(child: _InfoCell(
                      icon: Icons.calendar_today_outlined,
                      label: isPast ? 'Period' : 'Start Date',
                      value: isPast ? c.period : c.startDate,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCell(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: c.duration,
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // Prescriptions
                  _SectionLabel(label: isPast ? 'Prescriptions Taken' : 'Prescriptions', color: kMid),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: c.prescriptions
                        .map((p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: accentBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('💊 $p',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  _SectionLabel(label: 'Notes', color: kMid),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kScreenBg, borderRadius: BorderRadius.circular(10)),
                    child: Text(c.notes,
                        style: const TextStyle(fontSize: 12, color: kMid, height: 1.5)),
                  ),
                  const SizedBox(height: 14),

                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.attach_file,
                        label: 'Reports',
                        color: accent,
                        bg: accentBg,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isPast)
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: kPinkDark,
                          bg: kPinkLight,
                          onTap: () {},
                        ),
                      ),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.delete_outline,
                      bg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFEF4444),
                      onTap: widget.onDelete,
                    ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Medicine Card ─────────────────────────────────────────

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onDelete;

  const _MedicineCard({required this.medicine, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCurrent = medicine.isCurrent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? kMintLight : const Color(0xFFF3F4F6),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isCurrent ? kMintLight : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('💊', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(medicine.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kDark),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCurrent ? 'Current' : 'Past',
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: isCurrent ? const Color(0xFF065F46) : kMuted,
                      ),
                    ),
                  ),
                ]),
                if (medicine.purpose.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(medicine.purpose, style: const TextStyle(fontSize: 11, color: kMuted)),
                ],
                if (medicine.dosage.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(medicine.dosage, style: const TextStyle(fontSize: 10, color: kMid)),
                ],
                if (medicine.period.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 9, color: kMuted),
                    const SizedBox(width: 3),
                    Text(medicine.period, style: const TextStyle(fontSize: 10, color: kMuted)),
                  ]),
                ],
              ],
            ),
          ),
          Column(children: [
            _IconBtn(icon: Icons.edit_outlined, bg: kMintLight, iconColor: kMintText, onTap: () {}),
            const SizedBox(height: 6),
            _IconBtn(icon: Icons.delete_outline, bg: const Color(0xFFFEE2E2), iconColor: const Color(0xFFEF4444), onTap: onDelete),
          ]),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────

class _TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final Color color;
  final Color bgColor;

  const _TabHeader({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted)),
        ]),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kMintDark, kMintMid]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.add, color: kWhite, size: 14),
              SizedBox(width: 4),
              Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kWhite)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCell({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: kScreenBg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 11, color: kMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: kMuted)),
        ]),
        const SizedBox(height: 4),
        Text(value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kDark)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: color, letterSpacing: 0.3,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.bg, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
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
            child: Icon(icon, size: 28, color: kMintText),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMintText)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted)),
        ],
      ),
    );
  }
}
