/// EduCinema LMS — Teacher Salary Management Page (Principal)
/// Dashboard KPIs, filters, salary table, pay/edit actions, and analytics charts.
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

class SalaryManagementPage extends StatefulWidget {
  const SalaryManagementPage({super.key});
  @override
  State<SalaryManagementPage> createState() => _SalaryManagementPageState();
}

class _SalaryManagementPageState extends State<SalaryManagementPage> {
  final _repo = ApiRepository();
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Dashboard KPIs
  int _totalTeachers = 0;
  double _totalExpense = 0;
  int _paidCount = 0;
  int _pendingCount = 0;
  int _partialCount = 0;
  double _totalBonus = 0;
  double _totalDeductions = 0;
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  // Filters
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final List<String> _monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  final List<int> _years = [2024, 2025, 2026];
  final List<String> _statuses = ['All','Paid','Pending','Partial'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{
        'month': _selectedMonth,
        'year': _selectedYear,
      };
      if (_selectedStatus != 'All') params['status'] = _selectedStatus;

      final data = await _repo.get('/principal/teacher-salaries', params: params);
      setState(() {
        _totalTeachers = data['total_teachers'] ?? 0;
        _totalExpense = (data['total_expense'] ?? 0).toDouble();
        _paidCount = data['paid_count'] ?? 0;
        _pendingCount = data['pending_count'] ?? 0;
        _partialCount = data['partial_count'] ?? 0;
        _totalBonus = (data['total_bonus'] ?? 0).toDouble();
        _totalDeductions = (data['total_deductions'] ?? 0).toDouble();
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
      final name = (r['teacher_name'] ?? '').toString().toLowerCase();
      final empId = (r['employee_id'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || empId.contains(q);
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
                  Text('Failed to load salaries', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
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
                      const SectionHeader(title: 'Salary Dashboard'),
                      _buildKpiGrid(),
                      const SizedBox(height: 20),

                      // Generate bulk button
                      if (_records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(child: Column(children: [
                            Text('No salary records for ${_monthNames[_selectedMonth - 1]} $_selectedYear', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _generateBulkSalaries,
                              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                              label: const Text('Generate Salaries for All Teachers'),
                            ),
                          ])),
                        ),

                      const SectionHeader(title: 'Filters'),
                      _buildFilters(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 16),

                      SectionHeader(title: 'Teacher Salaries (${filtered.length})'),
                      ...filtered.map((r) => _buildSalaryCard(r)),
                      if (filtered.isEmpty && _records.isNotEmpty)
                        const EmptyState(icon: Icons.search_off, title: 'No match', subtitle: 'Try a different search query'),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'Salary Analytics'),
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
          KpiCard(title: 'Total Teachers', value: '$_totalTeachers', icon: Icons.people_alt_rounded, color: AppColors.featureBlue),
          KpiCard(title: 'Total Expense', value: _currencyFmt.format(_totalExpense), icon: Icons.account_balance_wallet, color: AppColors.featurePurple),
          KpiCard(title: 'Paid Salaries', value: '$_paidCount', icon: Icons.check_circle_rounded, color: AppColors.success, subtitle: _totalTeachers > 0 ? '${(_paidCount * 100 / max(1, _records.length)).round()}%' : null),
          KpiCard(title: 'Pending', value: '${_pendingCount + _partialCount}', icon: Icons.hourglass_top_rounded, color: AppColors.warning),
          KpiCard(title: 'Total Bonus', value: _currencyFmt.format(_totalBonus), icon: Icons.card_giftcard_rounded, color: AppColors.secondary),
          KpiCard(title: 'Deductions', value: _currencyFmt.format(_totalDeductions), icon: Icons.trending_down_rounded, color: AppColors.error),
        ],
      );
    });
  }

