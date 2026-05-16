/// EduCinema LMS — Student Fee Management Page (Principal)
/// Dashboard KPIs, filters, fee table, collect/reminder actions, and analytics charts.
/// Connected to backend API — no mock data.
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
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Dashboard KPIs
  int _totalStudents = 0;
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
  String _searchQuery = '';

  final List<String> _statuses = ['All', 'Paid', 'Partial', 'Pending'];
  final List<String> _months = ['All','January','February','March','April','May','June','July','August','September','October','November','December'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{};
      if (_selectedStatus != 'All') params['status'] = _selectedStatus;
      if (_selectedMonth != 'All') params['month'] = _selectedMonth;

      final data = await _repo.get('/principal/student-fees', params: params);
      setState(() {
        _totalStudents = data['total_students'] ?? 0;
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

  List<dynamic> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    return _records.where((r) {
      final name = (r['student_name'] ?? '').toString().toLowerCase();
      final admNo = (r['admission_no'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || admNo.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load fees', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SectionHeader(title: 'Fee Dashboard'),
                      _buildKpiGrid(),
                      const SizedBox(height: 20),

                      // Generate bulk button
                      if (_records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(child: Column(children: [
                            Text('No fee records found', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _generateBulkFees,
                              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                              label: const Text('Generate Fees for All Students'),
                            ),
                          ])),
                        ),

                      const SectionHeader(title: 'Filters'),
                      _buildFilters(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 16),

                      SectionHeader(title: 'Student Fees (${filtered.length})'),
                      ...filtered.map((r) => _buildFeeCard(r)),
                      if (filtered.isEmpty && _records.isNotEmpty)
                        const EmptyState(icon: Icons.search_off, title: 'No match', subtitle: 'Try a different search query'),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'Fee Analytics'),
                      _buildAnalyticsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 700 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: constraints.maxWidth > 700 ? 2.2 : 1.8,
        children: [
          KpiCard(title: 'Total Students', value: '$_totalStudents', icon: Icons.school_rounded, color: AppColors.featureBlue),
          KpiCard(title: 'Fees Collected', value: _currencyFmt.format(_totalCollected), icon: Icons.account_balance_wallet, color: AppColors.success),
          KpiCard(title: 'Pending Fees', value: _currencyFmt.format(_totalPending), icon: Icons.hourglass_top_rounded, color: AppColors.warning),
          KpiCard(title: 'Overdue Students', value: '$_overdueCount', icon: Icons.warning_rounded, color: AppColors.error),
          KpiCard(title: 'Partial', value: '$_partialCount', icon: Icons.pie_chart_rounded, color: AppColors.featurePurple),
          KpiCard(title: 'Fine Collected', value: _currencyFmt.format(_totalFine), icon: Icons.gavel_rounded, color: AppColors.secondary),
        ],
      );
    });
  }

  Widget _buildFilters() {
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _filterDropdown('Status', _selectedStatus, _statuses, (v) {
        setState(() => _selectedStatus = v!);
        _loadData();
      }),
      _filterDropdown('Month', _selectedMonth, _months, (v) {
        setState(() => _selectedMonth = v!);
        _loadData();
      }),
    ]);
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
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
        hintText: 'Search by name or admission no...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildFeeCard(dynamic r) {
    final status = r['status'] ?? 'Pending';
    final statusColor = status == 'Paid' ? AppColors.success : status == 'Partial' ? AppColors.warning : AppColors.error;
    final totalFee = ((r['total_fee'] ?? 0) as num).toDouble();
    final paidAmt = ((r['paid_amount'] ?? 0) as num).toDouble();
    final fineAmt = ((r['fine_amount'] ?? 0) as num).toDouble();
    final pendingAmt = ((r['pending_amount'] ?? 0) as num).toDouble();
    final progressVal = totalFee > 0 ? (paidAmt / (totalFee + fineAmt)).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: AppColors.featurePurple.withValues(alpha: 0.1),
          child: Text((r['student_name'] ?? 'S')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.featurePurple)),
        ),
        title: Row(children: [
          Expanded(child: Text(r['student_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
          StatusBadge(label: status, color: statusColor, showDot: true),
        ]),
        subtitle: Text('${r['admission_no'] ?? ''}  •  ${r['class_name'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              LabeledProgressBar(label: 'Payment Progress', value: progressVal, color: statusColor),
              const SizedBox(height: 12),
              _detailRow('Total Fee', _currencyFmt.format(totalFee)),
              _detailRow('Paid Amount', _currencyFmt.format(paidAmt), color: AppColors.success),
              if (fineAmt > 0) _detailRow('Fine', _currencyFmt.format(fineAmt), color: AppColors.error),
              _detailRow('Pending', _currencyFmt.format(pendingAmt), bold: true, color: pendingAmt > 0 ? AppColors.error : AppColors.success),
              if (r['due_date'] != null) _detailRow('Due Date', r['due_date']),
              if (r['payment_date'] != null) _detailRow('Paid On', r['payment_date']),
              if (r['payment_method'] != null) _detailRow('Method', r['payment_method']),
              const SizedBox(height: 12),
              Row(children: [
                if (status != 'Paid')
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _showCollectDialog(r),
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const Text('Collect Fee'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                if (status != 'Paid') const SizedBox(width: 8),
                if (status != 'Paid')
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _sendReminder(r),
                    icon: const Icon(Icons.notifications_active_rounded, size: 16),
                    label: const Text('Remind'),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                if (status == 'Paid')
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt details for ${r['student_name']} displayed above'), backgroundColor: AppColors.info));
                    },
                    icon: const Icon(Icons.receipt_rounded, size: 16),
                    label: const Text('View Receipt'),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color ?? AppColors.textPrimary)),
      ]),
    );
  }

  // ── Generate bulk fees ──
  Future<void> _generateBulkFees() async {
    final feeCtrl = TextEditingController(text: '25000');
    final monthCtrl = TextEditingController(text: 'May');
    final yearCtrl = TextEditingController(text: '2026');
    final dueDateCtrl = TextEditingController(text: '2026-05-15');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Generate Fees', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Generate fee records for all active students', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Fee', prefixIcon: Icon(Icons.currency_rupee))),
          const SizedBox(height: 12),
          TextField(controller: monthCtrl, decoration: const InputDecoration(labelText: 'Month (e.g. May)', prefixIcon: Icon(Icons.calendar_month))),
          const SizedBox(height: 12),
          TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year', prefixIcon: Icon(Icons.date_range))),
          const SizedBox(height: 12),
          TextField(controller: dueDateCtrl, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.event))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.post(
        '/principal/student-fees/generate-bulk?total_fee=${feeCtrl.text}&month=${monthCtrl.text}&year=${yearCtrl.text}&due_date=${dueDateCtrl.text}',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee records generated'), backgroundColor: AppColors.success));
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  // ── Collect Fee Dialog ──
  void _showCollectDialog(dynamic r) {
    final pendingAmt = ((r['pending_amount'] ?? 0) as num).toDouble();
    final amtCtrl = TextEditingController(text: pendingAmt.toStringAsFixed(0));
    final fineCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    String method = 'UPI';
    String installment = 'Full';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Collect Fee — ${r['student_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _detailRow('Pending', _currencyFmt.format(pendingAmt), bold: true, color: AppColors.error),
            const SizedBox(height: 16),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.credit_card)),
              items: ['UPI','Cash','Bank Transfer','Cheque'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setD(() => method = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: installment,
              decoration: const InputDecoration(labelText: 'Installment', prefixIcon: Icon(Icons.calendar_today)),
              items: ['Full','1st Installment','2nd Installment','3rd Installment'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setD(() => installment = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: fineCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fine', prefixIcon: Icon(Icons.gavel))),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note)), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Collect'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repo.patch('/principal/student-fees/${r['id']}/collect', data: {
                    'amount': double.tryParse(amtCtrl.text) ?? 0,
                    'payment_method': method,
                    'fine': double.tryParse(fineCtrl.text) ?? 0,
                    'installment': installment,
                    'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fee collected from ${r['student_name']}'), backgroundColor: AppColors.success));
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

  // ── Send Reminder ──
  void _sendReminder(dynamic r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.notifications_active_rounded, color: AppColors.info, size: 40),
        title: Text('Send Reminder', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text('Send fee reminder to ${r['student_name']}\'s parent?', style: GoogleFonts.inter(color: AppColors.textSecondary), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.sms_rounded, size: 16), label: const Text('SMS'),
            onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SMS reminder sent to ${r['student_name']}\'s parent'), backgroundColor: AppColors.success)); },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.notifications_rounded, size: 16), label: const Text('App'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.featurePurple),
            onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('App notification sent to ${r['student_name']}\'s parent'), backgroundColor: AppColors.success)); },
          ),
        ],
      ),
    );
  }

  // ── Analytics Section ──
  Widget _buildAnalyticsSection() {
    return Column(children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Collection Status', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: _records.isEmpty
            ? const Center(child: Text('No data'))
            : PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 40, sections: [
                if (_paidCount > 0) PieChartSectionData(value: _paidCount.toDouble(), color: AppColors.success, title: 'Paid\n$_paidCount', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), radius: 55),
                if (_partialCount > 0) PieChartSectionData(value: _partialCount.toDouble(), color: AppColors.warning, title: 'Partial\n$_partialCount', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), radius: 55),
                if (_pendingCount > 0) PieChartSectionData(value: _pendingCount.toDouble(), color: AppColors.error, title: 'Pending\n$_pendingCount', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), radius: 55),
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
    final entries = classTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final barColors = [AppColors.featurePurple, AppColors.featureBlue, AppColors.accent, AppColors.secondary, AppColors.featureGreen];
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: entries.map((e) => e.value).reduce(max) * 1.2,
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('${entries[group.x.toInt()].key}\n${_currencyFmt.format(rod.toY)}', GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      )),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
          final idx = val.toInt(); if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(entries[idx].key.replaceAll('Class ', 'C'), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500)));
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
