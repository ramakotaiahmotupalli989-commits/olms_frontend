/// EduCinema LMS — Platform Performance Page (Super Admin)
/// Compare school health scores and engagement metrics.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/network/api_repository.dart';

class PlatformPerformancePage extends StatefulWidget {
  const PlatformPerformancePage({super.key});
  @override
  State<PlatformPerformancePage> createState() => _PlatformPerformancePageState();
}

class _PlatformPerformancePageState extends State<PlatformPerformancePage> {
  final _repo = ApiRepository();
  List<dynamic> _healthScores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _healthScores = await _repo.getList('/analytics/schools/health');
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[Performance] Load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Platform Performance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _healthScores.isEmpty
              ? const EmptyState(icon: Icons.analytics_rounded, title: 'No data available', subtitle: 'Health scores will appear as schools interact with the platform')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _healthScores.length,
                  itemBuilder: (_, i) => _buildHealthCard(_healthScores[i], i + 1),
                ),
    );
  }

  Widget _buildHealthCard(Map<String, dynamic> score, int rank) {
    final engagement = score['engagement_score'] ?? 0.0;
    Color healthColor = AppColors.success;
    if (engagement < 40) healthColor = AppColors.error;
    else if (engagement < 70) healthColor = AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text('#$rank', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score['school_name'] ?? '',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _metricMini('Completion', '${score['avg_video_completion']}%'),
                    _metricMini('Quiz Avg', '${score['avg_quiz_score']}%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$engagement', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: healthColor)),
              Text('Health', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricMini(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
