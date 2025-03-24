import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({Key? key}) : super(key: key);

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _shipments = [];
  String _filterValue = 'Todos';
  
  @override
  void initState() {
    super.initState();
    _loadShipments();
  }
  
  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simular carga de datos
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _shipments = [
        {
          'id': '1',
          'trackingNumber': 'VB-12345678',
          'customer': 'Juan Pérez',
          'origin': 'Miami, FL',
          'destination': 'Ciudad de México, MX',
          'status': 'En tránsito',
          'date': '2025-03-14',
        },
        {
          'id': '2',
          'trackingNumber': 'VB-87654321',
          'customer': 'María González',
          'origin': 'Los Angeles, CA',
          'destination': 'Guadalajara, MX',
          'status': 'Procesando',
          'date': '2025-03-13',
        },
        {
          'id': '3',
          'trackingNumber': 'VB-23456789',
          'customer': 'Carlos Rodríguez',
          'origin': 'New York, NY',
          'destination': 'Monterrey, MX',
          'status': 'Entregado',
          'date': '2025-03-12',
        },
        {
          'id': '4',
          'trackingNumber': 'VB-98765432',
          'customer': 'Ana Martínez',
          'origin': 'Chicago, IL',
          'destination': 'Cancún, MX',
          'status': 'Retrasado',
          'date': '2025-03-11',
        },
        {
          'id': '5',
          'trackingNumber': 'VB-34567890',
          'customer': 'Roberto Sánchez',
          'origin': 'Houston, TX',
          'destination': 'Tijuana, MX',
          'status': 'En tránsito',
          'date': '2025-03-10',
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
          title: const Text('Filtrar envíos'),
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
                title: const Text('En tránsito'),
                value: 'En tránsito',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Entregados'),
                value: 'Entregado',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Procesando'),
                value: 'Procesando',
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Retrasados'),
                value: 'Retrasado',
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
  
  void _showNewShipmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Envío'),
          content: const SingleChildScrollView(
            child: Text('Formulario para crear envío (en desarrollo)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envío creado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadShipments();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Filtrar envíos según el filtro seleccionado
    final filteredShipments = _filterValue == 'Todos'
        ? _shipments
        : _shipments.where((shipment) => shipment['status'] == _filterValue).toList();
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Gestión de Envíos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShipments,
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
              selected: true,
              onTap: () {
                Navigator.pop(context);
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
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/customers');
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
              decoration: const InputDecoration(
                hintText: 'Buscar envío por tracking, cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Implementar búsqueda
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
                ElevatedButton.icon(
                  onPressed: _showNewShipmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Envío'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredShipments.isEmpty
                    ? const Center(
                        child: Text('No se encontraron envíos'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredShipments.length,
                        itemBuilder: (context, index) {
                          final shipment = filteredShipments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              title: Text(
                                '${shipment['trackingNumber']} - ${shipment['customer']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'De: ${shipment['origin']} A: ${shipment['destination']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatusBadge(shipment['status']),
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined),
                                    onPressed: () {
                                      // Ver detalles del envío
                                    },
                                    tooltip: 'Ver detalles',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      // Editar envío
                                    },
                                    tooltip: 'Editar',
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Ver detalles del envío
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewShipmentDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Entregado':
        color = Colors.green;
        break;
      case 'En tránsito':
        color = AppTheme.primaryColor;
        break;
      case 'Procesando':
        color = Colors.orange;
        break;
      case 'Retrasado':
        color = Colors.red;
        break;
      default:
        color = AppTheme.mutedTextColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

