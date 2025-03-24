import 'package:flutter/material.dart';
import '../theme.dart';

class ClientShipmentsOverview extends StatelessWidget {
  const ClientShipmentsOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para los envíos
    final shipments = [
      {
        'id': 'VB-12345678',
        'date': '15 Mar 2025',
        'status': 'En tránsito',
      },
      {
        'id': 'VB-87654321',
        'date': '10 Mar 2025',
        'status': 'Entregado',
      },
      {
        'id': 'VB-23456789',
        'date': '05 Mar 2025',
        'status': 'Procesando',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Envíos Recientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Estado de tus envíos recientes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            shipments.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: [
                      ...shipments.map((shipment) => _buildShipmentItem(context, shipment)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/my-shipments'),
                        child: const Text('Ver todos los envíos'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 48,
            color: AppTheme.mutedTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes envíos recientes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un envío para comenzar a utilizar nuestro servicio',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/my-shipments'),
            child: const Text('Crear Envío'),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentItem(BuildContext context, Map<String, String> shipment) {
    Color statusColor;
    switch (shipment['status']) {
      case 'Entregado':
        statusColor = AppTheme.successColor;
        break;
      case 'En tránsito':
        statusColor = AppTheme.primaryColor;
        break;
      case 'Procesando':
        statusColor = AppTheme.warningColor;
        break;
      default:
        statusColor = AppTheme.mutedTextColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.secondaryColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envío ${shipment['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  shipment['date'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              shipment['status'] ?? '',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

