import 'package:flutter/material.dart';
import '../theme.dart';

class ClientQuickActions extends StatelessWidget {
  const ClientQuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
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
              'Gestionar Productos',
              Icons.shopping_cart_outlined,
              () => Navigator.pushNamed(context, '/products'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Realizar Pago',
              Icons.credit_card_outlined,
              () => Navigator.pushNamed(context, '/payments'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Mis Envíos',
              Icons.inventory_2_outlined,
              () => Navigator.pushNamed(context, '/my-shipments'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Mi Perfil',
              Icons.person_outline,
              () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

