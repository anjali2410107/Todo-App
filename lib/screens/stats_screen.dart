import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/todo/todo_bloc.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state is! TodoLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = state.todos;
          final total = todos.length;
          final completed = todos.where((t) => t.isCompleted).length;
          final pending = total - completed;

          final high = todos.where((t) => t.priority == TaskPriority.high).length;
          final medium = todos.where((t) => t.priority == TaskPriority.medium).length;
          final low = todos.where((t) => t.priority == TaskPriority.low).length;

          final completionRate = total == 0 ? 0.0 : (completed / total) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSummaryCard(
                      label: 'Total',
                      value: total.toString(),
                      color: Colors.deepPurple,
                      icon: Icons.list_alt,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      label: 'Completed',
                      value: completed.toString(),
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      label: 'Pending',
                      value: pending.toString(),
                      color: Colors.orange,
                      icon: Icons.pending_actions,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Completion Rate',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${completionRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: completionRate >= 70
                                    ? Colors.green
                                    : completionRate >= 40
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: completionRate / 100,
                                  minHeight: 14,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    completionRate >= 70
                                        ? Colors.green
                                        : completionRate >= 40
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Completed vs Pending',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (total == 0 ? 1 : total).toDouble() + 1,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Completed',
                                              style: TextStyle(fontSize: 12));
                                        case 1:
                                          return const Text('Pending',
                                              style: TextStyle(fontSize: 12));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                    SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                    SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: completed.toDouble(),
                                    color: Colors.green,
                                    width: 50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: pending.toDouble(),
                                    color: Colors.orange,
                                    width: 50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tasks by Priority',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (total == 0 ? 1 : total).toDouble() + 1,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('High',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red));
                                        case 1:
                                          return const Text('Medium',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange));
                                        case 2:
                                          return const Text('Low',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                    SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                    SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: high.toDouble(),
                                    color: Colors.red,
                                    width: 50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: medium.toDouble(),
                                    color: Colors.orange,
                                    width: 50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                                BarChartGroupData(x: 2, barRods: [
                                  BarChartRodData(
                                    toY: low.toDouble(),
                                    color: Colors.green,
                                    width: 50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}