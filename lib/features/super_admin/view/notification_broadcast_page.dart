/// EduCinema LMS — Notification Broadcast Page (Super Admin)
/// Send targeted or platform-wide notifications.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_repository.dart';

class NotificationBroadcastPage extends StatefulWidget {
  const NotificationBroadcastPage({super.key});
  @override
  State<NotificationBroadcastPage> createState() => _NotificationBroadcastPageState();
}

class _NotificationBroadcastPageState extends State<NotificationBroadcastPage> {
  final _repo = ApiRepository();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _targetType = 'all'; // all, school, role
  String _targetRole = 'student';
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Send Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Broadcast', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Target users across the platform with important updates', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            
            _buildCard([
              _label('Notification Title'),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'e.g. New Feature Update')),
              const SizedBox(height: 20),
              _label('Message Body'),
              TextField(controller: _bodyCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe the update...')),
            ]),
            
            const SizedBox(height: 24),
            _label('Target Audience'),
            _buildCard([
              DropdownButtonFormField<String>(
                value: _targetType,
                decoration: const InputDecoration(labelText: 'Target Type'),
                items: [
                  {'val': 'all', 'label': 'All Platform Users'},
                  {'val': 'role', 'label': 'Specific Role Only'},
                ].map((t) => DropdownMenuItem(value: t['val'], child: Text(t['label']!))).toList(),
                onChanged: (v) => setState(() => _targetType = v!),
              ),
              if (_targetType == 'role') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _targetRole,
                  decoration: const InputDecoration(labelText: 'Select Role'),
                  items: [
                    {'val': 'student', 'label': 'Students'},
                    {'val': 'teacher', 'label': 'Teachers'},
                    {'val': 'school_admin', 'label': 'Principals'},
                  ].map((r) => DropdownMenuItem(value: r['val'], child: Text(r['label']!))).toList(),
                  onChanged: (v) => setState(() => _targetRole = v!),
                ),
              ],
            ]),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _sending ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _sending 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Send Broadcast Now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  Future<void> _handleSend() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _sending = true);
    try {
      await _repo.post('/notifications/send', data: {
        'title': _titleCtrl.text,
        'body': _bodyCtrl.text,
        'notification_type': 'general',
        'target_type': _targetType,
        'target_role': _targetType == 'role' ? _targetRole : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: AppColors.success));
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }
}
