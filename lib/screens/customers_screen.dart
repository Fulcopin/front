import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  String _filterValue = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    // Simular carga de datos
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _customers = [
        {
          'id': '1',
          'name': 'Juan Pérez',
          'email': 'juan.perez@example.com',
          'phone': '+52 55 1234 5678',
          'address': 'Av. Reforma 123, Col. Juárez, CDMX, 06600, México',
          'shipments': 12,
          'totalSpent': 1250.50,
          'status': 'Activo',
        },
        {
          'id': '2',
          'name': 'María González',
          'email': 'maria.gonzalez@example.com',
          'phone': '+52 55 8765 4321',
          'address': 'Calle Durango 45, Col. Roma, CDMX, 06700, México',
          'shipments': 8,
          'totalSpent': 850.75,
          'status': 'Activo',
        },
        {
          'id': '3',
          'name': 'Carlos Rodríguez',
          'email': 'carlos.rodriguez@example.com',
          'phone': '+52 55 2345 6789',
          'address': 'Av. Insurgentes 789, Col. Condesa, CDMX, 06140, México',
          'shipments': 5,
          'totalSpent': 520.30,
          'status': 'Activo',
        },
        {
          'id': '4',
          'name': 'Ana Martínez',
          'email': 'ana.martinez@example.com',
          'phone': '+52 55 9876 5432',
          'address': 'Calle Sonora 67, Col. Hipódromo, CDMX, 06100, México',
          'shipments': 15,
          'totalSpent': 1800.25,
          'status': 'VIP',
        },
        {
          'id': '5',
          'name': 'Roberto Sánchez',
          'email': 'roberto.sanchez@example.com',
          'phone': '+52 55 3456 7890',
          'address': 'Av. Chapultepec 234, Col. Juárez, CDMX, 06600, México',
          'shipments': 0,
          'totalSpent': 0.00,
          'status': 'Inactivo',
        },
      ];
      _isLoading = false;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar clientes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Todos'),
                value: 'Todos',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Activos'),
                value: 'Activo',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Inactivos'),
                value: 'Inactivo',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('VIP'),
                value: 'VIP',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Filtrar clientes según el filtro seleccionado
    final filteredCustomers = _filterValue == 'Todos'
        ? _customers
        : _customers.where((customer) => customer['status'] == _filterValue).toList();

    // Filtrar por búsqueda
    final searchQuery = _searchController.text.toLowerCase();
    final displayedCustomers = filteredCustomers.where((customer) {
      return customer['name'].toLowerCase().contains(searchQuery) ||
          customer['email'].toLowerCase().contains(searchQuery) ||
          customer['phone'].contains(searchQuery);
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Recargar',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vacabox',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.name ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Envíos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/shipments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Seguimiento'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/tracking');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: const Text('Almacén'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/warehouse');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Clientes'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Facturación'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/billing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Filtro: $_filterValue',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _showFilterDialog,
                  child: const Text('Cambiar'),
                ),
                const Spacer(),
                Text(
                  '${displayedCustomers.length} clientes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedCustomers.isEmpty
                    ? const Center(
                        child: Text('No se encontraron clientes'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = displayedCustomers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    customer['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (customer['status'] == 'VIP')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'VIP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(customer['email']),
                                  Text(customer['phone']),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${customer['shipments']} envíos',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '\$${customer['totalSpent'].toStringAsFixed(2)} USD',
                                    style: TextStyle(
                                      color: customer['totalSpent'] > 1000 ? AppTheme.primaryColor : null,
                                      fontWeight: customer['totalSpent'] > 1000 ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Ver detalles del cliente
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Agregar nuevo cliente
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

