import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task.dart';

enum ChartPeriod { week, month }

class TaskPieChart extends StatefulWidget {
  final List<Task> tasks;
  final DateTime selectedMonth;

  const TaskPieChart({
    Key? key,
    required this.tasks,
    required this.selectedMonth,
  }) : super(key: key);

  @override
  State<TaskPieChart> createState() => _TaskPieChartState();
}

class _TaskPieChartState extends State<TaskPieChart> {
  ChartPeriod _selectedPeriod = ChartPeriod.month;
  String _selectedMonthlyView = 'Category'; // 'Category', 'Priority', 'Status'

  Map<String, int> _getCategoryDistribution() {
    final filteredTasks = _getFilteredTasks();
    final distribution = <String, int>{};
    
    for (final task in filteredTasks) {
      distribution[task.category] = (distribution[task.category] ?? 0) + 1;
    }
    
    return distribution;
  }

  Map<String, int> _getPriorityDistribution() {
    final filteredTasks = _getFilteredTasks();
    final distribution = <String, int>{};
    
    for (final task in filteredTasks) {
      distribution[task.priority] = (distribution[task.priority] ?? 0) + 1;
    }
    
    return distribution;
  }

  Map<String, int> _getStatusDistribution() {
    final filteredTasks = _getFilteredTasks();
    final distribution = <String, int>{};
    
    for (final task in filteredTasks) {
      final status = task.isCompleted ? 'Completed' : 'Pending';
      distribution[status] = (distribution[status] ?? 0) + 1;
    }
    
    return distribution;
  }

  List<Task> _getFilteredTasks() {
    final now = DateTime.now();
    
    if (_selectedPeriod == ChartPeriod.week) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      return widget.tasks.where((task) =>
        task.dueDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        task.dueDate.isBefore(endOfWeek.add(const Duration(days: 1)))
      ).toList();
    } else {
      return widget.tasks.where((task) =>
        task.dueDate.year == widget.selectedMonth.year &&
        task.dueDate.month == widget.selectedMonth.month
      ).toList();
    }
  }

  List<Color> _getCategoryColors() {
    return [
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
    ];
  }

  Map<String, int> _getCurrentDistribution() {
    switch (_selectedMonthlyView) {
      case 'Priority':
        return _getPriorityDistribution();
      case 'Status':
        return _getStatusDistribution();
      default:
        return _getCategoryDistribution();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final distribution = _getCurrentDistribution();
    final colors = _getCategoryColors();

    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Distribution',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              DropdownButton<ChartPeriod>(
                value: _selectedPeriod,
                onChanged: (ChartPeriod? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedPeriod = newValue);
                  }
                },
                items: ChartPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(
                      period.name.toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_selectedPeriod == ChartPeriod.month) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Category', 'Priority', 'Status'].map((view) {
                  final isSelected = _selectedMonthlyView == view;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(view),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _selectedMonthlyView = view);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: List.generate(
                        distribution.length,
                        (index) {
                          final entry = distribution.entries.elementAt(index);
                          final total = distribution.values.reduce((a, b) => a + b);
                          final percentage = (entry.value / total) * 100;
                          
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: entry.value.toDouble(),
                            title: '${percentage.round()}%',
                            radius: 65,
                            titleStyle: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      distribution.length,
                      (index) {
                        final entry = distribution.entries.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entry.key} (${entry.value})',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
