/// EduCinema LMS — Student Fee Management Page (Principal)
/// Class-wise & school-wide fee assignment with purpose, partial payments,
/// paid/pending tracking, fee alerts, and Estimated Fee KPI.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class FeeManagementPage extends StatefulWidget {
  const FeeManagementPage({super.key});
  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  final _repo = ApiRepository();
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // KPIs
  int _totalStudents = 0;
  double _estimatedFee = 0;
  double _totalCollected = 0;
  double _totalPending = 0;
  double _totalFine = 0;
  int _paidCount = 0;
  int _partialCount = 0;
  int _pendingCount = 0;
  int _overdueCount = 0;
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  // Filters
  String _selectedStatus = 'All';
  String _selectedMonth = 'All';
  String _selectedClass = 'All';
  String _searchQuery = '';

  final _statuses = ['All', 'Paid', 'Partial', 'Pending'];
  final _months = ['All','January','February','March','April','May','June','July','August','September','October','November','December'];
  List<String> _classList = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _loadData();
  }

  Future<void> _fetchClasses() async {
    try {
      final list = await _repo.getList('/principal/timetable/classes');
      final labels = list.map((e) => (e['label'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
      setState(() {
        _classList = ['All', ...labels];
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{};
      if (_selectedStatus != 'All') params['status'] = _selectedStatus;
      if (_selectedMonth != 'All') params['month'] = _selectedMonth;
      if (_selectedClass != 'All') params['class'] = _selectedClass;
      final data = await _repo.get('/principal/student-fees', params: params);
      setState(() {
        _totalStudents = data['total_students'] ?? 0;
        _estimatedFee = (data['estimated_fee'] ?? 0).toDouble();
        _totalCollected = (data['total_collected'] ?? 0).toDouble();
        _totalPending = (data['total_pending'] ?? 0).toDouble();
        _totalFine = (data['total_fine'] ?? 0).toDouble();
        _paidCount = data['paid_count'] ?? 0;
        _partialCount = data['partial_count'] ?? 0;
        _pendingCount = data['pending_count'] ?? 0;
        _overdueCount = data['overdue_count'] ?? 0;
        _records = data['records'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      return (r['student_name'] ?? '').toString().toLowerCase().contains(q)
          || (r['admission_no'] ?? '').toString().toLowerCase().contains(q)
          || (r['title'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SectionHeader(title: 'Fee Dashboard'),
                      _buildKpiGrid(),
                      const SizedBox(height: 20),
                      // Generate fees button
                      _buildGenerateSection(),
                      const SizedBox(height: 8),
                      const SectionHeader(title: 'Filters'),
                      _buildFilters(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      SectionHeader(title: 'Student Fees (${list.length})'),
                      ...list.map((r) => _buildFeeCard(r)),
                      if (list.isEmpty && _records.isNotEmpty)
                        const EmptyState(icon: Icons.search_off, title: 'No match', subtitle: 'Try a different search'),
                      if (_records.isEmpty)
                        const EmptyState(icon: Icons.receipt_long_outlined, title: 'No fee records found', subtitle: 'Generate fees using the button above'),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Fee Analytics'),
                      _buildAnalytics(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
      const SizedBox(height: 12),
      Text('Failed to load fees', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
    ]));
  }

  // ── KPI Grid with Estimated Fee ──
  Widget _buildKpiGrid() {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 4 : 2;
      final ratio = c.maxWidth > 800 ? 1.5 : (c.maxWidth > 400 ? 1.25 : 1.15);
      return GridView.count(
        crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: ratio,
        children: [
          _kpiWrapper(
            card: KpiCard(title: 'Total Students', value: '$_totalStudents', icon: Icons.people_alt_rounded, color: AppColors.featureBlue),
            onTap: () {
              setState(() => _selectedStatus = 'All');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Estimated Fees', value: _fmt.format(_estimatedFee), icon: Icons.calculate_rounded, color: AppColors.featurePurple),
            onTap: () {
              setState(() => _selectedStatus = 'All');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Fees Collected', value: _fmt.format(_totalCollected), icon: Icons.check_circle_rounded, color: AppColors.success),
            onTap: () {
              setState(() => _selectedStatus = 'Paid');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Pending Fees', value: _fmt.format(_totalPending), icon: Icons.hourglass_top_rounded, color: AppColors.error),
            onTap: () {
              setState(() => _selectedStatus = 'Pending');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Overdue Students', value: '$_overdueCount', icon: Icons.warning_amber_rounded, color: AppColors.warning),
            onTap: () {
              setState(() => _selectedStatus = 'Pending');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Partial', value: '$_partialCount', icon: Icons.pie_chart_rounded, color: AppColors.info),
            onTap: () {
              setState(() => _selectedStatus = 'Partial');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Fine Collected', value: _fmt.format(_totalFine), icon: Icons.gavel_rounded, color: AppColors.secondary),
            onTap: () {
              setState(() => _selectedStatus = 'All');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Paid', value: '$_paidCount', icon: Icons.verified_rounded, color: AppColors.featureGreen),
            onTap: () {
              setState(() => _selectedStatus = 'Paid');
              _loadData();
            },
          ),
        ],
      );
    });
  }

  Widget _kpiWrapper({required Widget card, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: card,
      ),
    );
  }

  // ── Generate Fee Section ──
  Widget _buildGenerateSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showGenerateDialog,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Assign Fee (Class / School)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.featurePurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Filters ──
  Widget _buildFilters() {
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _dropdown('Class', _selectedClass, _classList, (v) { setState(() => _selectedClass = v!); _loadData(); }),
      _dropdown('Month', _selectedMonth, _months, (v) { setState(() => _selectedMonth = v!); _loadData(); }),
      _dropdown('Status', _selectedStatus, _statuses, (v) { setState(() => _selectedStatus = v!); _loadData(); }),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by name, ID, or fee purpose...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  // ── Fee Card ──
  Widget _buildFeeCard(dynamic r) {
    final status = r['status'] ?? 'Pending';
    final statusColor = status == 'Paid' ? AppColors.success : status == 'Partial' ? AppColors.warning : AppColors.error;
    final totalFee = (r['total_fee'] ?? 0).toDouble();
    final paidAmt = (r['paid_amount'] ?? 0).toDouble();
    final pendingAmt = (r['pending_amount'] ?? 0).toDouble();
    final fineAmt = (r['fine_amount'] ?? 0).toDouble();
    final progress = totalFee > 0 ? (paidAmt / (totalFee + fineAmt)).clamp(0.0, 1.0) : 0.0;
    final title = r['title'] ?? 'Tuition Fee';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: AppColors.featureBlue.withValues(alpha: 0.1),
          child: Text((r['student_name'] ?? 'S')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.featureBlue)),
        ),
        title: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['student_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppColors.featurePurple, fontWeight: FontWeight.w600)),
          ])),
          StatusBadge(label: status, color: statusColor, showDot: true),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text('${r['admission_no'] ?? ''}  •  ${r['class_name'] ?? ''}  •  ${r['month'] ?? ''} ${r['year'] ?? ''}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, minHeight: 6,
              backgroundColor: AppColors.error.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Paid: ${_fmt.format(paidAmt)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
            Text('Pending: ${_fmt.format(pendingAmt)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
          ]),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              _row('Fee Purpose', title, color: AppColors.featurePurple),
              _row('Total Fee', _fmt.format(totalFee)),
              _row('Fine', '+ ${_fmt.format(fineAmt)}', color: AppColors.warning),
              const Divider(height: 16),
              _row('Paid Amount', _fmt.format(paidAmt), color: AppColors.success, bold: true),
              _row('Pending Amount', _fmt.format(pendingAmt), color: pendingAmt > 0 ? AppColors.error : AppColors.success, bold: true),
              if (r['due_date'] != null) _row('Due Date', r['due_date']),
              if (r['payment_date'] != null) _row('Last Payment', r['payment_date']),
              if (r['payment_method'] != null) _row('Method', r['payment_method']),
              const SizedBox(height: 14),
              // Actions
              Row(children: [
                if (status != 'Paid')
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _showCollectDialog(r),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: Text(status == 'Partial' ? 'Collect More' : 'Collect Fee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  )),
                if (status != 'Paid') const SizedBox(width: 8),
                if (status != 'Paid')
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: () => _sendAlert(r),
                      icon: const Icon(Icons.notifications_active_rounded, size: 20, color: AppColors.warning),
                      tooltip: 'Send Pending Fee Alert',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color ?? AppColors.textPrimary), textAlign: TextAlign.end)),
      ]),
    );
  }

  // ── Generate Fee Dialog ──
  void _showGenerateDialog() async {
    // Fetch classes for dropdown
    List<dynamic> classes = [];
    try {
      classes = await _repo.getList('/principal/timetable/classes');
    } catch (_) {}

    final titleCtrl = TextEditingController(text: 'Tuition Fee');
    final amountCtrl = TextEditingController(text: '5000');
    final dueDateCtrl = TextEditingController();
    String selectedMonth = _months[DateTime.now().month];
    int selectedYear = DateTime.now().year;
    int? selectedClassId; // null = all classes (school-wide)
    String selectedClassLabel = 'All Classes (School-wide)';

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Assign Fee', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Create fee records for students', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              // Fee Purpose
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Fee Purpose / Title',
                  hintText: 'e.g. Transport Fee, Library Fee',
                  prefixIcon: const Icon(Icons.label_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              // Amount
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Fee Amount (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              // Class selector
              DropdownButtonFormField<int?>(
                value: selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Assign To',
                  prefixIcon: const Icon(Icons.school_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All Classes (School-wide)')),
                  ...classes.map((c) => DropdownMenuItem<int?>(value: c['class_id'], child: Text(c['label'] ?? 'Class ${c['grade']}'))),
                ],
                onChanged: (v) => setD(() {
                  selectedClassId = v;
                  selectedClassLabel = v == null ? 'All Classes' : classes.firstWhere((c) => c['class_id'] == v)['label'];
                }),
              ),
              const SizedBox(height: 14),
              // Month
              DropdownButtonFormField<String>(
                value: selectedMonth,
                decoration: InputDecoration(
                  labelText: 'Month',
                  prefixIcon: const Icon(Icons.calendar_month),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _months.where((m) => m != 'All').map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setD(() => selectedMonth = v!),
              ),
              const SizedBox(height: 14),
              // Year
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: InputDecoration(
                  labelText: 'Year',
                  prefixIcon: const Icon(Icons.date_range),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setD(() => selectedYear = v!),
              ),
              const SizedBox(height: 14),
              // Due Date
              TextField(
                controller: dueDateCtrl,
                decoration: InputDecoration(
                  labelText: 'Due Date (optional)',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: const Icon(Icons.event),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.featurePurple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.featurePurple.withValues(alpha: 0.15)),
                ),
                child: Column(children: [
                  _row('Purpose', titleCtrl.text, color: AppColors.featurePurple),
                  _row('Scope', selectedClassLabel),
                  _row('Period', '$selectedMonth $selectedYear'),
                ]),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.featurePurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      var url = '/principal/student-fees/generate-bulk'
          '?total_fee=${amountCtrl.text}'
          '&title=${Uri.encodeComponent(titleCtrl.text)}'
          '&month=$selectedMonth'
          '&year=$selectedYear';
      if (dueDateCtrl.text.isNotEmpty) url += '&due_date=${dueDateCtrl.text}';
      if (selectedClassId != null) url += '&class_id=$selectedClassId';
      await _repo.post(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fee records generated for "$selectedClassLabel"'), backgroundColor: AppColors.success));
      }
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  // ── Collect Fee Dialog ──
  void _showCollectDialog(dynamic r) {
    final totalFee = (r['total_fee'] ?? 0).toDouble();
    final fineAmt = (r['fine_amount'] ?? 0).toDouble();
    final alreadyPaid = (r['paid_amount'] ?? 0).toDouble();
    final remaining = totalFee + fineAmt - alreadyPaid;
    bool payFull = true;
    final amountCtrl = TextEditingController(text: '${remaining.toInt()}');
    final fineCtrl = TextEditingController(text: '0');
    String method = 'UPI';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Collect Fee — ${r['student_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.featureBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.featureBlue.withValues(alpha: 0.15)),
                ),
                child: Column(children: [
                  _row('Fee Purpose', r['title'] ?? 'Tuition Fee', color: AppColors.featurePurple),
                  _row('Total Fee', _fmt.format(totalFee), bold: true),
                  if (fineAmt > 0) _row('Fine', _fmt.format(fineAmt), color: AppColors.warning),
                  _row('Already Paid', _fmt.format(alreadyPaid), color: AppColors.success),
                  _row('Remaining', _fmt.format(remaining), color: AppColors.error, bold: true),
                ]),
              ),
              const SizedBox(height: 16),
              // Toggle
              Row(children: [
                Expanded(child: _toggleBtn('Pay Full (${_fmt.format(remaining)})', payFull, () => setD(() {
                  payFull = true;
                  amountCtrl.text = '${remaining.toInt()}';
                }))),
                const SizedBox(width: 8),
                Expanded(child: _toggleBtn('Partial Amount', !payFull, () => setD(() {
                  payFull = false;
                  amountCtrl.text = '';
                }))),
              ]),
              const SizedBox(height: 14),
              if (!payFull)
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount to Collect',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    helperText: 'Max: ${_fmt.format(remaining)}',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (!payFull) const SizedBox(height: 12),
              TextField(
                controller: fineCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Additional Fine (if any)',
                  prefixIcon: const Icon(Icons.gavel_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: InputDecoration(labelText: 'Payment Method', prefixIcon: const Icon(Icons.credit_card), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['UPI','Cash','Bank Transfer','Cheque','Online'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setD(() => method = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: InputDecoration(labelText: 'Notes (optional)', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: Text(payFull ? 'Collect Full' : 'Collect Partial'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.pop(ctx);
                final payAmt = payFull ? remaining : (double.tryParse(amountCtrl.text) ?? 0);
                if (payAmt <= 0) return;
                try {
                  await _repo.patch('/principal/student-fees/${r['id']}/collect', data: {
                    'amount': payAmt,
                    'fine': double.tryParse(fineCtrl.text) ?? 0,
                    'payment_method': method,
                    'installment': payFull ? 'Full' : 'Partial',
                    'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_fmt.format(payAmt)} collected from ${r['student_name']}'), backgroundColor: AppColors.success),
                    );
                  }
                  _loadData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.featureBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.featureBlue : Colors.grey.shade300, width: active ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.featureBlue : AppColors.textSecondary), textAlign: TextAlign.center)),
      ),
    );
  }

  // ── Send Alert ──
  Future<void> _sendAlert(dynamic r) async {
    try {
      final result = await _repo.post('/principal/student-fees/${r['id']}/alert');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Alert sent!'), backgroundColor: AppColors.info),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  // ── Analytics ──
  Widget _buildAnalytics() {
    return Column(children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Payment Status', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: _records.isEmpty
            ? const Center(child: Text('No data'))
            : PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 40, sections: [
                if (_paidCount > 0) PieChartSectionData(value: _paidCount.toDouble(), color: AppColors.success, title: 'Paid\n$_paidCount', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), radius: 55),
                if (_pendingCount > 0) PieChartSectionData(value: _pendingCount.toDouble(), color: AppColors.error, title: 'Pending\n$_pendingCount', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), radius: 55),
                if (_partialCount > 0) PieChartSectionData(value: _partialCount.toDouble(), color: AppColors.warning, title: 'Partial\n$_partialCount', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), radius: 55),
              ]))),
      ])),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Class-wise Collection', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _buildClassBarChart()),
      ])),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildClassBarChart() {
    final classTotals = <String, double>{};
    for (final r in _records) {
      final cls = r['class_name'] ?? 'N/A';
      classTotals[cls] = (classTotals[cls] ?? 0) + ((r['paid_amount'] ?? 0) as num).toDouble();
    }
    if (classTotals.isEmpty) return const Center(child: Text('No data'));
    final entries = classTotals.entries.toList();
    final barColors = [AppColors.featureBlue, AppColors.featurePurple, AppColors.accent, AppColors.secondary, AppColors.featureGreen, AppColors.info];
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: entries.map((e) => e.value).reduce(max) * 1.2,
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('${entries[group.x.toInt()].key}\n${_fmt.format(rod.toY)}', GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      )),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
          final idx = val.toInt(); if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(entries[idx].key.replaceAll('Class ', ''), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500)));
        })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false), gridData: FlGridData(show: false),
      barGroups: List.generate(entries.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: entries[i].value, color: barColors[i % barColors.length], width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      ])),
    ));
  }
}
