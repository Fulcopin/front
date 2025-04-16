import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import '../services/admin_stats_service.dart';

class AdminShipmentsChart extends StatefulWidget {
  const AdminShipmentsChart({Key? key}) : super(key: key);

  @override
  _AdminShipmentsChartState createState() => _AdminShipmentsChartState();
}

class _AdminShipmentsChartState extends State<AdminShipmentsChart> {
  final AdminStatsService _statsService = AdminStatsService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyData = [];
  String _selectedYear = DateTime.now().year.toString();
  
  // Available years from data
  List<String> _availableYears = [];
  
  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }
  
  Future<void> _loadMonthlyData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final monthlyData = await _statsService.getMonthlyRevenue();
      
      // Extract available years from data
      final years = monthlyData
          .map((item) => item['year'].toString())
          .toSet()
          .toList();
      years.sort();
      
      setState(() {
        _monthlyData = monthlyData;
        _availableYears = years;
        if (years.isNotEmpty && !years.contains(_selectedYear)) {
          _selectedYear = years.last; // Select most recent year by default
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading monthly data: $e');
      setState(() {
        _monthlyData = [];
        _isLoading = false;
      });
    }
  }

  // Filter data for the selected year
  List<Map<String, dynamic>> _getFilteredData() {
    return _monthlyData
        .where((item) => item['year'].toString() == _selectedYear)
        .toList();
  }

  // Get max revenue value for Y-axis scaling
  double _getMaxRevenue() {
    if (_monthlyData.isEmpty) return 1000.0;
    
    final filteredData = _getFilteredData();
    if (filteredData.isEmpty) return 1000.0;
    
    return filteredData
        .map<double>((item) => (item['revenue'] as num).toDouble())
        .reduce((max, value) => value > max ? value : max) * 1.2; // Add 20% padding
  }

  // Generate bars for the chart
  List<BarChartGroupData> _getBarGroups() {
    final filteredData = _getFilteredData();
    final List<BarChartGroupData> barGroups = [];
    
    // Month names for display
    final monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    // Create a map to easily look up revenue by month
    final Map<int, double> revenueByMonth = {};
    for (final item in filteredData) {
      final month = item['month'] as int;
      final revenue = (item['revenue'] as num).toDouble();
      revenueByMonth[month] = revenue;
    }
    
    // Create bar groups for all 12 months (even if some have zero revenue)
    for (int i = 1; i <= 12; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenueByMonth[i] ?? 0,
              color: Colors.blue,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxRevenue() / 20, // Subtle background
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ingresos por Mes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (_availableYears.isNotEmpty) ...[
                        const Text('Año: '),
                        DropdownButton<String>(
                          value: _selectedYear,
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedYear = newValue;
                              });
                            }
                          },
                          items: _availableYears.map((year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(year),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 16),
                      ],
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadMonthlyData,
                        tooltip: 'Actualizar datos',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (_monthlyData.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, 
                                     color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'No se pudieron cargar los datos de ingresos mensuales',
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filteredData = _getFilteredData();
                  if (filteredData.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No hay datos para el año $_selectedYear',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  // Calculate total for the selected year
                  final totalRevenue = filteredData
                      .map((item) => (item['revenue'] as num).toDouble())
                      .fold(0.0, (sum, item) => sum + item);
                  
                  return Column(
                    children: [
                      // Year summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total $_selectedYear: \$${NumberFormat('#,##0.00').format(totalRevenue)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Chart
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxRevenue(),
                            minY: 0,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final monthNames = [
                                    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
                                  ];
                                  return BarTooltipItem(
                                    '${monthNames[group.x.toInt() - 1]}\n\$${NumberFormat('#,##0.00').format(rod.toY)}',
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
                                final monthNames = [
                                  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                                  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                                ];
                                if (value.toInt() >= 1 && value.toInt() <= 12) {
                                  return Text(monthNames[value.toInt() - 1]);
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('\$0');
                                return Text('\$${NumberFormat.compact().format(value)}');
                              },
                              reservedSize: 40,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                        ),
                            borderData: FlBorderData(show: false),
                            barGroups: _getBarGroups(),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: _getMaxRevenue() / 5,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey[300],
                                  strokeWidth: 1,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}