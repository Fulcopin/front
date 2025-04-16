import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/admin_stats_service.dart';


class AdminStatsOverview extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AdminStatsOverview({
    Key? key, 
    required this.stats,
    this.isLoading = false,
    this.onRefresh,
  }) : super(key: key);

  Widget _buildStatCard(BuildContext context, String title, String value, 
                       IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estadísticas Generales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Actualizar estadísticas',
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                if (isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (stats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, 
                                     color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No se pudieron cargar las estadísticas',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      'Usuarios',
                      stats['totalUsers']?.toString() ?? '0',
                      Icons.people_outline,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Productos',
                      stats['totalProducts']?.toString() ?? '0',
                      Icons.inventory_2_outlined,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Envíos',
                      stats['totalShipments']?.toString() ?? '0',
                      Icons.local_shipping_outlined,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Pagos Pendientes',
                      stats['pendingPayments']?.toString() ?? '0',
                      Icons.payment_outlined,
                      Colors.red,
                    ),
                    _buildStatCard(
                      context,
                      'En Bodega',
                      stats['productsInWarehouse']?.toString() ?? '0',
                      Icons.warehouse_outlined,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      context,
                      'En Tránsito',
                      stats['productsInTransit']?.toString() ?? '0',
                      Icons.flight_takeoff_outlined,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      context,
                      'Entregados',
                      stats['productsDelivered']?.toString() ?? '0',
                      Icons.check_circle_outline,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      context,
                      'Ingresos',
                      '\$${(stats['revenue'] ?? 0.0).toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.amber.shade700,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}