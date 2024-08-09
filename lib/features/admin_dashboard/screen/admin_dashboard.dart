import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/admin_dashboard/controller/admin_dashboard_controller.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final postCount = ref.watch(getTodayPostsCountProvider('LeagueOfLegends'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: postCount.when(
          data: (data) {
            return BarChart(
              BarChartData(
                barGroups: _createBarGroups(data),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString().padLeft(2, '0'));
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('Error: $error'),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<int, int> counts) {
    return counts.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.blue,
          )
        ],
      );
    }).toList();
  }
}
