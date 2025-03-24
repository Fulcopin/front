import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Mensual';
  final List<String> _periodOptions = ['Semanal', 'Mensual', 'Trimestral', 'Anual'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Envíos'),
            Tab(text: 'Ingresos'),
            Tab(text: 'Clientes'),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            icon: const Icon(Icons.arrow_drop_down),
            underline: Container(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPeriod = newValue!;
              });
            },
            items: _periodOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              // Lógica para exportar reportes
            },
            tooltip: 'Exportar reporte',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildShipmentsTab(),
          _buildRevenueTab(),
          _buildCustomersTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildShipmentStatusChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          title: 'Total Envíos',
          value: '1,234',
          trend: '+12.5%',
          isPositive: true,
          icon: Icons.inventory_2_outlined,
        ),
        _buildSummaryCard(
          title: 'Ingresos',
          value: '\$45,231',
          trend: '+8.1%',
          isPositive: true,
          icon: Icons.attach_money,
        ),
        _buildSummaryCard(
          title: 'Clientes Nuevos',
          value: '56',
          trend: '+5.4%',
          isPositive: true,
          icon: Icons.people_outline,
        ),
        _buildSummaryCard(
          title: 'Tiempo Promedio',
          value: '3.2 días',
          trend: '-0.5 días',
          isPositive: true,
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  icon,
                  color: AppTheme.mutedTextColor,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos $_selectedPeriod',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.secondaryColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
  show: true,
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 30,
      getTitlesWidget: (double value, TitleMeta meta) {
        const style = TextStyle(
          color: AppTheme.mutedTextColor,
          fontSize: 12,
        );
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
        return SideTitleWidget(
          child: Text(text, style: style),
          meta: meta, // Add required meta parameter
        );
      },
    ),
  ),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(
                            color: AppTheme.mutedTextColor,
                            fontSize: 12,
                          );
                          String text;
                          if (value == 0) {
                            text = '\$0';
                          } else if (value == 20000) {
                            text = '\$20K';
                          } else if (value == 40000) {
                            text = '\$40K';
                          } else if (value == 60000) {
                            text = '\$60K';
                          } else {
                            return const SizedBox();
                          }
                          return SideTitleWidget(
                              child: Text(text, style: style),
                              meta: meta, // Add required meta parameter
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
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: 60000,
                  lineBarsData: [
                    LineChartBarData(
                    spots: const [
                      FlSpot(0, 30000),
                      FlSpot(1, 25000),
                      FlSpot(2, 40000),
                      FlSpot(3, 35000),
                      FlSpot(4, 50000),
                      FlSpot(5, 45000),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildShipmentStatusChart() {
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
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.primaryColor,
                      value: 65,
                      title: '65%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppTheme.warningColor,
                      value: 25,
                      title: '25%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppTheme.errorColor,
                      value: 10,
                      title: '10%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Entregados', AppTheme.primaryColor),
                const SizedBox(width: 24),
                _buildLegendItem('En tránsito', AppTheme.warningColor),
                const SizedBox(width: 24),
                _buildLegendItem('Retrasados', AppTheme.errorColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
        Text(label),
      ],
    );
  }

  Widget _buildShipmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShipmentsByStatusChart(),
          const SizedBox(height: 24),
          _buildShipmentsByOriginChart(),
          const SizedBox(height: 24),
          _buildShipmentsByDestinationChart(),
        ],
      ),
    );
  }

  Widget _buildShipmentsByStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envíos por estado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(
                            color: AppTheme.mutedTextColor,
                            fontSize: 12,
                          );
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Entregados';
                              break;
                            case 1:
                              text = 'En tránsito';
                              break;
                            case 2:
                              text = 'Procesando';
                              break;
                            case 3:
                              text = 'Retrasados';
                              break;
                            default:
                              text = '';
                          }
                              return SideTitleWidget(
                                  meta: meta,
                                  child: Text(text, style: style),
                                );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                        if (value % 20 != 0) return const SizedBox();
                        return SideTitleWidget(
                          meta: meta,  // Add this line
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
                    horizontalInterval: 20,
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
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 65,
                          color: AppTheme.primaryColor,
                          width: 25,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 25,
                          color: AppTheme.warningColor,
                          width: 25,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 8,
                          color: AppTheme.secondaryColor,
                          width: 25,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: 2,
                          color: AppTheme.errorColor,
                          width: 25,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentsByOriginChart() {
    // Implementación similar a los otros gráficos
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envíos por origen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Top 5 ciudades de origen'),
            const SizedBox(height: 24),
            // Aquí iría un gráfico similar
            const Placeholder(
              fallbackHeight: 250,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentsByDestinationChart() {
    // Implementación similar a los otros gráficos
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envíos por destino',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Top 5 ciudades de destino'),
            const SizedBox(height: 24),
            // Aquí iría un gráfico similar
            const Placeholder(
              fallbackHeight: 250,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab() {
    // Implementación similar a los otros tabs
    return const Center(
      child: Text('Contenido de ingresos en desarrollo'),
    );
  }

  Widget _buildCustomersTab() {
    // Implementación similar a los otros tabs
    return const Center(
      child: Text('Contenido de clientes en desarrollo'),
    );
  }
}

