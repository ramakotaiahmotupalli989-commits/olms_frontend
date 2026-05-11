/// EduCinema LMS — Teacher Performance Overview
/// Score distribution pie chart + class analytics for teachers.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class PerformanceOverview extends StatelessWidget {
  const PerformanceOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Performance Analytics',
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
            const SizedBox(height: 24),

            // ── KPI Cards ──
            _buildKpiRow(),
            const SizedBox(height: 24),

            // ── Score Distribution Pie Chart ──
            _buildScoreDistributionCard(),
            const SizedBox(height: 24),

            // ── Quick Summary ──
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          _kpiCard('Total Students', '28', Icons.people_rounded, AppColors.primary),
          _kpiCard('Average Score', '78.5%', Icons.trending_up_rounded, AppColors.success),
          _kpiCard('Highest Score', '96/100', Icons.emoji_events_rounded, AppColors.gold),
          _kpiCard('Lowest Score', '42/100', Icons.trending_down_rounded, AppColors.error),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c)))
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList(),
        );
      },
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistributionCard() {
    final bands = [
      _BandData('90-100%', 5, const Color(0xFF4CAF50)),
      _BandData('80-90%', 7, const Color(0xFF2196F3)),
      _BandData('60-80%', 9, const Color(0xFFFFC107)),
      _BandData('40-60%', 4, const Color(0xFFFF9800)),
      _BandData('0-40%', 3, const Color(0xFFE53935)),
    ];

    final total = bands.fold<int>(0, (sum, b) => sum + b.count);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Distribution',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              if (isWide) {
                return Row(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: _buildPieChart(bands, total),
                    ),
                    const SizedBox(width: 32),
                    Expanded(child: _buildLegend(bands, total)),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: _buildPieChart(bands, total),
                  ),
                  const SizedBox(height: 20),
                  _buildLegend(bands, total),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<_BandData> bands, int total) {
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 40,
        sections: bands.map((band) {
          final percent = (band.count / total * 100);
          return PieChartSectionData(
            color: band.color,
            value: band.count.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            titleStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            radius: 50,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(List<_BandData> bands, int total) {
    return Column(
      children: bands.map((band) {
        final percent = (band.count / total * 100).toStringAsFixed(1);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: band.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                band.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${band.count} students ($percent%)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.secondary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 students scored below 40%. Consider scheduling a revision session for Chapter 5.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandData {
  final String label;
  final int count;
  final Color color;
  const _BandData(this.label, this.count, this.color);
}
