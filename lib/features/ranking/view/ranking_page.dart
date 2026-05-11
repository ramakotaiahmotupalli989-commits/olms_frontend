/// EduCinema LMS — Ranking Page
/// Full class leaderboard with Gold/Silver/Bronze indicators,
/// "You" badge, progress bars, and persistent past results.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class RankingPage extends ConsumerStatefulWidget {
  final int quizId;
  final int classId;

  const RankingPage({
    super.key,
    required this.quizId,
    required this.classId,
  });

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Mock data — will be replaced by Riverpod provider
  final int _currentUserId = 5;
  final List<Map<String, dynamic>> _rankings = [
    {'rank': 1, 'student_id': 1, 'name': 'Aarav Sharma', 'score': 96, 'total': 100, 'percent': 96.0},
    {'rank': 2, 'student_id': 2, 'name': 'Priya Patel', 'score': 92, 'total': 100, 'percent': 92.0},
    {'rank': 3, 'student_id': 3, 'name': 'Rohan Gupta', 'score': 88, 'total': 100, 'percent': 88.0},
    {'rank': 4, 'student_id': 4, 'name': 'Ananya Singh', 'score': 85, 'total': 100, 'percent': 85.0},
    {'rank': 5, 'student_id': 5, 'name': 'You (Arjun M)', 'score': 82, 'total': 100, 'percent': 82.0},
    {'rank': 6, 'student_id': 6, 'name': 'Kavya Reddy', 'score': 78, 'total': 100, 'percent': 78.0},
    {'rank': 7, 'student_id': 7, 'name': 'Aditya Kumar', 'score': 74, 'total': 100, 'percent': 74.0},
    {'rank': 8, 'student_id': 8, 'name': 'Meera Nair', 'score': 70, 'total': 100, 'percent': 70.0},
    {'rank': 9, 'student_id': 9, 'name': 'Vivek Joshi', 'score': 65, 'total': 100, 'percent': 65.0},
    {'rank': 10, 'student_id': 10, 'name': 'Shreya Das', 'score': 60, 'total': 100, 'percent': 60.0},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          // ── Top 3 Podium ──
          SliverToBoxAdapter(
            child: _buildPodium(),
          ),

          // ── Full Ranking Table ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Full Rankings',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = _rankings[index];
                final isCurrentUser = entry['student_id'] == _currentUserId;
                return _buildRankingRow(entry, isCurrentUser, index);
              },
              childCount: _rankings.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Class Rankings',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chapter 5 Quiz — Class 8A',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    if (_rankings.length < 3) return const SizedBox.shrink();

    final first = _rankings[0];
    final second = _rankings[1];
    final third = _rankings[2];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _podiumCard(second, AppColors.silver, '🥈', 90),
          _podiumCard(first, AppColors.gold, '🥇', 110),
          _podiumCard(third, AppColors.bronze, '🥉', 80),
        ],
      ),
    );
  }

  Widget _podiumCard(
      Map<String, dynamic> entry, Color medalColor, String emoji, double height) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          entry['name'].toString().split(' ').first,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${entry['score']}/${entry['total']}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.3),
                medalColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '#${entry['rank']}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingRow(
      Map<String, dynamic> entry, bool isCurrentUser, int index) {
    final rank = entry['rank'] as int;
    final percent = entry['percent'] as double;

    Color? medalColor;
    if (rank == AppConstants.goldRank) medalColor = AppColors.gold;
    if (rank == AppConstants.silverRank) medalColor = AppColors.silver;
    if (rank == AppConstants.bronzeRank) medalColor = AppColors.bronze;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = (index * 0.08).clamp(0.0, 0.8);
        final animValue = Interval(delay, delay + 0.2, curve: Curves.easeOut)
            .transform(_animController.value);

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentUser
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: isCurrentUser ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Rank Badge ──
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: medalColor?.withValues(alpha: 0.2) ??
                    AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: medalColor != null
                    ? Border.all(color: medalColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: medalColor ?? AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Student Name + "You" Badge ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry['name'],
                          style: GoogleFonts.inter(
                            fontWeight:
                                isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'You',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Progress Bar ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percent >= 90
                            ? AppColors.success
                            : percent >= 70
                                ? AppColors.info
                                : percent >= 50
                                    ? AppColors.warning
                                    : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // ── Score ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry['score']}/${entry['total']}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
