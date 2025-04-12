import 'package:flutter/material.dart';
import '../theme.dart';

class AdminStatsOverview extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;

  const AdminStatsOverview({
    Key? key,
    required this.stats,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determinar cuántas tarjetas por fila según el ancho
                int crossAxisCount = 1;
                if (constraints.maxWidth > 600) crossAxisCount = 2;
                if (constraints.maxWidth > 900) crossAxisCount = 3;
                if (constraints.maxWidth > 1200) crossAxisCount = 4;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context,
                      'Usuarios',
                      stats['totalUsers'].toString(),
                      Icons.people_outline,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Productos',
                      stats['totalProducts'].toString(),
                      Icons.inventory_2_outlined,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Envíos',
                      stats['totalShipments'].toString(),
                      Icons.local_shipping_outlined,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Pagos Pendientes',
                      stats['pendingPayments'].toString(),
                      Icons.payment_outlined,
                      Colors.red,
                    ),
                    _buildStatCard(
                      context,
                      'En Bodega',
                      stats['productsInWarehouse'].toString(),
                      Icons.warehouse_outlined,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      context,
                      'En Tránsito',
                      stats['productsInTransit'].toString(),
                      Icons.flight_takeoff_outlined,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      context,
                      'Entregados',
                      stats['productsDelivered'].toString(),
                      Icons.check_circle_outline,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      context,
                      'Ingresos',
                      '\$${stats['revenue'].toStringAsFixed(2)}',
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedTextColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                8,
                (index) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

