import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class WeeklyChartCard extends StatefulWidget {
  final Map<String, int> weeklyUsage; // date string -> milliseconds
  final int dailyLimit;

  const WeeklyChartCard({
    super.key,
    required this.weeklyUsage,
    required this.dailyLimit,
  });

  @override
  State<WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<WeeklyChartCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final chartData = _prepareChartData();
    final totalMinutes = chartData.fold<int>(0, (sum, item) => sum + item.minutes);
    final avgMinutes = chartData.isNotEmpty ? (totalMinutes / chartData.length).round() : 0;
    final maxMinutes = chartData.isNotEmpty 
        ? chartData.map((e) => e.minutes).reduce((a, b) => a > b ? a : b)
        : 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.accentCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Last 7 days activity',
                      style: TextStyle(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Average Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: AppTheme.primaryPurple,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg: ${avgMinutes}m',
                      style: const TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 180,
            child: chartData.isEmpty
                ? _buildEmptyState()
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxMinutes > widget.dailyLimit 
                          ? maxMinutes.toDouble() 
                          : widget.dailyLimit.toDouble()) * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          //tooltipBgColor: AppTheme.darkSurface,
                          tooltipRoundedRadius: 12,
                          tooltipPadding: const EdgeInsets.all(12),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final data = chartData[group.x];
                            return BarTooltipItem(
                              '${data.dayName}\n',
                              const TextStyle(
                                color: AppTheme.darkTextSecondary,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '${data.minutes} min',
                                  style: TextStyle(
                                    color: _getBarColor(data.minutes),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (response != null && 
                                response.spot != null &&
                                event is FlTapUpEvent) {
                              _touchedIndex = response.spot!.touchedBarGroupIndex;
                            } else if (event is FlTapUpEvent || 
                                       event is FlPanEndEvent) {
                              _touchedIndex = null;
                            }
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= chartData.length) {
                                return const SizedBox();
                              }
                              final data = chartData[value.toInt()];
                              final isToday = data.isToday;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data.shortDay,
                                      style: TextStyle(
                                        color: isToday 
                                            ? AppTheme.primaryPurple 
                                            : AppTheme.darkTextMuted,
                                        fontSize: 11,
                                        fontWeight: isToday 
                                            ? FontWeight.w700 
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (isToday)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryPurple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: _getInterval(maxMinutes),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}m',
                                style: const TextStyle(
                                  color: AppTheme.darkTextMuted,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getInterval(maxMinutes),
                        getDrawingHorizontalLine: (value) {
                          // Highlight limit line
                          if (value == widget.dailyLimit.toDouble()) {
                            return FlLine(
                              color: AppTheme.dangerRed.withOpacity(0.5),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                            );
                          }
                          return FlLine(
                            color: Colors.white.withOpacity(0.05),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: chartData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final isTouched = _touchedIndex == index;
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data.minutes.toDouble(),
                              width: isTouched ? 20 : 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  _getBarColor(data.minutes),
                                  _getBarColor(data.minutes).withOpacity(0.7),
                                ],
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: (maxMinutes > widget.dailyLimit 
                                    ? maxMinutes.toDouble() 
                                    : widget.dailyLimit.toDouble()) * 1.2,
                                color: AppTheme.darkSurfaceLight.withOpacity(0.5),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: AppTheme.successGreen,
                label: 'Under limit',
              ),
              SizedBox(width: 20),
              _LegendItem(
                color: AppTheme.warningOrange,
                label: 'Near limit',
              ),
              SizedBox(width: 20),
              _LegendItem(
                color: AppTheme.dangerRed,
                label: 'Over limit',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Limit line indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Container(
                width: 4,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: Colors.transparent,
              ),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily limit (${widget.dailyLimit}m)',
                style: const TextStyle(
                  color: AppTheme.darkTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: AppTheme.darkTextMuted,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No data yet',
            style: TextStyle(
              color: AppTheme.darkTextSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Start using the app to see your stats',
            style: TextStyle(
              color: AppTheme.darkTextMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<ChartData> _prepareChartData() {
    final List<ChartData> data = [];
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = dateFormat.format(date);
      final usageMs = widget.weeklyUsage[dateStr] ?? 0;
      final usageMinutes = (usageMs / 60000).round();

      data.add(ChartData(
        date: date,
        minutes: usageMinutes,
        dayName: DateFormat('EEEE').format(date),
        shortDay: DateFormat('E').format(date).substring(0, 2),
        isToday: i == 0,
      ));
    }

    return data;
  }

  Color _getBarColor(int minutes) {
    final percentage = minutes / widget.dailyLimit;
    if (percentage >= 1.0) return AppTheme.dangerRed;
    if (percentage >= 0.8) return AppTheme.warningOrange;
    return AppTheme.successGreen;
  }

  double _getInterval(int maxMinutes) {
    if (maxMinutes <= 10) return 5;
    if (maxMinutes <= 30) return 10;
    if (maxMinutes <= 60) return 15;
    if (maxMinutes <= 120) return 30;
    return 60;
  }
}

class ChartData {
  final DateTime date;
  final int minutes;
  final String dayName;
  final String shortDay;
  final bool isToday;

  ChartData({
    required this.date,
    required this.minutes,
    required this.dayName,
    required this.shortDay,
    required this.isToday,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkTextMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}