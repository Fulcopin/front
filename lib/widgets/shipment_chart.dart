import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

class ShipmentChart extends StatelessWidget {
  const ShipmentChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de envíos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Distribución mensual de envíos por estado',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'Entregados', AppTheme.primaryColor),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'En tránsito', AppTheme.secondaryColor),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'Retrasados', AppTheme.errorColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String month;
              switch (group.x.toInt()) {
                case 0:
                  month = 'Ene';
                  break;
                case 1:
                  month = 'Feb';
                  break;
                case 2:
                  month = 'Mar';
                  break;
                case 3:
                  month = 'Abr';
                  break;
                case 4:
                  month = 'May';
                  break;
                case 5:
                  month = 'Jun';
                  break;
                default:
                  month = '';
              }
              String title;
              switch (rodIndex) {
                case 0:
                  title = 'Entregados';
                  break;
                case 1:
                  title = 'En tránsito';
                  break;
                case 2:
                  title = 'Retrasados';
                  break;
                default:
                  title = '';
              }
              return BarTooltipItem(
                '$title\n${rod.toY.round()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'Ene';
                    break;
                  case 1:
                    text = 'Feb';
                    break;
                  case 2:
                    text = 'Mar';
                    break;
                  case 3:
                    text = 'Abr';
                    break;
                  case 4:
                    text = 'May';
                    break;
                  case 5:
                    text = 'Jun';
                    break;
                  default:
                    text = '';
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppTheme.mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 10 != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppTheme.mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.secondaryColor,
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: [
          _buildBarGroup(0, 40, 24, 5),
          _buildBarGroup(1, 30, 18, 3),
          _buildBarGroup(2, 45, 20, 2),
          _buildBarGroup(3, 50, 32, 4),
          _buildBarGroup(4, 35, 15, 1),
          _buildBarGroup(5, 60, 25, 3),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double entregados,
    double enTransito,
    double retrasados,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: entregados,
          color: AppTheme.primaryColor,
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: enTransito,
          color: AppTheme.secondaryColor,
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: retrasados,
          color: AppTheme.errorColor,
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

