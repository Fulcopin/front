import 'package:flutter/material.dart';
import '../theme.dart';

class AdminPendingPayments extends StatelessWidget {
  final List<Map<String, dynamic>> pendingPayments;
  final bool isLoading;
  final Function(Map<String, dynamic>)? onNotifyUser;
  final Function(Map<String, dynamic>)? onMarkAsPaid;
  final Function(Map<String, dynamic>)? onViewDetails;

  const AdminPendingPayments({
    Key? key,
    required this.pendingPayments,
    this.isLoading = false,
    this.onNotifyUser,
    this.onMarkAsPaid,
    this.onViewDetails,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pagos Pendientes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    // Ver todos los pagos pendientes
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver Todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingPayments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay pagos pendientes',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingPayments.length > 5 ? 5 : pendingPayments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final payment = pendingPayments[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(payment['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cliente: ${payment['user']}'),
                        const SizedBox(height: 4),
                        Text(
                          'Llegó el ${payment['arrivalDate']} - \$${payment['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_active_outlined),
                          onPressed: () => onNotifyUser?.call(payment),
                          tooltip: 'Notificar Usuario',
                          color: Colors.orange,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => onMarkAsPaid?.call(payment),
                          tooltip: 'Marcar como Pagado',
                          color: Colors.green,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => onViewDetails?.call(payment),
                          tooltip: 'Ver Detalles',
                          iconSize: 20,
                        ),
                      ],
                    ),
                    onTap: () => onViewDetails?.call(payment),
                  );
                },
              ),
          ],
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pagos Pendientes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver Todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

