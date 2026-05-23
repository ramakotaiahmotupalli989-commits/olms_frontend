/// EduCinema LMS — Teacher Salary Management Page (Principal)
/// Individual basic pay, partial payments, bonus/deductions editing,
/// paid/pending tracking with premium dashboard.
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
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // KPI data
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

  final _monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  final _years = [2024, 2025, 2026, 2027];
  final _statuses = ['All','Paid','Pending','Partial'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'month': _selectedMonth, 'year': _selectedYear};
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

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      return (r['teacher_name'] ?? '').toString().toLowerCase().contains(q)
          || (r['employee_id'] ?? '').toString().toLowerCase().contains(q);
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
                      const SectionHeader(title: 'Salary Dashboard'),
                      _buildKpiGrid(),
                      const SizedBox(height: 20),
                      if (_records.isEmpty) _buildEmptyState(),
                      const SectionHeader(title: 'Filters'),
                      _buildFilters(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      SectionHeader(title: 'Teacher Salaries (${list.length})'),
                      ...list.map((r) => _buildSalaryCard(r)),
                      if (list.isEmpty && _records.isNotEmpty)
                        const EmptyState(icon: Icons.search_off, title: 'No match', subtitle: 'Try a different search query'),
                      if (_records.isEmpty)
                        const EmptyState(icon: Icons.receipt_long_outlined, title: 'No salary records found', subtitle: 'Generate salaries using the button at the top'),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Salary Analytics'),
                      _buildAnalyticsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
      const SizedBox(height: 12),
      Text('Failed to load salaries', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
    ]));
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(child: Column(children: [
        Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.featurePurple.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text('No salary records for ${_monthNames[_selectedMonth - 1]} $_selectedYear',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _generateBulkSalaries,
          icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
          label: const Text('Generate Salaries for All Teachers'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.featurePurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ])),
    );
  }

  // ── KPI Grid ──
  Widget _buildKpiGrid() {
    double totalPaid = 0;
    double totalPending = 0;
    for (final r in _records) {
      totalPaid += (r['paid_amount'] ?? 0).toDouble();
      totalPending += (r['pending_amount'] ?? 0).toDouble();
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 4 : 2;
      final ratio = c.maxWidth > 800 ? 1.5 : (c.maxWidth > 400 ? 1.25 : 1.15);
      return GridView.count(
        crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: ratio,
        children: [
          _kpiWrapper(
            card: KpiCard(title: 'Total Teachers', value: '$_totalTeachers', icon: Icons.people_alt_rounded, color: AppColors.featureBlue),
            onTap: () {
              setState(() => _selectedStatus = 'All');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Total Expense', value: _fmt.format(_totalExpense), icon: Icons.account_balance_wallet, color: AppColors.featurePurple),
            onTap: () {
              setState(() => _selectedStatus = 'All');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Total Paid', value: _fmt.format(totalPaid), icon: Icons.check_circle_rounded, color: AppColors.success),
            onTap: () {
              setState(() => _selectedStatus = 'Paid');
              _loadData();
            },
          ),
          _kpiWrapper(
            card: KpiCard(title: 'Total Pending', value: _fmt.format(totalPending), icon: Icons.hourglass_top_rounded, color: AppColors.error),
            onTap: () {
              setState(() => _selectedStatus = 'Pending');
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

  // ── Filters ──
  Widget _buildFilters() {
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _dropdown('Month', _monthNames[_selectedMonth - 1], _monthNames, (v) {
        setState(() => _selectedMonth = _monthNames.indexOf(v!) + 1);
        _loadData();
      }),
      _dropdown('Year', '$_selectedYear', _years.map((e) => '$e').toList(), (v) {
        setState(() => _selectedYear = int.parse(v!));
        _loadData();
      }),
      _dropdown('Status', _selectedStatus, _statuses, (v) {
        setState(() => _selectedStatus = v!);
        _loadData();
      }),
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
        hintText: 'Search by name or employee ID...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  // ── Salary Card ──
  Widget _buildSalaryCard(dynamic r) {
    final status = r['payment_status'] ?? 'Pending';
    final statusColor = status == 'Paid' ? AppColors.success : status == 'Partial' ? AppColors.warning : AppColors.error;
    final netSalary = (r['net_salary'] ?? 0).toDouble();
    final paidAmt = (r['paid_amount'] ?? 0).toDouble();
    final pendingAmt = (r['pending_amount'] ?? 0).toDouble();
    final progress = netSalary > 0 ? (paidAmt / netSalary).clamp(0.0, 1.0) : 0.0;

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
          child: Text((r['teacher_name'] ?? 'T')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.featureBlue)),
        ),
        title: Row(children: [
          Expanded(child: Text(r['teacher_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
          StatusBadge(label: status, color: statusColor, showDot: true),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text('${r['employee_id'] ?? ''}  •  Net: ${_fmt.format(netSalary)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          // Progress bar showing paid vs pending
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
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
              _row('Basic Salary', _fmt.format(r['basic_salary'] ?? 0)),
              _row('Bonus', '+ ${_fmt.format(r['bonus'] ?? 0)}', color: AppColors.success),
              _row('Deductions', '- ${_fmt.format(r['deductions'] ?? 0)}', color: AppColors.error),
              const Divider(height: 16),
              _row('Net Salary', _fmt.format(netSalary), bold: true),
              _row('Paid Amount', _fmt.format(paidAmt), color: AppColors.success, bold: true),
              _row('Pending Amount', _fmt.format(pendingAmt), color: pendingAmt > 0 ? AppColors.error : AppColors.success, bold: true),
              if (r['payment_date'] != null) _row('Last Payment', r['payment_date']),
              if (r['payment_method'] != null) _row('Method', r['payment_method']),
              if (r['transaction_id'] != null) _row('Txn ID', r['transaction_id']),
              const SizedBox(height: 14),
              // Action buttons
              Row(children: [
                if (status != 'Paid')
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _showPayDialog(r),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: Text(status == 'Partial' ? 'Pay Remaining' : 'Pay Salary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  )),
                if (status != 'Paid') const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(r),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                )),
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
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color ?? AppColors.textPrimary)),
      ]),
    );
  }

  // ── Generate Bulk Salaries with Individual Basic Pay ──
  Future<void> _generateBulkSalaries() async {
    // First get teacher list
    List<dynamic> teachers = [];
    try {
      teachers = await _repo.getList('/principal/teachers');
    } catch (_) {}

    if (teachers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active teachers found'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }

    // Create controllers for each teacher's basic pay
    final controllers = <int, TextEditingController>{};
    for (final t in teachers) {
      controllers[t['id']] = TextEditingController(text: '30000');
    }
    final defaultCtrl = TextEditingController(text: '30000');

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Generate Salaries', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Set basic pay for each teacher for ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                // Apply to all
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: defaultCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Default for All',
                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setD(() {
                        for (final c in controllers.values) {
                          c.text = defaultCtrl.text;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply All'),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Individual teacher entries
                ...teachers.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.featureBlue.withValues(alpha: 0.1),
                        child: Text((t['name'] ?? 'T')[0], style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.featureBlue)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Text(t['name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: controllers[t['id']],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
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

    // Create individual salary records
    try {
      int created = 0;
      for (final t in teachers) {
        final basicPay = double.tryParse(controllers[t['id']]?.text ?? '30000') ?? 30000;
        try {
          await _repo.post('/principal/teacher-salaries', data: {
            'teacher_id': t['id'],
            'month': _selectedMonth,
            'year': _selectedYear,
            'basic_salary': basicPay,
            'bonus': 0,
            'deductions': 0,
          });
          created++;
        } catch (_) {
          // Skip if already exists
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$created salary records generated'), backgroundColor: AppColors.success),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Pay Dialog with Partial Payment Support ──
  void _showPayDialog(dynamic r) {
    final netSalary = (r['net_salary'] ?? 0).toDouble();
    final alreadyPaid = (r['paid_amount'] ?? 0).toDouble();
    final remaining = netSalary - alreadyPaid;
    bool payFull = true;
    final amountCtrl = TextEditingController(text: '${remaining.toInt()}');
    String method = 'Bank Transfer';
    final txnCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Pay Salary — ${r['teacher_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  _row('Net Salary', _fmt.format(netSalary), bold: true),
                  _row('Already Paid', _fmt.format(alreadyPaid), color: AppColors.success),
                  _row('Remaining', _fmt.format(remaining), color: AppColors.error, bold: true),
                ]),
              ),
              const SizedBox(height: 16),
              // Full or Partial toggle
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
                    labelText: 'Amount to Pay',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    helperText: 'Max: ${_fmt.format(remaining)}',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (!payFull) const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Bank Transfer','UPI','Cash','Cheque'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setD(() => method = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: txnCtrl, decoration: InputDecoration(labelText: 'Transaction ID', prefixIcon: const Icon(Icons.receipt_long), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: InputDecoration(labelText: 'Notes (optional)', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: Text(payFull ? 'Pay Full Amount' : 'Pay Partial'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.pop(ctx);
                final payAmount = payFull ? remaining : (double.tryParse(amountCtrl.text) ?? 0);
                if (payAmount <= 0) return;
                try {
                  await _repo.patch('/principal/teacher-salaries/${r['id']}/pay', data: {
                    'amount': payAmount,
                    'payment_method': method,
                    'transaction_id': txnCtrl.text.isNotEmpty ? txnCtrl.text : null,
                    'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_fmt.format(payAmount)} paid to ${r['teacher_name']}'), backgroundColor: AppColors.success),
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

  // ── Edit Dialog (Basic Pay, Bonus, Deductions) ──
  void _showEditDialog(dynamic r) {
    final basicCtrl = TextEditingController(text: '${(r['basic_salary'] ?? 0).toInt()}');
    final bonusCtrl = TextEditingController(text: '${(r['bonus'] ?? 0).toInt()}');
    final dedCtrl = TextEditingController(text: '${(r['deductions'] ?? 0).toInt()}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Salary — ${r['teacher_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: basicCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Basic Pay', prefixIcon: const Icon(Icons.currency_rupee), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 14),
          TextField(controller: bonusCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Bonus', prefixIcon: const Icon(Icons.card_giftcard), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 14),
          TextField(controller: dedCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Deductions', prefixIcon: const Icon(Icons.remove_circle_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text('Net Salary will be:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
              const SizedBox(width: 8),
              Flexible(child: Text('Auto-calculated', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.featureBlue, fontStyle: FontStyle.italic), textAlign: TextAlign.end)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.patch('/principal/teacher-salaries/${r['id']}', data: {
                  'basic_salary': double.tryParse(basicCtrl.text) ?? 0.0,
                  'bonus': double.tryParse(bonusCtrl.text) ?? 0.0,
                  'deductions': double.tryParse(dedCtrl.text) ?? 0.0,
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['teacher_name']} salary updated'), backgroundColor: AppColors.info));
                _loadData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Save Changes'),
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
        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('${entries[group.x.toInt()].key}\n${_fmt.format(rod.toY)}', GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
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
