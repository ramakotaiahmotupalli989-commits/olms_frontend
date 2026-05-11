/// EduCinema LMS — School Management Page (Super Admin)
/// Platform-wide school onboarding, principal assignment, and suspension.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class SchoolManagementPage extends StatefulWidget {
  const SchoolManagementPage({super.key});
  @override
  State<SchoolManagementPage> createState() => _SchoolManagementPageState();
}

class _SchoolManagementPageState extends State<SchoolManagementPage> {
  final _repo = ApiRepository();
  List<dynamic> _schools = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _repo.getList('/schools/');
      if (mounted) {
        setState(() {
          _schools = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[SchoolMgmt] Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSuspend(Map<String, dynamic> school) async {
    final active = school['is_active'] ?? true;
    final confirmed = await _showConfirmDialog(
      title: active ? 'Suspend School' : 'Reactivate School',
      message: 'Are you sure you want to ${active ? 'suspend' : 'reactivate'} "${school['name']}"?',
      confirmText: active ? 'Suspend' : 'Activate',
      isDestructive: active,
    );

    if (confirmed == true) {
      try {
        if (active) {
          await _repo.post('/schools/${school['id']}/suspend');
        } else {
          await _repo.patch('/schools/${school['id']}', data: {'is_active': true, 'subscription_status': 'active'});
        }
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText, style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionButton(
              label: 'Onboard School',
              icon: Icons.add_business_rounded,
              onPressed: _showAddSchoolDialog,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schools.isEmpty
              ? const EmptyState(icon: Icons.business_rounded, title: 'No schools onboarded', subtitle: 'Start by onboarding a new school tenant')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schools.length,
                    itemBuilder: (_, i) => _buildSchoolCard(_schools[i]),
                  ),
                ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> s) {
    final active = s['is_active'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.business_rounded, color: active ? AppColors.primary : Colors.grey),
        ),
        title: Text(s['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${s['city'] ?? ''}, ${s['state'] ?? ''} • ${s['board'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusBadge(
                  label: s['subscription_status']?.toUpperCase() ?? 'NONE',
                  color: s['subscription_status'] == 'active' ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 8),
                if (!active) StatusBadge(label: 'SUSPENDED', color: AppColors.error),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'principal', child: ListTile(leading: Icon(Icons.person_add_alt_rounded, size: 18), title: Text('Add Principal'), contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 18), title: Text('Edit Profile'), contentPadding: EdgeInsets.zero)),
            PopupMenuItem(value: 'suspend', child: ListTile(
              leading: Icon(active ? Icons.block_rounded : Icons.check_circle_rounded, size: 18, color: active ? AppColors.error : AppColors.success),
              title: Text(active ? 'Suspend' : 'Reactivate', style: TextStyle(color: active ? AppColors.error : AppColors.success)),
              contentPadding: EdgeInsets.zero,
            )),
          ],
          onSelected: (v) {
            if (v == 'suspend') _handleSuspend(s);
            if (v == 'principal') _showAddPrincipalDialog(s);
          },
        ),
      ),
    );
  }

  void _showAddPrincipalDialog(Map<String, dynamic> school) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password123');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Principal', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Creating a Principal account for ${school['name']}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Principal Name', prefixIcon: Icon(Icons.person_outline, size: 20))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.alternate_email_rounded, size: 20))),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Login Password', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
              
              final confirmed = await _showConfirmDialog(
                title: 'Confirm Principal Creation',
                message: 'Do you want to create a Principal account for ${nameCtrl.text}?',
              );
              
              if (confirmed == true && mounted) {
                try {
                  await _repo.post('/users/', data: {
                    'name': nameCtrl.text,
                    'email': emailCtrl.text,
                    'password': passCtrl.text,
                    'role': 'school_admin',
                    'school_id': school['id'],
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Principal created successfully!'), backgroundColor: AppColors.success));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  void _showAddSchoolDialog() {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final boardCtrl = TextEditingController(text: 'CBSE');
    String tier = 'starter';
    double amount = 15000.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Onboard New School', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'School Name', prefixIcon: Icon(Icons.school_outlined, size: 20))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_rounded, size: 20)))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: boardCtrl.text,
                  decoration: const InputDecoration(labelText: 'Board', prefixIcon: Icon(Icons.account_balance_rounded, size: 20)),
                  items: ['CBSE', 'ICSE', 'State Board', 'International'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => boardCtrl.text = v ?? 'CBSE',
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text('Subscription Plan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tier,
                  decoration: const InputDecoration(labelText: 'Select Tier', prefixIcon: Icon(Icons.card_membership_rounded, size: 20)),
                  items: [
                    const DropdownMenuItem(value: 'starter', child: Text('Starter (₹15,000)')),
                    const DropdownMenuItem(value: 'growth', child: Text('Growth (₹30,000)')),
                    const DropdownMenuItem(value: 'scale', child: Text('Scale (₹55,000)')),
                  ],
                  onChanged: (v) {
                    setDialogState(() {
                      tier = v!;
                      if (tier == 'starter') amount = 15000.0;
                      else if (tier == 'growth') amount = 30000.0;
                      else amount = 55000.0;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;

                final confirmed = await _showConfirmDialog(
                  title: 'Confirm Onboarding',
                  message: 'Onboard "${nameCtrl.text}" with the ${tier.toUpperCase()} plan?',
                );

                if (confirmed == true && mounted) {
                  try {
                    await _repo.post('/schools/', data: {
                      'name': nameCtrl.text,
                      'city': cityCtrl.text,
                      'state': stateCtrl.text,
                      'board': boardCtrl.text,
                      'subscription_tier': tier,
                      'subscription_amount': amount,
                      'semester': '2026-S1',
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('School onboarded successfully!'), backgroundColor: AppColors.success));
                      _load();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Onboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const ActionButton({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
