import 'package:flutter/material.dart';
import '../theme.dart';

class Shipment {
  final String id;
  final String trackingNumber;
  final String customer;
  final String origin;
  final String destination;
  final ShipmentStatus status;
  final String date;

  Shipment({
    required this.id,
    required this.trackingNumber,
    required this.customer,
    required this.origin,
    required this.destination,
    required this.status,
    required this.date,
  });
}

enum ShipmentStatus {
  delivered,
  inTransit,
  processing,
  delayed,
}

extension ShipmentStatusExtension on ShipmentStatus {
  String get label {
    switch (this) {
      case ShipmentStatus.delivered:
        return 'Entregado';
      case ShipmentStatus.inTransit:
        return 'En tránsito';
      case ShipmentStatus.processing:
        return 'Procesando';
      case ShipmentStatus.delayed:
        return 'Retrasado';
    }
  }

  Color get color {
    switch (this) {
      case ShipmentStatus.delivered:
        return AppTheme.successColor;
      case ShipmentStatus.inTransit:
        return AppTheme.primaryColor;
      case ShipmentStatus.processing:
        return AppTheme.warningColor;
      case ShipmentStatus.delayed:
        return AppTheme.errorColor;
    }
  }
}

class RecentShipments extends StatelessWidget {
  const RecentShipments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shipments = [
      Shipment(
        id: '1',
        trackingNumber: 'VB-12345678',
        customer: 'Juan Pérez',
        origin: 'Miami, FL',
        destination: 'Ciudad de México, MX',
        status: ShipmentStatus.inTransit,
        date: '2025-03-14',
      ),
      Shipment(
        id: '2',
        trackingNumber: 'VB-87654321',
        customer: 'María González',
        origin: 'Los Angeles, CA',
        destination: 'Guadalajara, MX',
        status: ShipmentStatus.processing,
        date: '2025-03-13',
      ),
      Shipment(
        id: '3',
        trackingNumber: 'VB-23456789',
        customer: 'Carlos Rodríguez',
        origin: 'New York, NY',
        destination: 'Monterrey, MX',
        status: ShipmentStatus.delivered,
        date: '2025-03-12',
      ),
      Shipment(
        id: '4',
        trackingNumber: 'VB-98765432',
        customer: 'Ana Martínez',
        origin: 'Chicago, IL',
        destination: 'Cancún, MX',
        status: ShipmentStatus.delayed,
        date: '2025-03-11',
      ),
      Shipment(
        id: '5',
        trackingNumber: 'VB-34567890',
        customer: 'Roberto Sánchez',
        origin: 'Houston, TX',
        destination: 'Tijuana, MX',
        status: ShipmentStatus.inTransit,
        date: '2025-03-10',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envíos recientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  // Tabla para pantallas grandes
                  return _buildShipmentsTable(context, shipments);
                } else {
                  // Lista para pantallas pequeñas
                  return _buildShipmentsList(context, shipments);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentsTable(BuildContext context, List<Shipment> shipments) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tracking')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Origen')),
          DataColumn(label: Text('Destino')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: shipments.map((shipment) {
          return DataRow(
            cells: [
              DataCell(Text(
                shipment.trackingNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(Text(shipment.customer)),
              DataCell(Text(shipment.origin)),
              DataCell(Text(shipment.destination)),
              DataCell(_buildStatusBadge(shipment.status)),
              DataCell(Text(shipment.date)),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShipmentsList(BuildContext context, List<Shipment> shipments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shipments.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final shipment = shipments[index];
        return ListTile(
          title: Text(
            shipment.trackingNumber,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(shipment.customer),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(shipment.status),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ShipmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

