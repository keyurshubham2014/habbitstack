import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/log_service.dart';

class SentimentTrendChart extends StatefulWidget {
  final int userId;
  final int days;

  const SentimentTrendChart({
    super.key,
    required this.userId,
    this.days = 30,
  });

  @override
  State<SentimentTrendChart> createState() => _SentimentTrendChartState();
}

class _SentimentTrendChartState extends State<SentimentTrendChart> {
  final LogService _logService = LogService();
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _logService.getSentimentDistribution(widget.userId, days: widget.days),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final distribution = snapshot.data!;
        final total = distribution.values.fold(0, (sum, count) => sum + count);

        if (total == 0) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Chart
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _buildSections(distribution, total),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Legend
            _buildLegend(distribution, total),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, int> distribution, int total) {
    final sections = <PieChartSectionData>[];
    int index = 0;

    // Happy
    if (distribution['happy']! > 0) {
      sections.add(_buildSection(
        'happy',
        distribution['happy']!,
        total,
        index,
        AppColors.successGreen,
        Icons.sentiment_very_satisfied,
      ));
      index++;
    }

    // Neutral
    if (distribution['neutral']! > 0) {
      sections.add(_buildSection(
        'neutral',
        distribution['neutral']!,
        total,
        index,
        AppColors.neutralGray,
        Icons.sentiment_neutral,
      ));
      index++;
    }

    // Struggled
    if (distribution['struggled']! > 0) {
      sections.add(_buildSection(
        'struggled',
        distribution['struggled']!,
        total,
        index,
        AppColors.warningAmber,
        Icons.sentiment_dissatisfied,
      ));
      index++;
    }

    return sections;
  }

  PieChartSectionData _buildSection(
    String sentiment,
    int count,
    int total,
    int index,
    Color color,
    IconData icon,
  ) {
    final isTouched = index == touchedIndex;
    final double radius = isTouched ? 65 : 55;
    final double fontSize = isTouched ? 20 : 16;
    final percentage = (count / total * 100).toStringAsFixed(1);

    return PieChartSectionData(
      color: color,
      value: count.toDouble(),
      title: '$percentage%',
      radius: radius,
      titleStyle: AppTextStyles.title().copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.invertedText,
        shadows: [
          const Shadow(
            color: Colors.black26,
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, int> distribution, int total) {
    return Column(
      children: [
        if (distribution['happy']! > 0)
          _buildLegendItem(
            'Great',
            distribution['happy']!,
            total,
            AppColors.successGreen,
            Icons.sentiment_very_satisfied,
          ),
        if (distribution['neutral']! > 0)
          _buildLegendItem(
            'Okay',
            distribution['neutral']!,
            total,
            AppColors.neutralGray,
            Icons.sentiment_neutral,
          ),
        if (distribution['struggled']! > 0)
          _buildLegendItem(
            'Struggled',
            distribution['struggled']!,
            total,
            AppColors.warningAmber,
            Icons.sentiment_dissatisfied,
          ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = (count / total * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body().copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: AppTextStyles.body().copyWith(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: AppColors.neutralGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No sentiment data yet',
              style: AppTextStyles.title().copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log activities with sentiments to see your mood trends',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
