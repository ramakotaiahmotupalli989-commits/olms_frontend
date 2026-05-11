/// EduCinema LMS — Subscription Management Page (Super Admin)
/// View billing, active plans, and payments.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});
  @override
  State<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage> {
  final _repo = ApiRepository();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _repo.get('/analytics/revenue');
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[Subs] Load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = (_data?['subscriptions_by_status'] as Map?) ?? {};
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Subscriptions & Billing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRevenueHeader(),
                  const SizedBox(height: 24),
                  Text('Subscription Status Breakdown', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildStatusCards(statusCounts),
                  const SizedBox(height: 24),
                  Text('Upcoming Renewals', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildRenewalInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Revenue (${_data?['period'] ?? ''})', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 4),
                Text('\u20B9${_data?['total_revenue'] ?? 0}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildStatusCards(Map counts) {
    return Row(
      children: [
        Expanded(child: _statusCard('Active', '${counts['active'] ?? 0}', AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _statusCard('Expiring', '${counts['expiring_soon'] ?? 0}', AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: _statusCard('Suspended', '${counts['suspended'] ?? 0}', AppColors.error)),
      ],
    );
  }

  Widget _statusCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRenewalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          const Icon(Icons.update_rounded, color: AppColors.accent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Renewal Pipeline (60 days)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                Text('Projected renewal value: \u20B9${_data?['upcoming_renewals_value'] ?? 0}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
