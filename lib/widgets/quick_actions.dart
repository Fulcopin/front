import 'package:flutter/material.dart';
import '../theme.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Accede a las funciones más utilizadas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Nuevo envío',
              Icons.add,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Rastrear paquete',
              Icons.search,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Programar recogida',
              Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Generar reporte',
              Icons.description_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