  Widget _buildFilters() {
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _filterDropdown('Month', _monthNames[_selectedMonth - 1], _monthNames, (v) {
        setState(() => _selectedMonth = _monthNames.indexOf(v!) + 1);
        _loadData();
      }),
      _filterDropdown('Year', '$_selectedYear', _years.map((e) => '$e').toList(), (v) {
        setState(() => _selectedYear = int.parse(v!));
        _loadData();
      }),
      _filterDropdown('Status', _selectedStatus, _statuses, (v) {
        setState(() => _selectedStatus = v!);
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
        hintText: 'Search by name or employee ID...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildSalaryCard(dynamic r) {
    final status = r['payment_status'] ?? 'Pending';
    final statusColor = status == 'Paid' ? AppColors.success : status == 'Partial' ? AppColors.warning : AppColors.error;
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
          backgroundColor: AppColors.featureBlue.withValues(alpha: 0.1),
          child: Text((r['teacher_name'] ?? 'T')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.featureBlue)),
        ),
        title: Row(children: [
          Expanded(child: Text(r['teacher_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
          StatusBadge(label: status, color: statusColor, showDot: true),
        ]),
        subtitle: Text('${r['employee_id'] ?? ''}  •  ${r['department'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              _detailRow('Basic Salary', _currencyFmt.format(r['basic_salary'] ?? 0)),
              _detailRow('Bonus', _currencyFmt.format(r['bonus'] ?? 0), color: AppColors.success),
              _detailRow('Deductions', '- ${_currencyFmt.format(r['deductions'] ?? 0)}', color: AppColors.error),
              const Divider(height: 16),
              _detailRow('Net Salary', _currencyFmt.format(r['net_salary'] ?? 0), bold: true),
              if (r['payment_date'] != null) _detailRow('Payment Date', r['payment_date']),
              if (r['payment_method'] != null) _detailRow('Method', r['payment_method']),
              if (r['transaction_id'] != null) _detailRow('Txn ID', r['transaction_id']),
              const SizedBox(height: 12),
              Row(children: [
                if (status != 'Paid')
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _showPayDialog(r),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Pay Salary'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                if (status != 'Paid') const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(r),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
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

  // ── Generate bulk salaries ──
  Future<void> _generateBulkSalaries() async {
    final basicCtrl = TextEditingController(text: '30000');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Generate Salaries', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Generate salary records for all active teachers for ${_monthNames[_selectedMonth - 1]} $_selectedYear', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(controller: basicCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Default Basic Salary', prefixIcon: Icon(Icons.currency_rupee))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.post(
        '/principal/teacher-salaries/generate-bulk?month=$_selectedMonth&year=$_selectedYear&basic_salary=${basicCtrl.text}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary records generated'), backgroundColor: AppColors.success));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  // ── Pay Dialog ──
  void _showPayDialog(dynamic r) {
    String method = 'Bank Transfer';
    final txnCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pay Salary — ${r['teacher_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _detailRow('Net Salary', _currencyFmt.format(r['net_salary'] ?? 0), bold: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.credit_card)),
              items: ['Bank Transfer','UPI','Cash','Cheque'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setD(() => method = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: txnCtrl, decoration: const InputDecoration(labelText: 'Transaction ID', prefixIcon: Icon(Icons.receipt_long))),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note)), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Mark Paid'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repo.patch('/principal/teacher-salaries/${r['id']}/pay', data: {
                    'payment_method': method,
                    'transaction_id': txnCtrl.text.isNotEmpty ? txnCtrl.text : null,
                    'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['teacher_name']} salary marked as paid'), backgroundColor: AppColors.success));
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

  // ── Edit Dialog ──
  void _showEditDialog(dynamic r) {
    final basicCtrl = TextEditingController(text: '${(r['basic_salary'] ?? 0).toInt()}');
    final bonusCtrl = TextEditingController(text: '${(r['bonus'] ?? 0).toInt()}');
    final dedCtrl = TextEditingController(text: '${(r['deductions'] ?? 0).toInt()}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Salary — ${r['teacher_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: basicCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Basic Salary', prefixIcon: Icon(Icons.currency_rupee))),
          const SizedBox(height: 12),
          TextField(controller: bonusCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bonus', prefixIcon: Icon(Icons.card_giftcard))),
          const SizedBox(height: 12),
          TextField(controller: dedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Deductions', prefixIcon: Icon(Icons.remove_circle_outline))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.patch('/principal/teacher-salaries/${r['id']}', data: {
                  'basic_salary': double.tryParse(basicCtrl.text),
                  'bonus': double.tryParse(bonusCtrl.text),
                  'deductions': double.tryParse(dedCtrl.text),
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['teacher_name']} salary updated'), backgroundColor: AppColors.info));
                _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Analytics Section ──
  Widget _buildAnalyticsSection() {
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
        Text('Department-wise Expense', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _buildDeptBarChart()),
      ])),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildDeptBarChart() {
    final deptTotals = <String, double>{};
    for (final r in _records) {
      final dept = r['department'] ?? 'General';
      deptTotals[dept] = (deptTotals[dept] ?? 0) + ((r['net_salary'] ?? 0) as num).toDouble();
    }
    if (deptTotals.isEmpty) return const Center(child: Text('No data'));
    final entries = deptTotals.entries.toList();
    final barColors = [AppColors.featureBlue, AppColors.featurePurple, AppColors.accent, AppColors.secondary, AppColors.featureGreen, AppColors.info];
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: entries.map((e) => e.value).reduce(max) * 1.2,
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('${entries[group.x.toInt()].key}\n${_currencyFmt.format(rod.toY)}', GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      )),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
          final idx = val.toInt(); if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(entries[idx].key.substring(0, min(4, entries[idx].key.length)), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500)));
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
