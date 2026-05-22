/// EduCinema LMS — New Conversation Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/messaging_models.dart';
import '../providers/messaging_providers.dart';

class NewConversationPage extends ConsumerStatefulWidget {
  const NewConversationPage({super.key});

  @override
  ConsumerState<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends ConsumerState<NewConversationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ConversationCategory? _selectedCategory;
  String _userRole = '';
  
  List<dynamic> _teachers = [];
  int? _selectedTeacherId;
  
  List<dynamic> _subjects = [];
  int? _selectedSubjectId;
  
  bool _isLoadingTeachers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final role = await _storage.read(key: AppConstants.userRoleKey);
    if (mounted) {
      setState(() {
        _userRole = role ?? '';
        if (_userRole == AppConstants.student) {
          _selectedCategory = ConversationCategory.doubt;
        } else {
          _selectedCategory = ConversationCategory.academic;
        }
      });
    }

    final api = ApiRepository();
    try {
      final teachersRes = await api.getList('/users', params: {'role': 'teacher'});
      final subjectsRes = await api.getList('/cms/subjects');
      if (mounted) {
        setState(() {
          _teachers = teachersRes;
          _subjects = subjectsRes;
          _isLoadingTeachers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a teacher')));
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final data = {
        'category': _selectedCategory!.name,
        'title': _titleCtrl.text.trim(),
        'teacher_id': _selectedTeacherId,
        'initial_message': _msgCtrl.text.trim(),
        if (_selectedSubjectId != null) 'subject_id': _selectedSubjectId,
      };
      
      final res = await repo.createConversation(data);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        context.pop();
        if (res['id'] != null) {
          context.push('/messaging/${res['id']}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create conversation: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: _isLoadingTeachers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(title: 'Category'),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    
                    const SectionHeader(title: 'Details'),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            value: _selectedTeacherId,
                            decoration: const InputDecoration(labelText: 'Select Teacher'),
                            items: _teachers.map((t) => DropdownMenuItem<int>(
                              value: t['id'] as int,
                              child: Text(t['name'] as String),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedTeacherId = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          if (_selectedCategory == ConversationCategory.doubt) ...[
                            DropdownButtonFormField<int>(
                              value: _selectedSubjectId,
                              decoration: const InputDecoration(labelText: 'Select Subject (Optional)'),
                              items: _subjects.map((s) => DropdownMenuItem<int>(
                                value: s['id'] as int,
                                child: Text(s['name'] as String),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedSubjectId = val),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(labelText: 'Subject / Title'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _msgCtrl,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Message',
                              alignLabelWithHint: true,
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.featureBlue,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Send Message', style: GoogleFonts.inter(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategorySelector() {
    List<ConversationCategory> allowedCategories = [];
    if (_userRole == AppConstants.student) {
      allowedCategories = [ConversationCategory.doubt, ConversationCategory.general];
    } else if (_userRole == AppConstants.parent) {
      allowedCategories = [ConversationCategory.academic, ConversationCategory.attendance, ConversationCategory.fee, ConversationCategory.general];
    } else {
      allowedCategories = ConversationCategory.values;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: allowedCategories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? cat.color.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? cat.color : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 20, color: isSelected ? cat.color : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  cat.label,
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? cat.color : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
